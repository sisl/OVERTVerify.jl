using Gurobi
using OVERTVerify
using LazySets
using Dates

println("Running SinglePendulum Benchmark")
controller = "../../../nnet_files/L4DC/controllerTORA.nnet"
controller = "nnet_files/L4DC/controllerTORA.nnet"
query = OvertQuery(
	Tora,      # problem
	controller, # network file
	Id(),    # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",     # query solver, "MIP" or "ReluPlex"
	20,        # ntime
	0.1,       # dt
	2,        # N_overt
	)

input_set = Hyperrectangle(low=[0.6, -0.7, -0.4, 0.5], high=[0.7, -0.6, -0.3, 0.6])
#Unitimed run
query1 = deepcopy(query)
@time sets, bounds = OVERTVerify.many_timestep_concretization(query, input_set);
volume(sets[end])

#Timed run
tstart = Dates.now()
query1 = deepcopy(query)
@time sets, bounds = OVERTVerify.many_timestep_concretization(query, input_set);
tend = Dates.now()
println(volume(sets[end]))
println("#############################################################################################")
println("Time taken to compute concrete reach: ", tend-tstart)
println("###################################################################################")
# clean up sets 
# init_set0, reachable_state_sets = clean_up_sets(concrete_state_sets, symbolic_state_sets, concretization_intervals)

# # we want to check inclusion in the safe set:
# constraint1 = HalfSpace([1., 0., 0., 0.], 2.) # x1 <= 2
# constraint2 = HalfSpace([-1., 0., 0., 0.], 2.) # -x1 <= 2 aka x1 >= -2
# safe_set = HPolyhedron([constraint1, constraint2])
# t1 = time()
# safe_steps = reachable_state_sets .⊆ Ref(safe_set)
# violations = .!safe_steps
# safe = all(safe_steps)
# dt_check = time() - t1

# using JLD2
# JLD2.@save "src/examples/jmlr/data/tora_reachability_$(controller_name)_controller_data.jld2" query input_set safe_set concrete_state_sets symbolic_state_sets concrete_meas_sets symbolic_meas_sets reachable_state_sets dt safe violations dt_check concretization_intervals
