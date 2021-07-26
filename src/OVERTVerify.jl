module OVERTVerify

# include stuff
include("models/problems.jl")
include("overt_to_mip.jl")
include("nv/utils/activation.jl")
include("nv/utils/network.jl")
include("nv/utils/problem.jl")
include("nv/utils/util.jl")
include("nv/optimization/utils/constraints.jl")
include("nv/optimization/utils/objectives.jl")
include("nv/optimization/utils/variables.jl")
include("nv/reachability/maxSens.jl")
include("logic.jl")
include("reachability_functions.jl")
include("models/single_pendulum/single_pend.jl")
include("models/tora/tora.jl")
include("models/car/simple_car.jl")
include("models/acc/acc.jl")
include("overt_parser_minimal.jl")
include("dreal_wrapper/smt2_interface.jl")
include("dreal_wrapper/proof_functions.jl")
include("dreal_wrapper/dreal_utils.jl")
include("dreal_wrapper/compare_to_dreal.jl")

export OvertQuery,
    SinglePendulum,
    symbolic_satisfiability,
    symbolic_reachability_with_concretization,
    clean_up_sets,
    check_avoid_set_intersection,
    compare_to_dreal,
    Id,
    ReLU
        # stuff
end