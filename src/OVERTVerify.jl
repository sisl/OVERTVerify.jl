module OVERTVerify

include("dependencies.jl")

export OvertQuery,
    SinglePendulum,
    ACC,
    SimpleCar,
    Tora,
    Quad_6D,
    Quad_6D_world,
    symbolic_satisfiability,
    symbolic_reachability_with_concretization,
    clean_up_sets,
    clean_up_meas_sets,
    check_avoid_set_intersection,
    compare_to_dreal,
    Id,
    ReLU,
    Constraint
        # stuff
end