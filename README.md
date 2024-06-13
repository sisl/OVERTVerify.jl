# OVERTVerify

[![CI](https://github.com/sisl/OVERTVerify.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/sisl/OVERTVerify.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/sisl/OVERTVerify.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/sisl/OVERTVerify.jl)

This repo integrates OVERT with reachability functionality for the purpose of verifying closed-loop systems with neural network control policies.
[OVERT](https://github.com/sisl/OVERT.jl) is a `julia` package that provides a relational piecewise-linear overapproximation of any multi-dimensional function. 
Such an overapproximation is used for converting smooth nonlinear functions that commonly appear in closed-loop dynamical systems into a set of relations with piecewise-linear functions such as `min` and `max`. 
The overapproximated dynamics, together with the neural network control policy (which is assumed to be ReLU-activated) is then represented as a mixed integer program using an encoding inspired by the [MIPVerify algorithm](https://arxiv.org/abs/1711.07356).
This system is unrolled in time and used to answer bounded-time reachability queries such as: can the closed loop system avoid an unsafe set? Or reach a goal set?

## Dependencies
By default, this package will use GLPK as it is open-source. However, Gurobi tends to perform better and was used for the experiments in the paper. If you have or can obtain a Gurobi license, it is recommended to use Gurobi. An academic Gurobi license can be acquired for free here: 
https://www.gurobi.com/academia/academic-program-and-licenses/

The Julia dependencies are listed in the Project.toml file and will be automatically installed when you add the package (see Installation below).

## Installation
```
] add https://github.com/sisl/OVERTVerify.jl
```

## Usage
See the documentation [here](docs/src/index.md)

### Citation
```
@article{sidrane2022overt,
  title={OVERT: An algorithm for safety verification of neural network control policies for nonlinear systems},
  author={Sidrane, Chelsea and Maleki, Amir and Irfan, Ahmed and Kochenderfer, Mykel J},
  journal={Journal of Machine Learning Research},
  volume={23},
  number={117},
  pages={1--45},
  year={2022}
}

```
