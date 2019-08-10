import UIKit
import CoreML

/**
  The app's main screen.
 */
class MenuViewController: UITableViewController {
  @IBOutlet var backgroundTrainingSwitch: UISwitch!

  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.backBarButtonItem = UIBarButtonItem(title: "Menu", style: .plain, target: nil, action: nil)
    backgroundTrainingSwitch.isOn = settings.isBackgroundTrainingEnabled

    Models.copyEmptyNearestNeighbors()
    Models.copyEmptyNeuralNetwork()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "TrainingData" {
      let viewController = segue.destination as! DataViewController
      viewController.imagesByLabel = ImagesByLabel(dataset: trainingDataset)
      viewController.title = "Training Data"
    }
    else if segue.identifier == "TestingData" {
      let viewController = segue.destination as! DataViewController
      viewController.imagesByLabel = ImagesByLabel(dataset: testingDataset)
      viewController.title = "Testing Data"
    }
    else if segue.identifier == "TrainNearestNeighbors" {
      let viewController = segue.destination as! TrainNearestNeighborsViewController
      viewController.model = Models.loadTrainedNearestNeighbors()
      viewController.imagesByLabel = ImagesByLabel(dataset: trainingDataset)
    }
    else if segue.identifier == "EvaluateNearestNeighbors" {
      let viewController = segue.destination as! EvaluateViewController
      viewController.model = Models.loadTrainedNearestNeighbors()
      viewController.dataset = testingDataset
      viewController.title = "k-Nearest Neighbors"
    }
    else if segue.identifier == "CameraNearestNeighbors" {
      let viewController = segue.destination as! CameraViewController
      viewController.model = Models.loadTrainedNearestNeighbors()
      viewController.title = "k-Nearest Neighbors"
    }
    else if segue.identifier == "TrainNeuralNetwork" {
      let viewController = segue.destination as! TrainNeuralNetworkViewController
      viewController.model = Models.loadTrainedNeuralNetwork()
      viewController.trainingDataset = trainingDataset
      viewController.validationDataset = testingDataset
    }
    else if segue.identifier == "EvaluateNeuralNetwork" {
      let viewController = segue.destination as! EvaluateViewController
      viewController.model = Models.loadTrainedNeuralNetwork()
      viewController.dataset = testingDataset
      viewController.title = "Neural Network"
    }
    else if segue.identifier == "CameraNeuralNetwork" {
      let viewController = segue.destination as! CameraViewController
      viewController.model = Models.loadTrainedNeuralNetwork()
      viewController.title = "Neural Network"
    }
  }

  @IBAction func loadBuiltInDataSet() {
    trainingDataset.copyBuiltInImages()
    testingDataset.copyBuiltInImages()
  }

  @IBAction func resetToEmptyNearestNeighbors() {
    Models.deleteTrainedNearestNeighbors()
    Models.copyEmptyNearestNeighbors()
  }

  @IBAction func resetToEmptyNeuralNetwork() {
    Models.deleteTrainedNeuralNetwork()
    Models.copyEmptyNeuralNetwork()
  }

  @IBAction func resetToTuriNeuralNetwork() {
    Models.deleteTrainedNeuralNetwork()
    Models.copyTuriNeuralNetwork()
  }

  @IBAction func backgroundTrainingSwitchTapped(_ sender: UISwitch) {
    settings.isBackgroundTrainingEnabled = backgroundTrainingSwitch.isOn
  }
}
