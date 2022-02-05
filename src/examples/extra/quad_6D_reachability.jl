# these example scripts are not part of the Package, just examples of how to use it.
# using OVERTVerify
using LazySets
using Dates 
using JLD2

# use random network that takes 6 inputs (state) and outputs 3 controls 
# net = OVERTVerify.random_network([6,5,3], [ReLU(), Id()])
# OVERTVerify.write_nnet("nnet_files/extra/quad_6D_random.nnet", net)

# read nnet 
controller_filepath = "../nnet_files/extra/quad_6D_random.nnet"
println("Controller is: $(controller_filepath)")
query = OvertQuery(
    Quad_6D,
    controller_filepath,
    Id(), # last layer activation 
    "MIP",
    5, # ntime 
    0.1, # dt 
    -1, # N OVERT
)

# starting set: 
# Recall that state is: px, py, pz, vx, vy, vz 
lows = [-1., -1., -1., -0.1, -0.1, -0.1]
highs = -lows
input_set = Hyperrectangle(low=lows, high=highs)

concretization_intervals = [5] 
t1 = time()
concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query, input_set, concretization_intervals)
t2 = Dates.time()
dt = (t2-t1)
print("elapsed time= $(dt) seconds")

