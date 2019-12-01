import CoreML

/**
  Wraps ImageLoader into MLBatchProvider.

  When training the neural network, just as with k-NN, the training examples
  must be vended by an MLBatchProvider. For k-NN it's easiest to use the
  MLArrayBatchProvider class. But if you have a lot of data, or if you want to
  do on-the-fly data augmentation, it makes sense to implement MLBatchProvider
  yourself.

  Since we already have an ImageLoader class, our batch provider will use that
  to load the images. We also provide the true labels for each example.

  Rather than constructing the MLFeatureProvider objects from scratch, we simply
  use the Xcode-generated class HandsEmptyTrainingInput.
 */
class TrainingBatchProvider: MLBatchProvider {
  let imageLoader: ImageLoader

  init(imageLoader: ImageLoader) {
    self.imageLoader = imageLoader
  }

  var count: Int {
    imageLoader.dataset.count
  }

  func features(at index: Int) -> MLFeatureProvider {
    print("*** batch provider @", index)

    guard let featureValue = try? imageLoader.featureValue(at: index) else {
      print("Could not load image at index \(index)")
      return failure()
    }

    let trueLabel = imageLoader.dataset.label(at: index)

    guard let pixelBuffer = featureValue.imageBufferValue else {
      print("Could not get pixel buffer for image at \(index)")
      return failure()
    }

    return HandsEmptyTrainingInput(image: pixelBuffer, label: trueLabel)
  }

  private func failure() -> MLFeatureProvider {
    return try! MLDictionaryFeatureProvider(dictionary: [:])
  }
}
