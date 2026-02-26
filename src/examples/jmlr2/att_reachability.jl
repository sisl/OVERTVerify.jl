using Gurobi
include("../../dependencies.jl")
using LazySets
using Dates
using TOML
using Logging 
#ENV["JULIA_DEBUG"] = Main

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
	Attitude,  # problem
	controller,    # network file
	Id(),      	# last layer activation layer Id()=linear
	"MIP",     	# query solver, "MIP" or "ReluPlex"
	2,        	# ntime
	0.1,       	# dt
	2,        	# N_overt
	)

input_set = Hyperrectangle(low=[-0.75, 0.85, -0.65, -0.45, -0.55, 0.65], high=[-0.74, 0.86, -0.64, -0.44, -0.54, 0.66])
concretization_intervals = [2]
t1 = Dates.time()
@time concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query1, input_set, concretization_intervals);
# symbolic_state_sets[end]
# symbolic_state_sets[2]
t2 = Dates.time()
dt = (t2-t1)
print("elapsed time= $(dt) seconds")

#Timed run
@info "Timed run"
query = OvertQuery(
	Attitude,  # problem
	controller,    # network file
	Id(),      	# last layer activation layer Id()=linear
	"MIP",     	# query solver, "MIP" or "ReluPlex"
	ntime,        	# ntime
	0.1,       	# dt
	2,        	# N_overt
	)

concretization_intervals = [ntime]
t1 = now()
@info "Start time: $t1"
@time concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query, input_set, concretization_intervals, timeout=3600);
t2 = now()
dt = t2 - t1
@info "End time: $t2"
@info "Elapsed time: $dt seconds"
@info "Set volume at final step: $(LazySets.volume(symbolic_state_sets[end]))"