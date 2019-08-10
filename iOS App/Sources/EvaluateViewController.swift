import UIKit
import CoreML

/**
  View controller for the "Evaluate" screen.

  This can evaluate both the neural network model and the k-NN model, because
  they use the same input and output names.
*/
class EvaluateViewController: UITableViewController {

  // To disable batch prediction, set this to 1.
  let batchSize = 4

  var model: MLModel!
  var dataset: ImageDataset!
  var imageLoader: ImageLoader!
  var predictor: Predictor!

  var headerView: SummaryHeaderView!
  var predictions: [Prediction?] = []

  let inferenceQueue = DispatchQueue(label: "net.machinethink.gestures.InferenceQueue")

  override func viewDidLoad() {
    super.viewDidLoad()

    let headerNib = UINib(nibName: "SummaryHeaderView", bundle: nil)
    headerView = headerNib.instantiate(withOwner: self, options: nil)[0] as? SummaryHeaderView
    headerView.label.text = ""

    let cellNib = UINib(nibName: "EvaluateCell", bundle: nil)
    tableView.register(cellNib, forCellReuseIdentifier: "EvaluateCell")

    // Since we're evaluating the model, don't shuffle or augment the images.
    imageLoader = ImageLoader(dataset: dataset, batchSize: batchSize,
                              shuffle: false, augment: false,
                              imageConstraint: imageConstraint(model: model))

    predictor = Predictor(model: model)
    predictions = .init(repeating: nil, count: dataset.count)
  }

  deinit {
    print(self, #function)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    print(self, #function)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if dataset.count == 0 {
      headerView.label.text = "No test images found"
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    if dataset.count > 0 && !predictor.shouldCancel {
      inferenceQueue.async {
        self.predictor.predict(loader: self.imageLoader, updateHandler: self.predictCallback)
      }
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)

    // We quit the prediction loop if the user taps the back button.
    predictor.shouldCancel = true
  }

  // MARK: - Table view data source

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    dataset.count
  }

  override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    88
  }

  override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    headerView
  }

  override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    132
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "EvaluateCell", for: indexPath) as! EvaluateCell
    if let image = dataset.image(at: indexPath.row) {
      cell.exampleImageView.image = image
      if let prediction = predictions[indexPath.row] {

        // Is this prediction correct or not?
        let trueLabel = dataset.label(at: indexPath.row)
        let isCorrect = (trueLabel == prediction.label)

        // If this is a gesture the user defined, then use their label instead
        // of the internal one from the mlmodel file.
        let predictedLabel = labels.userLabel(for: prediction.label)

        cell.setResults(trueLabel: trueLabel, predictedLabel: predictedLabel,
                        confidence: prediction.confidence, isCorrect: isCorrect)
      } else {
        cell.setInProgress()
      }
    } else {
      cell.exampleImageView.image = nil
      cell.setImageNotFound()
    }
    return cell
  }

  override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    indexPath
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }

  // MARK: - Inference

  private func predictCallback(callback: Predictor.Callback) {
    DispatchQueue.main.async {
      switch callback {
      case .batchBegin(let batchIndex, let batchCount):
        if self.imageLoader.batchSize == 1 {
          self.headerView.label.text = "Evaluating image \(batchIndex + 1) of \(batchCount)"
        } else {
          self.headerView.label.text = "Evaluating batch \(batchIndex + 1) of \(batchCount)"
        }

      case .batchEnd(let imageIndices, let batchPredictions):
        // Note: because the main thread reads from the predictions array,
        // we should also modify it on the main thread only.
        for i in 0..<batchPredictions.count {
          self.predictions[imageIndices[i]] = batchPredictions[i]
        }

        // Update all the table view cells for this batch at once.
        let indexPaths = imageIndices.map { IndexPath(row: $0, section: 0) }
        self.tableView.reloadRows(at: indexPaths, with: .automatic)

      case .completed:
        self.showSummary()

      case .cancelled:
        self.headerView.label.text = "Cancelled"
      }
    }
  }

  private func showSummary() {
    let correctCount = countCorrectPredictions()
    let accuracy = Double(correctCount) / Double(dataset.count)
    let summary = String(format: "%.1f%% correct (%d of %d)", accuracy * 100, correctCount, dataset.count)
    headerView.label.text = summary
  }

  private func countCorrectPredictions() -> Int {
    var correctCount = 0
    for i in 0..<dataset.count {
      let trueLabel = dataset.label(at: i)
      if let prediction = predictions[i], prediction.label == trueLabel {
        correctCount += 1
      }
    }
    return correctCount
  }
}
