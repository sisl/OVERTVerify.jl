using Gurobi
include("../../dependencies.jl")
using LazySets
using Dates
using TOML
using Logging 
#ENV["JULIA_DEBUG"] = Main

#dARGS = [1234, "configs_to_run/2_unicycle_250.toml"]

exec_id = ARGS[1]
logfile = "logs/metrics/$(exec_id).log"
io = open(logfile, "a")
global_logger(SimpleLogger(io, Logging.Info))

@info "Logging run of car benchmark" logfile=logfile

cfg = TOML.parsefile(ARGS[2])
controller = cfg["params"]["controller"]
ntime = cfg["params"]["ntime"]

@info "Warm up run"
@info "ntime: $ntime"
query1 = OvertQuery(
	SimpleCar,  # problem
	controller,    # network file
	Id(),      	# last layer activation layer Id()=linear
	"MIP",     	# query solver, "MIP" or "ReluPlex"
	2,        	# ntime
	0.2,       	# dt
	2,        	# N_overt
	)

input_set = Hyperrectangle(low=[9.50,-4.50,2.10,1.50], high = [9.55,-4.45,2.11,1.51])
concretization_intervals = [2]
@time concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query1, input_set, concretization_intervals);
symbolic_state_sets[end]

#Timed run
@info "Timed run"
query = OvertQuery(
	SimpleCar,  # problem
	controller,    # network file
	Id(),      	# last layer activation layer Id()=linear
	"MIP",     	# query solver, "MIP" or "ReluPlex"
	ntime,        	# ntime
	0.2,       	# dt
	2,        	# N_overt
	)

input_set = Hyperrectangle(low=[9.50,-4.50,2.10,1.50], high = [9.55,-4.45,2.11,1.51])
concretization_intervals = [10,10,10,10,10]
t1 = now()
@info "Start time: $t1"
@time concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query, input_set, concretization_intervals, timeout=3600);
t2 = now()
dt = t2 - t1
@info "End time: $t2"
@info "Elapsed time: $dt seconds"
@info "Set volume at final step: $(LazySets.volume(symbolic_state_sets[end]))"