import UIKit
import CoreML

let applicationDocumentsDirectory: URL = {
  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}()

@discardableResult func copyIfNotExists(from: URL, to: URL) -> Bool {
  if !FileManager.default.fileExists(atPath: to.path) {
    do {
      try FileManager.default.copyItem(at: from, to: to)
      return true
    } catch {
      print("Error: \(error)")
    }
  }
  return false
}

func removeIfExists(at url: URL) {
  try? FileManager.default.removeItem(at: url)
}

func createDirectory(at url: URL) {
  try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
}

func contentsOfDirectory(at url: URL) -> [URL]? {
  try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
}

func contentsOfDirectory(at url: URL, matching predicate: (URL) -> Bool) -> [URL] {
  contentsOfDirectory(at: url)?.filter(predicate) ?? []
}

extension UIViewController {
  func showDialog(message: String) {
    let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
    let action = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(action)
    present(alert, animated: true, completion: nil)
  }
}
