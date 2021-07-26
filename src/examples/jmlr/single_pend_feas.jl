# run this with: julia1.5 --project="." examples/jmlr/single_pend_feas.jl "small" |& tee examples/jmlr/single_pend_feas_log.txt

using OVERTVerify
using LazySets
using Dates

controller_type = ARGS[1] # pass from command line, e.g. "small"
controller = "nnet_files/jmlr/single_pendulum_$(controller_type)_controller.nnet"
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
target_set = HalfSpace([1., 0.], -0.2617) # 1*x_1 + 0*x_2 <= -.2167  -->  x_1 <= -.2167 
t1 = Dates.time()
SATus, vals, stats = symbolic_satisfiability(query, input_set, target_set)
t2 = Dates.time()
dt = (t2-t1)

using JLD2
JLD2.@save "src/examples/jmlr/data/single_pendulum_satisfiability_$(controller_type)_controller_data.jld2" query input_set target_set SATus vals stats dt controller
