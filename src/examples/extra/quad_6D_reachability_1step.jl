# these example scripts are not part of the Package, just examples of how to use it.
# using OVERTVerify
using Gurobi
include("../../dependencies.jl")
using LazySets
using Dates 
using JLD2

set_default_model("gurobi")

function compile_run()
    t1 = time()
    lows = [-0.9, 0.05, -0.1,  0.0,  0.0, -0.1]
    highs = [-0.8, 0.06,  0.1,  0.1,  0.1,  0.1]
    input_set = Hyperrectangle(low=lows, high=highs)
    nsteps = 2
    concretization_intervals = [2]
    quad_6D_reach(input_set, nsteps, concretization_intervals)
    println("time for compile run: ", time() - t1)
end

function quad_6D_reach(input_set, nsteps, concretization_intervals)
    # read nnet 
    controller_filepath = "nnet_files/extra/clamped_cloned_quad_policy_regularized1e-7_smallest.nnet"
    println("Controller is: $(controller_filepath)")
    query = OvertQuery(
        Quad_6D,
        controller_filepath,
        Id(), # last layer activation 
        "MIP",
        nsteps, # ntime 
        0.1, # dt 
        -1, # N OVERT
    )

    t1 = time()
    concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query, input_set, concretization_intervals)
    t2 = Dates.time()
    dt = (t2-t1)
    print("elapsed time= $(dt) seconds")

    # Intersect reachable sets with avoid set 
    # construct avoid set as HPolytope from Hyperplanes
    lx = HalfSpace([-1.,  0.,  0., 0., 0., 0.], 0.1) # x >= -0.1  ->  0.1 >= -x aka -x <= 0.1
    hx = HalfSpace([ 1.,  0.,  0., 0., 0., 0.], 0.1) # x <= 0.1
    ly = HalfSpace([ 0., -1.,  0., 0., 0., 0.], 0.1) # -y <= 0.1 aka y >= -0.1
    hy = HalfSpace([ 0.,  1.,  0., 0., 0., 0.], 0.1) # y <= 0.1
    lz = HalfSpace([ 0.,  0., -1., 0., 0., 0.], 0.1) # -z <= 0.1 aka z >= -0.1
    hz = HalfSpace([ 0.,  0.,  1., 0., 0., 0.], 0.1) # z <= 0.1
    avoid_sets = [HPolyhedron([lx, hx, ly, hy, lz, hz])] # square around the origin 

    t1 = time()
    safe, violations = check_avoid_set_intersection(symbolic_state_sets, input_set, avoid_sets)
    dt_check = time() - t1

    return (query=query, input_set=input_set, conc_int=concretization_intervals, conc_st_sets=concrete_state_sets, conc_ms_sets=concrete_meas_sets, sym_st_sets=symbolic_state_sets, sym_ms_sets=symbolic_meas_sets, dt=dt, cntrl=controller_filepath, avoid_sets=avoid_sets, safe=safe, vio=violations, dt_check=dt_check) #named tuple
end

compile_run()

#########
# First check above y-axis 
#########
# starting set: 
# Recall that state is: px, py, pz, vx, vy, vz 
lows = [-0.9, 0.05, -0.1,  0.0,  0.0, -0.1]
highs = [-0.8, 0.06,  0.1,  0.1,  0.1,  0.1]
input_set = Hyperrectangle(low=lows, high=highs)
println("input set is: low:", low(input_set), " high: ", high(input_set))
nsteps = 15
concretization_intervals = Int.(ones(nsteps)) 
top_data = quad_6D_reach(input_set, nsteps, concretization_intervals)
JLD2.@save "src/examples/extra/data/quad6D_reachability_data_15_top_1step.jld2" top_data

#########
# Now check below y-axis 
#########
# starting set: 
# Recall that state is: px, py, pz, vx, vy, vz 
lows_b = [-0.9, -0.06, -0.1,  0.0,  -0.1, -0.1]
highs_b = [-0.8, -0.05,  0.1,  0.1,  0.0,  0.1]
input_set_b = Hyperrectangle(low=lows_b, high=highs_b)
println("input set is: low:", low(input_set_b), " high: ", high(input_set_b))
bottom_data = quad_6D_reach(input_set_b, nsteps, concretization_intervals)

JLD2.@save "src/examples/extra/data/quad6D_reachability_data_15_bottom_1step.jld2" bottom_data
