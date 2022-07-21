# Internal file dependencies

# include stuff
include("models/problems.jl")
include("overt_to_mip.jl")

## The following code in the nv folder forked from https://github.com/sisl/NeuralVerification.jl
include("nv/utils/activation.jl")
include("nv/utils/network.jl")
include("nv/utils/problem.jl")
include("nv/utils/util.jl")
include("nv/utils/flux.jl")
include("nv/optimization/utils/constraints.jl")
include("nv/optimization/utils/objectives.jl")
include("nv/optimization/utils/variables.jl")
include("nv/reachability/maxSens.jl")
## 

include("logic.jl")
include("reachability_functions.jl")
include("models/single_pendulum/single_pend.jl")
include("models/tora/tora.jl")
include("models/car/simple_car.jl")
include("models/acc/acc.jl")
include("models/quad/sixD_quad.jl")
include("overt_parser_minimal.jl")
include("dreal_wrapper/smt2_interface.jl")
include("dreal_wrapper/proof_functions.jl")
include("dreal_wrapper/dreal_utils.jl")
include("dreal_wrapper/compare_to_dreal.jl")
include("utilities.jl")