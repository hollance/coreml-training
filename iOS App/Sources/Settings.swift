import Foundation

class Settings {
  init() {
    UserDefaults.standard.register(defaults: [
      "learningRate": 0.001,
      "augmentation": false,
      "backgroundTraining": false
    ])
  }

  var learningRate: Double {
    get { UserDefaults.standard.double(forKey: "learningRate") }
    set { UserDefaults.standard.set(newValue, forKey: "learningRate") }
  }

  var isAugmentationEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: "augmentation") }
    set { UserDefaults.standard.set(newValue, forKey: "augmentation") }
  }

  var isBackgroundTrainingEnabled: Bool {
    get { UserDefaults.standard.bool(forKey: "backgroundTraining") }
    set { UserDefaults.standard.set(newValue, forKey: "backgroundTraining") }
  }
}
