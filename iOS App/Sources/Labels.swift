import Foundation

/**
  Manages the class labels used by the k-NN and neural network models.
 */
class Labels {
  let maxLabels = 10

  // The dataset always has these three labels but the user can add their own.
  let builtinLabelNames = [ "✊", "✋", "✌️" ]

  // The names of the labels as chosen by the user (plus the built-in ones).
  var labelNames: [String] = []

  // Which output neuron corresponds to which user-chosen label name.
  var labelIndices: [String: Int] {
    Dictionary(uniqueKeysWithValues: zip(labelNames, labelNames.indices))
  }

  // The names of the labels for the neural network in the mlmodel file: user0,
  // user1, user2, and so on. Core ML's predictions will use these labels, but
  // we don't want to show these to the user.
  //
  // Note: It would be best if we grabbed these class names from the mlmodel,
  // but there is no API that lets us do this right now (apart from making an
  // actual prediction). Although it is possible to add the class names as
  // metadata in the mlmodel and then we can read them from modelDescription.
  //
  // Note: These internal label names are only needed for the neural network.
  // The app lets users add new gestures, but a neural net always has a fixed
  // number of outputs. That's why we've added 7 placeholder labels in addition
  // to the 3 built-in ones.
  //
  // k-NN does not have this restriction, and the label names inside the k-NN's
  // mlmodel are always the ones chosen by the user.
  lazy var internalLabelNames: [String] = {
    builtinLabelNames + (0..<7).map { "user\($0)" }
  }()

  // Which output neuron corresponds to which label name in the mlmodel file.
  lazy var internalLabelIndices: [String: Int] = {
    Dictionary(uniqueKeysWithValues: zip(internalLabelNames, internalLabelNames.indices))
  }()

  init() {
    readLabelNames()
  }

  private var labelNamesURL: URL {
    applicationDocumentsDirectory.appendingPathComponent("labels.json")
  }

  /**
    The first three labels are always the same (✊, ✋, ✌️) but we also allow
    users to add their own. The new labels are written to labels.json because it
    is important that we read them in the same order every time.
   */
  private func readLabelNames() {
    do {
      let data = try Data(contentsOf: labelNamesURL)
      labelNames = try JSONDecoder().decode(Array<String>.self, from: data)
    } catch {
      labelNames = builtinLabelNames
    }
  }

  private func saveLabelNames() {
    do {
      let data = try JSONEncoder().encode(labelNames)
      try data.write(to: labelNamesURL)
    } catch {
      print("Error: \(error)")
    }
  }

  /**
    Adds a new label that is chosen by the user.

    We always add the new label name to the end of the list, because the neural
    network may already have been trained on the other labels. If we change the
    order, the predictions will no longer make sense!
   */
  func addLabel(_ label: String) {
    if !labelNames.contains(label) {
      labelNames.append(label)
      saveLabelNames()
    }
  }

  /**
    Converts an internal label, such as "user0", into a user-chosen label.
    This is useful for converting predictions, which use the internal name,
    into text for display. (Used only for the neural network; for k-NN there
    is no difference between internal labels and user-chosen labels.)
   */
  func userLabel(for internalLabel: String) -> String {
    if let idx = internalLabelIndices[internalLabel], idx < labelNames.count {
      return labelNames[idx]
    } else {
      return internalLabel
    }
  }

  /**
    Looks up the internal label, such as "user0", that corresponds to a given
    user-chosen label. This is needed to match a prediction, which always uses
    the internal label, to the label used by the ImageDataset. (Used only for
    the neural network; for k-NN there is no difference between internal labels
    and user-chosen labels.)
   */
  func internalLabel(for userLabel: String) -> String {
    internalLabelNames[labels.labelIndices[userLabel]!]
  }
}
