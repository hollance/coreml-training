import UIKit
import CoreML

/**
  View controller for the "Training Neural Network" screen.
 */
class TrainNeuralNetworkViewController: UIViewController {
  @IBOutlet var oneEpochButton: UIButton!
  @IBOutlet var tenEpochsButton: UIButton!
  @IBOutlet var fiftyEpochsButton: UIButton!
  @IBOutlet var stopButton: UIButton!
  @IBOutlet var learningRateLabel: UILabel!
  @IBOutlet var learningRateSlider: UISlider!
  @IBOutlet var augmentationSwitch: UISwitch!
  @IBOutlet var statusLabel: UILabel!
  @IBOutlet var tableView: UITableView!
  @IBOutlet var headerLabel: UILabel!
  @IBOutlet var graphView: GraphView!

  var model: MLModel!
  var trainingDataset: ImageDataset!
  var validationDataset: ImageDataset!
  var trainer: NeuralNetworkTrainer!
  var isTraining = false

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.dataSource = self
    tableView.delegate = self
    tableView.rowHeight = 32
    tableView.separatorInset = .zero
    tableView.contentInset = .zero

    stopButton.isEnabled = false
    statusLabel.text = "Paused"
    augmentationSwitch.isOn = settings.isAugmentationEnabled

    learningRateSlider.value = Float(log10(settings.learningRate))
    learningRateLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
    updateLearningRateLabel()

    headerLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    headerLabel.sizeToFit()

    trainer = NeuralNetworkTrainer(modelURL: Models.trainedNeuralNetworkURL,
                                   trainingDataset: trainingDataset,
                                   validationDataset: validationDataset,
                                   imageConstraint: imageConstraint(model: model))

    assert(model.modelDescription.isUpdatable)
    //print(model.modelDescription.trainingInputDescriptionsByName)

    NotificationCenter.default.addObserver(self, selector: #selector(appWillResignActive), name: UIApplication.willResignActiveNotification, object: nil)
  }

  deinit {
    print(self, #function)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print(self, #function)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // The user tapped the back button.
    stopTraining()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    graphView.update()
  }

  @objc func appWillResignActive() {
    stopTraining()
  }

  @IBAction func oneEpochTapped(_ sender: Any) {
    startTraining(epochs: 1)
  }

  @IBAction func tenEpochsTapped(_ sender: Any) {
    startTraining(epochs: 10)
  }

  @IBAction func fiftyEpochsTapped(_ sender: Any) {
    startTraining(epochs: 50)
  }

  @IBAction func stopTapped(_ sender: Any) {
    stopTraining()
  }

  @IBAction func learningRateSliderMoved(_ sender: UISlider) {
    settings.learningRate = pow(10, Double(sender.value))
    updateLearningRateLabel()
  }

  @IBAction func augmentationSwitchTapped(_ sender: UISwitch) {
    settings.isAugmentationEnabled = sender.isOn
  }

  func updateLearningRateLabel() {
    learningRateLabel.text = String(String(format: "%.6f", settings.learningRate).prefix(8))
  }

  func updateButtons() {
    oneEpochButton.isEnabled = !isTraining
    tenEpochsButton.isEnabled = !isTraining
    fiftyEpochsButton.isEnabled = !isTraining
    learningRateSlider.isEnabled = !isTraining
    augmentationSwitch.isEnabled = !isTraining
    stopButton.isEnabled = isTraining
  }
}

extension TrainNeuralNetworkViewController {
  func startTraining(epochs: Int) {
    guard trainingDataset.count > 0 else {
      statusLabel.text = "No training images"
      return
    }

    isTraining = true
    statusLabel.text = "Training..."
    updateButtons()

    trainer.train(epochs: epochs, learningRate: settings.learningRate, callback: trainingCallback)
  }

  func stopTraining() {
    trainer.cancel()
    trainingStopped()
  }

  func trainingStopped() {
    isTraining = false
    statusLabel.text = "Paused"
    updateButtons()
  }

  func trainingCallback(callback: NeuralNetworkTrainer.Callback) {
    DispatchQueue.main.async {
      switch callback {
      case let .epochEnd(trainLoss, valLoss, valAcc):
        history.addEvent(trainLoss: trainLoss, validationLoss: valLoss, validationAccuracy: valAcc)

        let indexPath = IndexPath(row: history.count - 1, section: 0)
        self.tableView.insertRows(at: [indexPath], with: .fade)
        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
        self.graphView.update()

      case .completed(let updatedModel):
        self.trainingStopped()

        // Replace our model with the newly trained one.
        self.model = updatedModel

      case .error:
        self.trainingStopped()
      }
    }
  }
}

extension TrainNeuralNetworkViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    history.count
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    32
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
    cell.textLabel?.text = history.events[indexPath.row].displayString
    return cell
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.textLabel?.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
  }
}

fileprivate extension History.Event {
  var displayString: String {
    var s = String(format: "%5d   ", epoch + 1)
    s += String(String(format: "%6.4f", trainLoss).prefix(6))
    s += "   "
    s += String(String(format: "%6.4f", validationLoss).prefix(6))
    s += "     "
    s += String(String(format: "%5.2f", validationAccuracy * 100).prefix(5))
    return s
  }
}
