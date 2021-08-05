# OVERTVerify

This repo integrates OVERT with reachability functionality for the purpose of verifying closed-loop systems with neural network control policies.
[OVERT](https://github.com/sisl/OVERT.jl) is a `julia` package that provides a relational piecewise-linear overapproximation of any multi-dimensional function. 
Such an overapproximation is used for converting smooth nonlinear functions that commonly appear in closed-loop dynamical systems into a set of relations with piecewise-linear functions such as `min` and `max`. 
The overapproximated dynamics, together with the neural network control policy (which is assumed to be ReLU-activated) is then represented as a mixed integer program using an encoding inspired by the [MIPVerify algorithm](https://arxiv.org/abs/1711.07356).
This system is unrolled in time and used to answer bounded-time reachability queries such as: can the closed loop system avoid an unsafe set? Or reach a goal set?

## Installation
```
] add https://github.com/sisl/OVERT.jl
] add https://github.com/sisl/OVERTVerify.jl
```

## Usage
See the accompanied documentation [here](docs/src/index.md)


## References

- [1] "*OVERT: An Algorithm for Safety Verification of Neural Network Control Policies for Nonlinear Systems*", Sidrane et al. (2020) [link](https://arxiv.org/abs/2108.01220)

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
