## Define controller
The next step is to define the neural network control policy. 
Currently, OVERTVerify supports
fully connected neural networks with ReLU activation functions. 
The last layer may have a linear activation function. 
The control policy should be prescribed as an `nnet` file. 
To see the details of this representation, check out [this repository](https://github.com/sisl/NNet).

