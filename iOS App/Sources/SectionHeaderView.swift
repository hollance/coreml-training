import UIKit

class SectionHeaderView: UIView {
  @IBOutlet var cameraButton: UIButton!
  @IBOutlet var libraryButton: UIButton!
  @IBOutlet var label: UILabel!

  var takePictureCallback: ((Int) -> ())?
  var choosePhotoCallback: ((Int) -> ())?
  var section = 0

  override func awakeFromNib() {
    super.awakeFromNib()
    cameraButton.contentEdgeInsets = UIEdgeInsets(top: 30, left: 16, bottom: 30, right: 46)
    libraryButton.contentEdgeInsets = UIEdgeInsets(top: 30, left: 46, bottom: 30, right: 16)
  }

  @IBAction func takePicture(_ sender: Any) {
    takePictureCallback?(section)
  }

  @IBAction func choosePhoto(_ sender: Any) {
    choosePhotoCallback?(section)
  }
}
