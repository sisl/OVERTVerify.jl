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
query = OvertQuery(
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
@time sets_val, bounds_val = many_timestep_concretization(query, input_set);
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
@time sets_val, bounds_val = many_timestep_concretization(query, input_set);
t2 = now()
dt = t2 - t1
@info "End time: $t2"
@info "Elapsed time: $dt seconds"
@info "Set volume at final step: $(volume(sets_val[end]))"