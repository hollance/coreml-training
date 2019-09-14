# Makes a pipeline model of SqueezeNet v1.1 for feature extraction
# followed by k-Nearest Neighbors for classification.

import coremltools
import coremltools.proto.FeatureTypes_pb2 as ft
from coremltools.models.nearest_neighbors import KNearestNeighborsClassifierBuilder
import copy

# Take the SqueezeNet feature extractor from the Turi Create model.
base_model = coremltools.models.MLModel("../Models/TuriOriginal.mlmodel")
base_spec = base_model._spec

layers = copy.deepcopy(base_spec.neuralNetworkClassifier.layers)

# Delete the softmax and innerProduct layers. The new last layer is
# a "flatten" layer that outputs a 1000-element vector.
del layers[-1]
del layers[-1]

preprocessing = base_spec.neuralNetworkClassifier.preprocessing

# The Turi Create model is a classifier, which is treated as a special
# model type in Core ML. But we need a general-purpose neural network.
del base_spec.neuralNetworkClassifier.layers[:]
base_spec.neuralNetwork.layers.extend(layers)

# Also copy over the image preprocessing options.
base_spec.neuralNetwork.preprocessing.extend(preprocessing)

# Remove other classifier stuff.
base_spec.description.ClearField("metadata")
base_spec.description.ClearField("predictedFeatureName")
base_spec.description.ClearField("predictedProbabilitiesName")

# Remove the old classifier outputs.
del base_spec.description.output[:]

# Add a new output for the feature vector.
output = base_spec.description.output.add()
output.name = "features"
output.type.multiArrayType.shape.append(1000)
output.type.multiArrayType.dataType = ft.ArrayFeatureType.FLOAT32

# Connect the last layer to this new output.
base_spec.neuralNetwork.layers[-1].output[0] = "features"

# Create the k-NN model.
knn_builder = KNearestNeighborsClassifierBuilder(input_name="features",
                                                 output_name="label",
                                                 number_of_dimensions=1000,
                                                 default_class_label="???",
                                                 number_of_neighbors=3,
                                                 weighting_scheme="inverse_distance",
                                                 index_type="linear")

knn_spec = knn_builder.spec
knn_spec.description.input[0].shortDescription = "Input vector"
knn_spec.description.output[0].shortDescription = "Predicted label"
knn_spec.description.output[1].shortDescription = "Probabilities for each possible label"

knn_builder.set_number_of_neighbors_with_bounds(3, allowed_range=(1, 10))

# Use the same name as in the neural network models, so that we
# can use the same code for evaluating both types of model.
knn_spec.description.predictedProbabilitiesName = "labelProbability"
knn_spec.description.output[1].name = knn_spec.description.predictedProbabilitiesName

# Put it all together into a pipeline.
pipeline_spec = coremltools.proto.Model_pb2.Model()
pipeline_spec.specificationVersion = coremltools._MINIMUM_UPDATABLE_SPEC_VERSION
pipeline_spec.isUpdatable = True

pipeline_spec.description.input.extend(base_spec.description.input[:])
pipeline_spec.description.output.extend(knn_spec.description.output[:])
pipeline_spec.description.predictedFeatureName = knn_spec.description.predictedFeatureName
pipeline_spec.description.predictedProbabilitiesName = knn_spec.description.predictedProbabilitiesName

# Add inputs for training.
pipeline_spec.description.trainingInput.extend([base_spec.description.input[0]])
pipeline_spec.description.trainingInput[0].shortDescription = "Example image"
pipeline_spec.description.trainingInput.extend([knn_spec.description.trainingInput[1]])
pipeline_spec.description.trainingInput[1].shortDescription = "True label"

pipeline_spec.pipelineClassifier.pipeline.models.add().CopyFrom(base_spec)
pipeline_spec.pipelineClassifier.pipeline.models.add().CopyFrom(knn_spec)

pipeline_spec.pipelineClassifier.pipeline.names.extend(["FeatureExtractor", "kNNClassifier"])

coremltools.utils.save_spec(pipeline_spec, "../Models/HandskNN.mlmodel")
