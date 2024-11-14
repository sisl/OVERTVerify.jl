# these example scripts are not part of the Package, just examples of how to use it.
# using OVERTVerify
using Gurobi
include("../../dependencies.jl")
using LazySets
using Dates 
using JLD2
using .Sys

set_default_model("gurobi")

function quad_12D_reach(; data_dir="$pwd()/data", compile=true)
    if !isdir(data_dir)
        @warn "Creating storage directories $data_dir and $data_dir/quad6D"
        mkdir(data_dir)
        mkdir(data_dir*"/quad6D")
    end

    # log machine info 
    mi = MachineInfo(VERSION, Sys.total_memory()/2^20, Sys.CPU_NAME, Sys.CPU_THREADS, Sys.MACHINE)
    
    # read nnet 
    controller_filepath = "Networks/ARCH-COMP-2023/nnet/controllerQuad.nnet" # TODO: fix
    println("Controller is: $(controller_filepath)")
    e = 1e-8 # @sam: changed parameter name because epsilon refers to approximation tolerance
    input_set = Hyperrectangle(low=[-0.4,-0.4,-0.4,-0.4,-0.4,-0.4,-e,-e,-e,-e,-e,-e], high=[0.4,0.4,0.4,0.4,0.4,0.4,e,e,e,e,e,e])
    dt = 0.1
    numsteps = 50
    query = OvertQuery(
        Quad_12D,
        controller_filepath,
        Id(), # last layer activation 
        "MIP",
        numsteps, # ntime 
        dt, # dt 
        -1, # N OVERT
    )

    if compile
        query.ntime = 5
        _ = symbolic_reachability_with_concretization(query, input_set, [3,2])
        query.ntime = numsteps
    end

    # timed run # BOOKMARK
    concretization_intervals = [10,10,10,10,10] # just a guess, not tuned at all
    t1 = time()
    concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query, input_set, concretization_intervals)
    t2 = Dates.time()
    dt = (t2-t1)
    print("elapsed time= $(dt) seconds")

    _, reachable_state_sets = clean_up_sets(concrete_state_sets, symbolic_state_sets, concretization_intervals)

    # not checking avoid sets bc not sure what you want to check

    timestamp = now()

    JLD2.@save "$data_dir/acc/acc_reachability_data_$(query.ntime)steps_ht.jld2" query input_set concretization_intervals concrete_state_sets concrete_meas_sets symbolic_state_sets symbolic_meas_sets dt controller_filepath reachable_state_sets mi timestamp

    return dt
end