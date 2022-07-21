# quad feasibility
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
    quad_6D_feas(input_set, nsteps)
    println("time for compile run: ", time() - t1)
end

function quad_6D_feas(input_set, nsteps)
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

    # Because we are dealing with an avoid set property "Quad never enter avoid set" we enforce complement: "Quad intersects avoid set" 
    # construct avoid set as HPolytope from Hyperplanes
    lx = HalfSpace([-1.,  0.,  0., 0., 0., 0.], 0.1) # x >= -0.1  ->  0.1 >= -x aka -x <= 0.1
    hx = HalfSpace([ 1.,  0.,  0., 0., 0., 0.], 0.1) # x <= 0.1
    ly = HalfSpace([ 0., -1.,  0., 0., 0., 0.], 0.1) # -y <= 0.1 aka y >= -0.1
    hy = HalfSpace([ 0.,  1.,  0., 0., 0., 0.], 0.1) # y <= 0.1
    lz = HalfSpace([ 0.,  0., -1., 0., 0., 0.], 0.1) # -z <= 0.1 aka z >= -0.1
    hz = HalfSpace([ 0.,  0.,  1., 0., 0., 0.], 0.1) # z <= 0.1
    avoid_set = HPolyhedron([lx, hx, ly, hy, lz, hz])

    t1 = time()
    SATus, vals, stats = symbolic_satisfiability(query, input_set, avoid_set, apply_meas=false)
    t2 = time()
    dt = t2 - t1

    return (query=query, input_set=input_set, avoid_set=avoid_set, SATus=SATus, vals=vals, stats=stats, dt=dt, controller_filepath=controller_filepath)

end

compile_run()

nsteps=15
# top 
# starting set: 
# Recall that state is: px, py, pz, vx, vy, vz 
lows = [-0.9, 0.05, -0.1,  0.0,  0.0, -0.1]
highs = [-0.8, 0.06,  0.1,  0.1,  0.1,  0.1]
input_set_top = Hyperrectangle(low=lows, high=highs)
println("input set top is: low:", low(input_set_top), " high: ", high(input_set_top))

top_data = quad_6D_feas(input_set_top, nsteps)
JLD2.@save "src/examples/extra/data/quad6D_feasibility_data_15_top.jld2" top_data


# bottom 
# starting set: 
# Recall that state is: px, py, pz, vx, vy, vz 
lows_b = [-0.9, -0.06, -0.1,  0.0,  -0.1, -0.1]
highs_b = [-0.8, -0.05,  0.1,  0.1,  0.0,  0.1]
input_set_bottom = Hyperrectangle(low=lows_b, high=highs_b)
println("input set is: low:", low(input_set_bottom), " high: ", high(input_set_bottom))

bottom_data = quad_6D_feas(input_set_bottom, nsteps)
JLD2.@save "src/examples/extra/data/quad6D_feasibility_data_15_bottom.jld2" bottom_data