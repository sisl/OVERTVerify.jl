## Reachable Set Computation Problem Specification
One way to prove the safety of a dynamical system is to compute its reachable set.
The reachable set at a given timestep `t` is comprised of all the possible states that the system may visit at time `t`.
Reachable set computation can be solved in two different ways.
One approach is to obtain a concrete reachable set at every timestep. Here, we define the concrete reachable set as an explicit representation of reachable set.
This approach is computational cheap, but yield conservative results. The second approach is to maintain an implicit symbolic representation of the reachable set at the intermediate timesteps, and only concretize at the final timestep. In order to keep the problem computationally tractable, and yet obtain a reasonably accurate reachable set, we use a hybrid approach, where concretization is performed only when necessary.

An example of a reachable set computation problem is provided in `src/examples/acc_reachability.jl`. After importing the files containing the description of the closed loop system, as explained above, an `OvertQuery` object is defined:
```julia
query = OvertQuery(
    SinglePendulum,    # problem
    controller,        # network file
    Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
    "MIP",             # query solver, "MIP" or "ReluPlex"
    40,                # ntime
    0.1,               # dt
    -1,                # N_overt
    )
```
The inputs of the object are problem instance (of type `OvertProblem`), controller file, last layer activation layer,
problem input set is specified by a hyperrectangle, horizon of verification (number of timesteps), time discretization constant `dt` and finally number of linear segments `N_overt`.
```julia
input_set = Hyperrectangle(low=[1., 0.], high=[1.2, 0.2])
```
Finally, reachability sets can be computed with the function:
`symbolic_reachability_with_concretization`. This function computes the reachable set by computing symbolic queries at a given set of timesteps and 1-step concrete sets at all other timesteps.


 For example,
 `symbolic_reachability_with_concretization(query, input_set, [10, 10, 10, 10])` computes reachable sets of the `query` problem over `input_set` initial set by concretizing at timesteps 10, 20, 30 and 40.
