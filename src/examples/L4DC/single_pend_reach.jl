using Gurobi
using OVERTVerify
using LazySets
using Dates
include("models/single_pendulum/single_pend.jl")

println("Running SinglePendulum Benchmark")
controller = "../../../nnet_files/L4DC/controllerSinglePendulum.nnet"
controller = "nnet_files/L4DC/controllerSinglePendulum.nnet"

query = OVERTVerify.OvertQuery(
	SinglePendulum2,    # problem
	controller,        # network file
	Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",             # query solver, "MIP" or "ReluPlex"
	20,                # ntime
	0.05,               # dt
	2,                # N_overt
	)
input_set = Hyperrectangle(low=[1., 0.], high=[1.2, 0.2])

#Unitimed run
query1 = deepcopy(query)
sets, bounds = OVERTVerify.many_timestep_concretization(query, input_set);

#Timed run
tstart = Dates.now()
query1 = deepcopy(query)
@time sets, bounds = OVERTVerify.many_timestep_concretization(query, input_set);
tend = Dates.now()
println(volume(sets[11]))
println("#############################################################################################")
println("Time taken to compute concrete reach: ", tend-tstart)
println("###################################################################################")
# extrema(sets[11])[2][1] - extrema(sets[11])[1][1]

#@time res = OVERTVerify.symbolic_reachability(query, input_set)

# extrema(res[2])[1]
# extrema(res[2])[2]
# we want to check the intersection with the avoid set: x_1 <= -.2167

# avoid_set = [HalfSpace([1., 0.], -0.2617)] # 1*x_1 + 0*x_2 <= -.2167  -->  x_1 <= -.2167 

# tstart = Dates.now()
# init_set0, reachable_state_sets = clean_up_sets(concrete_state_sets, symbolic_state_sets, concretization_intervals)
# safe, violations = check_avoid_set_intersection(reachable_state_sets, input_set, avoid_set)
# tend = Dates.now()
# println("######################################################################################")
# println("Time taken to verify property: ", tend-tstart)
# println("######################################################################################")

 