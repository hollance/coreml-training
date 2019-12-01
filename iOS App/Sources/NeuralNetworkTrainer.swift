import QuartzCore
import CoreML

/**
 For training the neural network model.
*/
class NeuralNetworkTrainer {
  let modelURL: URL
  let trainingDataset: ImageDataset
  let trainingLoader: ImageLoader
  let validationDataset: ImageDataset
  let validationLoader: ImageLoader

  private var updateTask: MLUpdateTask?

  enum Callback {
    case epochEnd(trainLoss: Double, validationLoss: Double, validationAccuracy: Double)
    case completed(updatedModel: MLModel)
    case error
  }

  init(modelURL: URL, trainingDataset: ImageDataset, validationDataset: ImageDataset, imageConstraint: MLImageConstraint) {
    self.modelURL = modelURL
    self.trainingDataset = trainingDataset
    self.validationDataset = validationDataset

    // Normally, the data loader for training would shuffle the images, but
    // Core ML already does the shuffling for us. We also don't need to set a
    // batch size because Core ML also takes care of making the mini-batches.
    trainingLoader = ImageLoader(dataset: trainingDataset,
                                 augment: settings.isAugmentationEnabled,
                                 imageConstraint: imageConstraint)

    // After each epoch, we'll try the updated model on the validation set.
    // NOTE: To see how the accuracy of the training set is affected during
    // training, use trainingDataset below instead of validationDataset:

    validationLoader = ImageLoader(dataset: validationDataset,
                                   batchSize: 8,
                                   shuffle: false,
                                   augment: false,
                                   imageConstraint: imageConstraint)
  }

  func train(epochs: Int, learningRate: Double, callback: @escaping (Callback) -> Void) {
    do {
      var startTime = CACurrentMediaTime()

      trainingLoader.augment = settings.isAugmentationEnabled

      let trainingData = TrainingBatchProvider(imageLoader: trainingLoader)

      // This is how we can change the hyperparameters before training. If you
      // don't do this, the defaults as defined in the mlmodel file are used.
      // Note that the values you choose here must match what is allowed in the
      // mlmodel file, or else Core ML throws an exception.
      let parameters: [MLParameterKey: Any] = [
        .epochs: epochs,
        //.seed: 1234,
        .miniBatchSize: 8,
        .learningRate: learningRate,
        //.shuffle: false,
      ]

      let config = MLModelConfiguration()
      config.computeUnits = .all
      config.parameters = parameters

      let progressHandler = { (context: MLUpdateContext) in
        switch context.event {
        case .trainingBegin:
          // This is the first event you receive, just before training actually
          // starts. At this point, context.metrics is empty.
          print("Training begin")

        case .miniBatchEnd:
          // This event is triggered after each mini-batch. You can get the
          // index of this batch and the training loss from context.metrics.
          let batchIndex = context.metrics[.miniBatchIndex] as! Int
          let batchLoss = context.metrics[.lossValue] as! Double
          print("Mini batch \(batchIndex), loss: \(batchLoss)")

        case .epochEnd:
          let elapsed = CACurrentMediaTime() - startTime
          let epochIndex = context.metrics[.epochIndex] as! Int

          // The only metric Core ML gives us is the training loss.
          let trainLoss = context.metrics[.lossValue] as! Double

          // Compute the validation loss and accuracy. Note that we need to use
          // the MLModel object from the MLUpdateContext for this!
          let predictor = Predictor(model: context.model)
          let (valLoss, valAcc) = predictor.evaluate(loader: self.validationLoader)

          print("Epoch \(epochIndex), train loss: \(trainLoss), val loss: \(valLoss), val acc: \(valAcc), time: \(elapsed) sec.")

          callback(.epochEnd(trainLoss: trainLoss, validationLoss: valLoss, validationAccuracy: valAcc))
          startTime = CACurrentMediaTime()

        default:
            print("Unknown event")
        }

        // If you want to, you can look at the training hyperparameters as
        // defined in the mlmodel. For some strange reason, this only works
        // inside the MLUpdateTask handlers!
        /*
        print(context.model.modelDescription.parameterDescriptionsByKey)
        */

        /*
        // Do the following to look at the weights or biases from a layer:
        do {
          let multiArray = try context.model.parameterValue(for: MLParameterKey.weights.scoped(to: "fullyconnected0")) as! MLMultiArray
          print(multiArray.shape)
        } catch {
          print(error)
        }
        */

        // This is how you can change the hyperparameters during training,
        // for example to do learning rate annealing:
        /*
        var newParameters = context.parameters
        newParameters[.learningRate] = (newParameters[.learningRate] as! Double) * 0.99
        context.task.resume(withParameters: newParameters)
        */
      }

      let completionHandler = { (context: MLUpdateContext) in
        // The completion handler is called after the last epoch completes.
        // It is not called when you cancel the MLUpdateTask.

        defer { self.updateTask = nil }

        print("Training completed with state \(context.task.state.rawValue)")

        // This happens when there is some kind of error, for example if the
        // batch provider returns an invalid MLFeatureProvider object.
        if context.task.state == .failed {
          callback(.error)
          return
        }

        let trainLoss = context.metrics[.lossValue] as! Double
        print("Final loss: \(trainLoss)")

        // Overwrite the mlmodelc with the updated one.
        self.saveUpdatedModel(context.model, to: self.modelURL)

        // Tell the caller we're done; also pass the new MLModel instance.
        callback(.completed(updatedModel: context.model))
      }

      let handlers = MLUpdateProgressHandlers(
        forEvents: [.trainingBegin, .miniBatchEnd, .epochEnd],
        progressHandler: progressHandler,
        completionHandler: completionHandler)

      updateTask = try MLUpdateTask(forModelAt: self.modelURL,
                                    trainingData: trainingData,
                                    configuration: config,
                                    progressHandlers: handlers)
      updateTask?.resume()

    } catch {
      print("Error training neural network:", error)
      callback(.error)
    }
  }

  private func saveUpdatedModel(_ model: MLModel & MLWritable, to url: URL) {
    do {
      let tempURL = urlForModelInDocumentsDirectory("tempNeuralNetwork")
      try model.write(to: tempURL)
      _ = try FileManager.default.replaceItemAt(url, withItemAt: tempURL)
    } catch {
      print("Error saving neural network model to \(url):", error)
    }
  }

  func cancel() {
    updateTask?.cancel()
  }
}
