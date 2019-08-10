import UIKit

class EvaluateCell: UITableViewCell {
  @IBOutlet var exampleImageView: UIImageView!
  @IBOutlet var labelsView: UIView!
  @IBOutlet var trueLabel: UILabel!
  @IBOutlet var predictedLabel: UILabel!
  @IBOutlet var confidenceLabel: UILabel!
  @IBOutlet var correctLabel: UILabel!
  @IBOutlet var busySpinner: UIActivityIndicatorView!

  func setImageNotFound() {
    labelsView.isHidden = true
    correctLabel.isHidden = false
    busySpinner.isHidden = true
    correctLabel.text = "?"
  }

  func setInProgress() {
    labelsView.isHidden = true
    correctLabel.isHidden = true
    busySpinner.isHidden = false
    busySpinner.startAnimating()
  }

  func setResults(trueLabel: String, predictedLabel: String, confidence: Double, isCorrect: Bool) {
    labelsView.isHidden = false
    correctLabel.isHidden = false
    busySpinner.isHidden = true
    busySpinner.stopAnimating()

    self.trueLabel.text = trueLabel
    self.trueLabel.sizeToFit()
    self.predictedLabel.text = predictedLabel
    self.predictedLabel.sizeToFit()

    confidenceLabel.text = String(format: "%.1f%%", confidence * 100)
    confidenceLabel.sizeToFit()

    correctLabel.text = isCorrect ? "✅" : "❌"
  }
}
