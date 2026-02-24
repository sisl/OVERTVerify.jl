using Gurobi
using OVERTVerify
using LazySets
using Dates

# controller_type = ARGS[1] # pass from command line, e.g. "small"
# controller = "nnet_files/jmlr/single_pendulum_$(controller_type)_controller.nnet"
controller = "nnet_files/L4DC/controllerSinglePendulum.nnet"
println("Controller: ", controller)
query = OvertQuery(
	SinglePendulum,    # problem
	controller,        # network file
	Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",             # query solver, "MIP" or "ReluPlex"
	20,                # ntime
	0.05,               # dt
	2,                # N_overt
	)

input_set = Hyperrectangle(low=[1., 0.], high=[1.2, 0.2])
# concretization_intervals = [10, 10, 5]
concretization_intervals = [10]

#@time concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query, input_set, concretization_intervals);

sets, bounds = @time OVERTVerify.many_timestep_concretization(query, input_set);
volume(sets[10])

# sets[11]
# extrema(sets[11])[2][1] - extrema(sets[11])[1][1]

#@time res = OVERTVerify.symbolic_reachability(query, input_set)

extrema(res[2])[1]
extrema(res[2])[2]
# we want to check the intersection with the avoid set: x_1 <= -.2167

avoid_set = [HalfSpace([1., 0.], -0.2617)] # 1*x_1 + 0*x_2 <= -.2167  -->  x_1 <= -.2167 

init_set0, reachable_state_sets = clean_up_sets(concrete_state_sets, symbolic_state_sets, concretization_intervals)

t1 = time()
safe, violations = check_avoid_set_intersection(reachable_state_sets, input_set, avoid_set)
dt_check = time() - t1

using JLD2
JLD2.@save "src/examples/jmlr/data/single_pendulum_reachability_$(controller_type)_controller_data.jld2" query input_set concretization_intervals concrete_state_sets concrete_meas_sets symbolic_state_sets symbolic_meas_sets dt controller avoid_set reachable_state_sets safe violations dt_check
 