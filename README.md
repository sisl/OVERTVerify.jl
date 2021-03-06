# OVERTVerify

[![Build Status](https://github.com/sisl/OVERTVerify.jl/workflows/CI/badge.svg)](https://github.com/sisl/OVERTVerify.jl/actions)
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
@misc{sidrane2021overt,
      title={OVERT: An Algorithm for Safety Verification of Neural Network Control Policies for Nonlinear Systems}, 
      author={Chelsea Sidrane and Amir Maleki and Ahmed Irfan and Mykel J. Kochenderfer},
      year={2021},
      eprint={2108.01220},
      archivePrefix={arXiv},
      primaryClass={cs.LG}
}
```
