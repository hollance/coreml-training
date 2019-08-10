import UIKit

extension UIImage {
  func resized(smallestSide: Int) -> UIImage? {
    let smallestSide = CGFloat(smallestSide)
    let newSize: CGSize
    if size.width > size.height {
      newSize = CGSize(width: size.width / size.height * smallestSide, height: smallestSide)
    } else {
      newSize = CGSize(width: smallestSide, height: size.height / size.width * smallestSide)
    }

    UIGraphicsBeginImageContextWithOptions(newSize, true, 1)
    draw(in: CGRect(origin: CGPoint.zero, size: newSize))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return newImage
  }
}
