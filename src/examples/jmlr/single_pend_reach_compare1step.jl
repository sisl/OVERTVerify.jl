include("../../models/problems.jl")
include("../../overt_to_mip.jl")
include("../../mip_utils.jl")
include("../../models/single_pendulum/single_pend.jl")
include("../../overt_parser_minimal.jl")

controller_type = ARGS[1] # pass from command line, e.g. "small"
controller = "nnet_files/jair/single_pendulum_$(controller_type)_controller.nnet"
println("Controller: ", controller)
query = OvertQuery(
	SinglePendulum,    # problem
	controller,        # network file
	Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",             # query solver, "MIP" or "ReluPlex"
	25,                # ntime
	0.1,               # dt
	-1,                # N_overt
	)

input_set = Hyperrectangle(low=[1., 0.], high=[1.2, 0.2])
concretization_intervals = Int.(ones(query.ntime))
t1 = Dates.time()
concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query, input_set, concretization_intervals)
t2 = Dates.time()
dt = (t2-t1)
print("elapsed time= $(dt) seconds")

# we want to check the intersection with the avoid set: x_1 <= -.2167
avoid_set = [HalfSpace([1., 0.], -0.2167)] # 1*x_1 + 0*x_2 <= -.2167  --> x_1 <= -.2167

t1 = time()
safe, violations = check_avoid_set_intersection(symbolic_state_sets, input_set, avoid_set)
dt_check = time() - t1

using JLD2
JLD2.@save "src/examples/jmlr/data/single_pendulum_reachability_$(controller_type)_controller_data_1step.jld2" query input_set concretization_intervals concrete_state_sets concrete_meas_sets symbolic_state_sets symbolic_meas_sets dt controller avoid_set safe violations dt_check
 