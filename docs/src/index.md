# OvertVerify

## Introduction
This repo integrates OVERT with reachability functionality for the purpose of verifying closed-loop systems with neural network control policies.
[OVERT](https://sisl.github.io/OVERT.jl) is a `julia` package that provides a relational piecewise-linear overapproximation of any multi-dimensional function. 
Such an overapproximation is used for converting smooth nonlinear functions that commonly appear in closed-loop dynamical systems into a set of relations with piecewise-linear functions such as `min` and `max`. 
The overapproximated dynamics, together with the neural network control policy (which is assumed to be ReLU-activated) is then represented as a mixed integer program using an encoding inspired by the [MIPVerify algorithm](https://arxiv.org/abs/1711.07356).
This system is unrolled in time and used to answer bounded-time reachability queries such as: can the closed loop system avoid an unsafe set? Or reach a goal set?
Reachability queries can be solved either using a feasibility approach or by explicitly calculating the reachable set and then intersecting the reachable set with the unsafe set or goal set.

Examples of reachable set computation and feasibility problems are setup in the `src/examples` folder. Below you can find instructions for
 - [setting up a new model](setup_model.md)
 - [define a new control policy](define_control_policy.md)
 - [reachable set computation problem specification](reachability.md)
 - [feasibility problem specification](feasibility.md)


Usage Notes:
If you would like to use the Gurobi solver (faster than GLPK), do `using Gurobi` before `using OVERTVerify`. OR you can use `set_default_model("gurobi")`. You can check the default model by printing `OVERTVerify.DEFAULT_MODEL`.