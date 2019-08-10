import UIKit

/**
  A simple animated line graph. Shows the training loss.
 */
class GraphView: UIView, CAAnimationDelegate {
  let shapeLayer = CAShapeLayer()

  override func awakeFromNib() {
    super.awakeFromNib()

    clipsToBounds = true

    shapeLayer.fillColor = nil
    shapeLayer.strokeColor = UIColor.cyan.cgColor
    shapeLayer.lineWidth = 2
    shapeLayer.lineCap = .round
    shapeLayer.lineJoin = .round
    layer.addSublayer(shapeLayer)
  }
}
