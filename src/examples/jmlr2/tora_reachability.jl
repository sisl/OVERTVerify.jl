using Gurobi
include("../../dependencies.jl")
using LazySets
using Dates
using TOML
using Logging 

exec_id = ARGS[1]
logfile = "logs/metrics/$(exec_id).log"
io = open(logfile, "a")
global_logger(SimpleLogger(io, Logging.Info))

@info "Logging run of tora benchmark" logfile=logfile

cfg = TOML.parsefile(ARGS[2])
controller = cfg["params"]["controller"]
ntime = cfg["params"]["ntime"]

@info "Warm up run"
@info "ntime: $ntime"
query1 = OvertQuery(
	Tora,      # problem
	controller, # network file
	Id(),    # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",     # query solver, "MIP" or "ReluPlex"
	2,        # ntime
	0.1,       # dt
	2,        # N_overt
	)

input_set = Hyperrectangle(low=[0.6, -0.7, -0.4, 0.5], high=[0.7, -0.6, -0.3, 0.6])
t1 = Dates.time()
concretization_intervals = [2]
@time concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query1, input_set, concretization_intervals);
symbolic_state_sets[end]
t2 = Dates.time()
dt = (t2-t1)
print("elapsed time= $(dt) seconds")

@info "Timed run"
query = OvertQuery(
	Tora,      # problem
	controller, # network file
	Id(),    # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",     # query solver, "MIP" or "ReluPlex"
	ntime,        # ntime
	0.1,       # dt
	2,        # N_overt
	)

t1 = now()
@info "Start time: $t1"
concretization_intervals = [10,10]
@time concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query, input_set, concretization_intervals);
symbolic_state_sets[end]
t2 = now()
dt = t2 - t1
@info "End time: $t2"
@info "Elapsed time: $dt seconds"
@info "Set volume at final step: $(LazySets.volume(symbolic_state_sets[end]))"