import UIKit
import CoreML

/**
  View controller for the "Training Neural Network" screen.
 */
class TrainNeuralNetworkViewController: UIViewController {
  @IBOutlet var oneEpochButton: UIButton!
  @IBOutlet var tenEpochsButton: UIButton!
  @IBOutlet var indefinitelyButton: UIButton!
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

    learningRateSlider.value = log10f(settings.learningRate)
    learningRateLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .regular)
    updateLearningRateLabel()

    headerLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
    headerLabel.sizeToFit()

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

  @IBAction func indefinitelyTapped(_ sender: Any) {
    startTraining(epochs: Int.max)
  }

  @IBAction func stopTapped(_ sender: Any) {
    stopTraining()
  }

  @IBAction func learningRateSliderMoved(_ sender: UISlider) {
    settings.learningRate = pow(10, sender.value)
    updateLearningRateLabel()
  }

  func updateLearningRateLabel() {
    learningRateLabel.text = String(String(format: "%2.4f", settings.learningRate).prefix(6))
  }

  @IBAction func augmentationSwitchTapped(_ sender: UISwitch) {
    settings.isAugmentationEnabled = sender.isOn
  }

  func startTraining(epochs: Int) {
  }

  func stopTraining() {
  }

  func trainingStopped() {
  }

  func updateButtons() {
  }
}

extension TrainNeuralNetworkViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    0
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    32
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
    cell.textLabel?.text = ""
    return cell
  }

  func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cell.textLabel?.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
  }
}
