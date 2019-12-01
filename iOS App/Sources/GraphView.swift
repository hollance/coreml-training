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

  func update() {
    let trainLoss = history.events.map { $0.trainLoss }
    draw(data: trainLoss, in: shapeLayer)
  }

  private func draw(data: [Double], in layer: CAShapeLayer) {
    guard data.count > 1 else {
      shapeLayer.path = nil
      return
    }

    let maxY = data.max()!
    let offsetX = 10.0
    let offsetY = 10.0
    let width = Double(bounds.width)
    let height = Double(bounds.height)
    let scaleX = (width  - offsetX*2) / Double(data.count - 1)
    let scaleY = (height - offsetY*2) / (maxY + 1e-5)

    let path = UIBezierPath()
    let point = CGPoint(x: offsetX, y: height - (offsetY + data[0] * scaleY))
    path.move(to: point)

    for i in 1..<data.count {
      let point = CGPoint(x: offsetX + Double(i)*scaleX, y: height - (offsetY + data[i] * scaleY))
      path.addLine(to: point)
    }

    if layer.path == nil {
      layer.path = path.cgPath
    } else {
      let anim = CABasicAnimation(keyPath: "path")
      anim.toValue = path.cgPath
      anim.duration = 0.3
      anim.timingFunction = CAMediaTimingFunction(name: .default)
      anim.delegate = self
      anim.isRemovedOnCompletion = false
      anim.fillMode = .forwards
      layer.add(anim, forKey: "pathAnimation")
    }
  }

  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    shapeLayer.path = ((anim as? CABasicAnimation)?.toValue as! CGPath)
  }
}
