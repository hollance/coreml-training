import UIKit
import CoreML
import Vision

/**
  View controller for the "Camera" screen.

  This can evaluate both the neural network model and the k-NN model, because
  they use the same input and output names.

  On the Simulator this uses the photo library instead of the camera.
 */
class CameraViewController: UIViewController {
  @IBOutlet var cameraButton: UIBarButtonItem!
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var textView: UITextView!

  var model: MLModel!
  var predictor: Predictor!

  override func viewDidLoad() {
    super.viewDidLoad()
    textView.text = "Use the camera to take a photo."
    predictor = Predictor(model: model)
  }

  @IBAction func takePicture() {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
    picker.allowsEditing = true
    present(picker, animated: true)
  }

  func predict(image: UIImage) {
    let constraint = imageConstraint(model: model)

    let imageOptions: [MLFeatureValue.ImageOption: Any] = [
      .cropAndScale: VNImageCropAndScaleOption.scaleFill.rawValue
    ]

    // In the "Evaluate" screen we load the image from the dataset but here
    // we use a UIImage / CGImage object.
    if let cgImage = image.cgImage,
       let featureValue = try? MLFeatureValue(cgImage: cgImage,
                                              orientation: .up,
                                              constraint: constraint,
                                              options: imageOptions),
       let prediction = predictor.predict(image: featureValue) {
      textView.text = makeDisplayString(prediction)
    }
  }

  private func makeDisplayString(_ prediction: Prediction) -> String {
    var s = "Prediction: \(prediction.label)\n"
    s += String(format: "Probability: %.2f%%\n\n", prediction.confidence * 100)
    s += "Results for all classes:\n"
    s += prediction.sortedProbabilities
                   .map { String(format: "%@ %f", labels.userLabel(for: $0.0), $0.1) }
                   .joined(separator: "\n")
    return s
  }
}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)

    let image = info[UIImagePickerController.InfoKey.editedImage] as! UIImage
    imageView.image = image

    predict(image: image)
  }
}
