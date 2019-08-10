import UIKit

/**
  View controller for the "Training Data" and "Testing Data" screens.
*/
class DataViewController: UITableViewController {
  var imagesByLabel: ImagesByLabel!
  let headerNib = UINib(nibName: "SectionHeaderView", bundle: nil)

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.rightBarButtonItem = editButtonItem

    let cellNib = UINib(nibName: "ExampleCell", bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: "ExampleCell")
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print(#function)
  }

  // MARK: - Table view data source

  override func numberOfSections(in tableView: UITableView) -> Int {
    imagesByLabel.numberOfLabels
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    imagesByLabel.numberOfImages(for: imagesByLabel.labelName(of: section))
  }

  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    imagesByLabel.labelName(of: section)
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    88
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let view = headerNib.instantiate(withOwner: self, options: nil)[0] as! SectionHeaderView
    view.label.text = imagesByLabel.labelName(of: section)
    view.takePictureCallback = takePicture
    view.choosePhotoCallback = choosePhoto
    view.section = section
    view.cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
    return view
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    132
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ExampleCell", for: indexPath) as! ExampleCell
    let label = imagesByLabel.labelName(of: indexPath.section)
    if let image = imagesByLabel.image(for: label, at: indexPath.row) {
      cell.exampleImageView.image = image
      cell.notFoundLabel.isHidden = true
    } else {
      cell.exampleImageView.image = nil
      cell.notFoundLabel.isHidden = false
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    indexPath
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }

  override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    true
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      // Delete the image from the data source.
      let label = imagesByLabel.labelName(of: indexPath.section)
      imagesByLabel.removeImage(for: label, at: indexPath.row)

      // Refresh the table view.
      tableView.deleteRows(at: [indexPath], with: .automatic)
    }
  }

  // MARK: - Choosing photos

  var pickPhotoForSection = 0

  func takePicture(section: Int) {
    pickPhotoForSection = section
    presentPhotoPicker(sourceType: .camera)
  }

  func choosePhoto(section: Int) {
    pickPhotoForSection = section
    presentPhotoPicker(sourceType: .photoLibrary)
  }

  func presentPhotoPicker(sourceType: UIImagePickerController.SourceType) {
    let picker = UIImagePickerController()
    picker.delegate = self
    picker.sourceType = sourceType
    picker.allowsEditing = true
    present(picker, animated: true)
  }
}

extension DataViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    picker.dismiss(animated: true)

    // Grab the image.
    let image = info[UIImagePickerController.InfoKey.editedImage] as! UIImage

    // Add the image to the data model.
    let label = labels.labelNames[pickPhotoForSection]
    imagesByLabel.addImage(image, for: label)

    // Refresh the table view.
    let count = imagesByLabel.numberOfImages(for: label)
    let indexPath = IndexPath(row: count - 1, section: pickPhotoForSection)
    tableView.insertRows(at: [indexPath], with: .automatic)
  }
}
