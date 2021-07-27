## Feasibility problem specification
The second type of problems that `OVERTVerify` supports are feasibility problems.
Feasibility problems directly encode the unsafe set (complement of the safe set) or not-goal set (complement of the goal set) and return Sat/Unsat which indicates whether the unsafe set is reachable or not, without explicitly computing the reachable set.

Example of a feasibility problem is provided in `src/examples/acc_feasibility.jl`. The setup is similar to reachable set computation problems, except a target set (unsafe set) must be specified. The target set can be of type `Hyperrectangle`, `HalfSpace`, `HPolyhedron` or `Constraint`:
For example,
```julia
target_set = HalfSpace([1., 0.], 5.0)
```
indicates `x[1]<=5` as an unsafe set for a problem with two state variables. 

To solve the feasibility problem, use
```julia
SATus, vals, ce = symbolic_feasibility(query, input_set, target_set)
```
Note that the output constraint can also be applied to the measurement model, which is a linear model that multiplies the state variables.
If you would like to use a measurement model, use:

```julia
SATus, vals, ce = symbolic_feasibility(query, input_set, target_set, apply_meas=true)
```

If problem returns `SAT`, meaning that the target set is reachable, a counter example is return in `ce`.
