import UIKit

/**
  View controller for the "Add Gesture" screen.
*/
class AddGestureViewController: UIViewController, UITextFieldDelegate {
  @IBOutlet var textField: UITextField!
  @IBOutlet var saveButton: UIBarButtonItem!

  override func viewDidLoad() {
    super.viewDidLoad()
    textField.text = ""
    saveButton.isEnabled = false

    if labels.labelNames.count >= labels.maxLabels {
      textField.text = "Cannot add more than \(labels.maxLabels) gestures."
      textField.isEnabled = false
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    textField.becomeFirstResponder()
  }

  @IBAction func save() {
    let newLabel = textField.text!
    if !newLabel.isEmpty {
      labels.addLabel(newLabel)
      trainingDataset.createFolder(for: newLabel)
      testingDataset.createFolder(for: newLabel)
    }
    navigationController?.popViewController(animated: true)
  }

  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    let newText = NSString(string: textField.text!).replacingCharacters(in: range, with: string)

    // Don't accept characters that can cause problems in the file system.
    let sanitized = newText.components(separatedBy: .init(charactersIn: #"./\?%*|"<>"#)).joined()
    let isValid = (newText.count > 0) && (newText == sanitized)

    saveButton.isEnabled = isValid
    return true
  }

  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    save()
    return true
  }
}
