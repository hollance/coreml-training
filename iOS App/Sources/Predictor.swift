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
