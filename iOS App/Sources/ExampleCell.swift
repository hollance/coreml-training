import UIKit

class ExampleCell: UITableViewCell {
  @IBOutlet var exampleImageView: UIImageView!
  @IBOutlet var notFoundLabel: UILabel!
  @IBOutlet var selectedLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()
    notFoundLabel.isHidden = true
    selectedLabel.isHidden = true
  }
}
