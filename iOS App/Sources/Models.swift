import CoreML

/**
  Names of the models inside the app bundle or the app's Documents folder.
 */
enum Models: String {
  case emptyNearestNeighbors = "HandskNN"
  case trainedNearestNeighbors = "NearestNeighbors"

  case emptyNeuralNetwork = "HandsEmpty"
  case turiNeuralNetwork = "HandsTuri"
  case trainedNeuralNetwork = "NeuralNetwork"
}

/**
  Convenience functions for loading models.
 */
extension Models {
  static var trainedNearestNeighborsURL: URL {
    urlForModelInDocumentsDirectory(.trainedNearestNeighbors)
  }

  static var trainedNeuralNetworkURL: URL {
    urlForModelInDocumentsDirectory(.trainedNeuralNetwork)
  }

  private static func urlForModelInBundle(_ model: Models) -> URL {
    Bundle.main.url(forResource: model.rawValue, withExtension: "mlmodelc")!
  }

  private static func urlForModelInDocumentsDirectory(_ model: Models) -> URL {
    Gestures.urlForModelInDocumentsDirectory(model.rawValue)
  }

  private static func loadModel(url: URL) -> MLModel? {
    do {
      let config = MLModelConfiguration()
      config.computeUnits = .all

      // You can override the model's hyperparameters like this:
      //config.parameters = [MLParameterKey.numberOfNeighbors: 10]

      return try MLModel(contentsOf: url, configuration: config)
    } catch {
      print("Error loading model: \(error)")
      return nil
    }
  }

  static func loadTrainedNearestNeighbors() -> MLModel? {
    loadModel(url: trainedNearestNeighborsURL)
  }

  static func loadTrainedNeuralNetwork() -> MLModel? {
    loadModel(url: trainedNeuralNetworkURL)
  }
}

/**
  Model file management.
 */
extension Models {
  static func copyEmptyNearestNeighbors() {
    copyModelToDocumentsDirectory(from: .emptyNearestNeighbors, to: .trainedNearestNeighbors)
  }

  static func copyEmptyNeuralNetwork() {
    copyModelToDocumentsDirectory(from: .emptyNeuralNetwork, to: .trainedNeuralNetwork)
  }

  static func copyTuriNeuralNetwork() {
    copyModelToDocumentsDirectory(from: .turiNeuralNetwork, to: .trainedNeuralNetwork)
  }

  private static func copyModelToDocumentsDirectory(from: Models, to: Models) {
    let fromURL = urlForModelInBundle(from)
    let toURL = urlForModelInDocumentsDirectory(to)
    copyIfNotExists(from: fromURL, to: toURL)
  }

  static func deleteTrainedNearestNeighbors() {
    deleteModelFromDocumentsDirectory(.trainedNearestNeighbors)
  }

  static func deleteTrainedNeuralNetwork() {
    deleteModelFromDocumentsDirectory(.trainedNeuralNetwork)
  }

  private static func deleteModelFromDocumentsDirectory(_ model: Models) {
    removeIfExists(at: urlForModelInDocumentsDirectory(model))
  }
}

func urlForModelInDocumentsDirectory(_ model: String) -> URL {
  applicationDocumentsDirectory.appendingPathComponent(model)
                               .appendingPathExtension("mlmodelc")
}

/**
  Because the images may not be exactly 227x227 pixels, we use the new
  MLFeatureValue(imageAt:) API to crop / scale the image.

  We need to tell the MLFeatureValue how large the image should be and
  what pixel format the model expects. You can hardcode these numbers,
  but it's easiest to grab the MLImageConstraint from the model input.

  We need to do this in several different places, which is why we'll use
  this helper function.
 */
func imageConstraint(model: MLModel) -> MLImageConstraint {
  return model.modelDescription.inputDescriptionsByName["image"]!.imageConstraint!
}
