import UIKit

/**
  Organizes the images from an ImageDataset grouped by their labels.

  This is used by the "Training Data" and "Test Data" screens, as well as the
  "Train k-Nearest Neighbors" screen.
 */
class ImagesByLabel {
  let dataset: ImageDataset
  private var groups: [String: [Int]] = [:]

  init(dataset: ImageDataset) {
    self.dataset = dataset
    updateGroups()
  }

  private func updateGroups() {
    groups = [:]
    for label in labels.labelNames {
      groups[label] = dataset.images(withLabel: label)
    }
  }

  var numberOfLabels: Int { labels.labelNames.count }

  func labelName(of group: Int) -> String { labels.labelNames[group] }

  func numberOfImages(for label: String) -> Int {
    groups[label]!.count
  }

  func image(for label: String, at index: Int) -> UIImage? {
    dataset.image(at: flatIndex(for: label, at: index))
  }

  func addImage(_ image: UIImage, for label: String) {
    dataset.addImage(image, for: label)

    // The new image is always added at the end, so we can simply append
    // the new index to the group for this label.
    groups[label]!.append(dataset.count - 1)
  }

  func removeImage(for label: String, at index: Int) {
    dataset.removeImage(at: flatIndex(for: label, at: index))

    // All the image indices following the deleted image are now off by one,
    // so recompute all the groups.
    updateGroups()
  }

  func flatIndex(for label: String, at index: Int) -> Int {
    groups[label]![index]
  }
}
