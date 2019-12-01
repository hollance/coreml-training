import CoreML
import Vision
import QuartzCore

/**
  Describes the result of running the model on a single example.
 */
struct Prediction {
  let label: String
  let confidence: Double
  let probabilities: [AnyHashable: NSNumber]

  var sortedProbabilities: [(String, Double)] {
    probabilities.sorted { $0.1.doubleValue > $1.1.doubleValue }
                 .map { ($0.key as! String, $0.value as! Double) }
  }

  init?(result: MLFeatureProvider) {
    guard let predictedLabel = result.featureValue(for: "label")?.stringValue,
          let probabilities = result.featureValue(for: "labelProbability")?.dictionaryValue,
          let predictedProbability = probabilities[predictedLabel]?.doubleValue
    else {
      print("Error: could not read from result feature provider")
      return nil
    }

    self.label = predictedLabel
    self.confidence = predictedProbability
    self.probabilities = probabilities
  }
}

/**
  Used to make predictions using a Core ML model.

  Note that we don't use the automatically generated class here but use
  the MLModel API. This is done because you can use the Evaluate screen
  with different mlmodel files (untrained, Turi, and on-device trained).
 */
class Predictor {
  let model: MLModel
  let predictionOptions = MLPredictionOptions()
  var shouldCancel = false

  init(model: MLModel) {
    self.model = model
    predictionOptions.usesCPUOnly = false
  }

  /**
    Classifies a single image.
   */
  func predict(image: MLFeatureValue) -> Prediction? {
    let inputs: [String: Any] = [ "image": image ]
    guard let provider = try? MLDictionaryFeatureProvider(dictionary: inputs),
          let result = try? model.prediction(from: provider, options: predictionOptions),
          let prediction = Prediction(result: result) else {
      print("Inference error")
      return nil
    }
    return prediction
  }

  /**
    Classifies a batch of images.
   */
  func predict(batch: ImageLoader.Batch) -> [Prediction]? {
    do {
      // To create a batch, you make a MLFeatureProvider for each example,
      // add it to an array, and give that array to MLArrayBatchProvider.
      var batchInputs: [MLFeatureProvider] = []
      for (_, featureValue) in batch {
        let inputs: [String: Any] = [ "image": featureValue ]
        let provider = try MLDictionaryFeatureProvider(dictionary: inputs)
        batchInputs.append(provider)
      }

      let batchProvider = MLArrayBatchProvider(array: batchInputs)
      let batchResult = try model.predictions(from: batchProvider, options: predictionOptions)

      // The output object is another MLArrayBatchProvider containing one
      // MLFeatureProvider for every example in the batch.
      var batchPredictions: [Prediction] = []
      for i in 0..<batchResult.count {
        let result = batchResult.features(at: i)
        guard let prediction = Prediction(result: result) else { return nil }
        batchPredictions.append(prediction)
      }
      return batchPredictions
    } catch {
      print("Inference error: \(error)")
      return nil
    }
  }

  enum Callback {
    case batchBegin(index: Int, count: Int)
    case batchEnd(indices: [Int], predictions: [Prediction])
    case completed
    case cancelled
  }

  /**
    Classifies the entire dataset.
   */
  func predict(loader: ImageLoader, updateHandler: @escaping (Callback) -> Void) {
    let startTime = CACurrentMediaTime()

    // Just for fun, this code shows how to do prediction on batches as
    // well as single images. Using batches is generally more efficient.

    if loader.batchSize > 1 {
      loader.reset()
      while let batch = try? loader.nextBatch(), !shouldCancel {
        updateHandler(.batchBegin(index: loader.index, count: loader.count))
        if let batchPredictions = predict(batch: batch) {
          updateHandler(.batchEnd(indices: batch.map { $0.0 }, predictions: batchPredictions))
        }
      }
    } else {
      for i in 0..<loader.dataset.count {
        updateHandler(.batchBegin(index: i, count: loader.dataset.count))
        if let featureValue = try? loader.featureValue(at: i),
           let prediction = predict(image: featureValue) {
          updateHandler(.batchEnd(indices: [i], predictions: [prediction]))
        }
        if shouldCancel { break }
      }
    }

    print("Prediction took: \(CACurrentMediaTime() - startTime) sec.")
    updateHandler(shouldCancel ? .cancelled : .completed)
  }
}

extension Predictor {
  /**
    Computes the loss and accuracy over the entire dataset. This is done after
    an epoch of training on the neural network.
   */
  func evaluate(loader: ImageLoader) -> (Double, Double) {
    let startTime = CACurrentMediaTime()

    var correctCount = 0
    var exampleCount = 0
    var runningLoss: Double = 0

    loader.reset()
    while let batch = try? loader.nextBatch(), !shouldCancel {
      if let batchPredictions = predict(batch: batch) {
        for (i, (j, _)) in batch.enumerated() {
          let predictedLabel = batchPredictions[i].label
          let trueLabel = loader.dataset.label(at: j)
          exampleCount += 1

          // Because the user can choose their own labels, but the mlmodel
          // contains hardcoded class names (user0, user1, etc), we need to
          // translate between them.
          // Core ML will put the hardcoded class names into the predicted
          // probabilities dictionary. But the true labels from ImageDataset
          // are the ones chosen by the user.
          let trueLabelInMLModel = labels.internalLabel(for: trueLabel)

          // Compute the accuracy.
          if predictedLabel == trueLabelInMLModel { correctCount += 1 }

          // Core ML doesn't tell us what the loss is for inference, only for
          // training. But we can always compute it ourselves, of course. :-)
          //
          // The cross-entropy loss for a single example is:
          //     CE = -sum t[i] * log(p[i])
          //
          // where t is the one-hot encoded true label and p[i] is the softmax
          // output for the i-th class. Since t[i] is 1 for the true class and
          // 0 for all other classes, we only need to look at the predicted
          // probability of the true class. If that probability is close to 1,
          // the logarithm is close to 0 and the error is small; but the lower
          // the predicted probability for the true class, the larger the error.
          //
          // We do add a small value to make sure we never take log(0), which
          // gives infinity and wreaks havoc.
          let probabilityForTrueClass = batchPredictions[i].probabilities[trueLabelInMLModel]!.doubleValue
          let crossEntropy = -log(probabilityForTrueClass + 1e-100)
          runningLoss += crossEntropy

          // Enable this to examine the individual predictions and how much
          // they contribute to the loss:
          //print(String(format: "\t%@ correct? %@, prob: %.5f, loss: %.5f", trueLabelInMLModel, (predictedLabel == trueLabelInMLModel) ? "√" : "×", probabilityForTrueClass, crossEntropy))
        }
      }
    }

    print("Evaluation took \(CACurrentMediaTime() - startTime) sec.")

    // No images in the dataset or they all gave errors.
    // If you cancel the training process during validation, the computed loss
    // and accuracy are only for a subset of the examples, which is misleading
    // so we simply report zero loss / accuracy here.
    if exampleCount == 0 || shouldCancel { return (0, 0) }

    // The loss is averaged over all the examples.
    let loss = runningLoss / Double(exampleCount)
    let accuracy = Double(correctCount) / Double(exampleCount)
    return (loss, accuracy)
  }
}
