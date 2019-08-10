# Training with Core ML 3

This is the sample code for my blog post series [On-device training with Core ML](https://machinethink.net/blog/coreml-training-part1/).

Included are:

- **Dataset**: a small dataset of 30 training images and 15 test images

- **iOS App**: the source code of the demo app described in the blog post

- **Models**: the empty and pre-trained models used by the app
    - **TuriOriginal.mlmodel**: the SqueezeNet classifier trained by Turi Create
    - **HandsTuri.mlmodel**: the TuriOriginal model but made updatable
    - **HandsEmpty.mlmodel**: like HandsTuri but with a classifier layer that has random weights
    - **HandskNN.mlmodel**: like TuriOriginal but with an untrained k-Nearest Neighbors classifier

- **Scripts**: 
    - **make_nn.py**: converts TuriOriginal.mlmodel to HandsTuri and HandsEmpty.mlmodel
    - **make_knn.py**: creates the k-Nearest Neighbor model, HandskNN.mlmodel
    - **TuriCreate.ipynb**: the notebook used to train TuriOriginal.mlmodel

Credits:

- Camera icon made by [Daniel Bruce](https://www.flaticon.com/authors/daniel-bruce) from [www.flaticon.com](https://www.flaticon.com/) and is licensed by [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/).
- Picture icon made by [Dave Gandy](https://www.flaticon.com/authors/dave-gandy) from [www.flaticon.com](https://www.flaticon.com/) and is licensed by [CC 3.0 BY](http://creativecommons.org/licenses/by/3.0/).

The source code is copyright 2019 M.I. Hollemans and licensed under the terms of the MIT license.
