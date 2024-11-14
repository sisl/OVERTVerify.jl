using Gurobi
using LazySets
using Dates
using OVERTVerify
using JuMP
using MathOptInterface


controller_type = "small" # pass from command line, e.g. "small"
controller = "nnet_files/jmlr/single_pendulum_$(controller_type)_controller.nnet"
println("Controller: ", controller)
query = OvertQuery(
	SinglePendulum,    # problem
	controller,        # network file
	Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",             # query solver, "MIP" or "ReluPlex"
	10,                # ntime
	0.1,               # dt
	2,                # N_overt
	)

input_set = Hyperrectangle(low=[1., 0.], high=[1.2, 0.2])
concretization_intervals = [10, 10, 5]
t1 = Dates.time()

# concretize_every = concretization_intervals
# reachSet = OVERTVerify.one_timestep_concretization(query, input_set)

reachSet, boo, oASets, bah = OVERTVerify.many_timestep_concretization(query, input_set)


sym_mip = OVERTVerify.setup_mip_with_overt_constraints(query, input_set)

OVERTVerify.add_controllers_constraints!(sym_mip, query, reachSet)

@time OVERTVerify.symbolic_reachability(query, input_set, get_meas=true)
# #Do reachability out here 
# ntime = query.ntime # number of 
# if isa(concretize_every, Int)
#     @assert ntime % concretize_every == 0
#     n_loops = Int(query.ntime / concretize_every)
#     concretize_every = [concretize_every for i in 1:n_loops]
# elseif isa(concretize_every, Array{Int, 1})
#     @assert sum(concretize_every) == query.ntime # make sure the concretization intervals add up to total time 
# end

# all_concrete_sets = []
# all_symbolic_sets = []
# all_concrete_meas_sets = []
# all_symbolic_meas_sets = []
# this_set = copy(input_set)

# #NOTE: Loop starts here. Revisit
# t1 = time()
# query.ntime = 10 #should be n in loop

# #Here we call symbolic reach, skip for now 
# # concrete_sets, symbolic_set, concrete_meas_sets, symbolic_meas_set = symbolic_reachability(query, this_set, get_meas=true)

# #This is normally where we would set up MIP with OVERT constraints
# #mip_model, all_sets, all_meas_sets, all_oA_vars = OVERTVerify.setup_mip_with_overt_constraints(query, this_set) #input_set is replaced with this_set

# #If we go inside, we just concretize over many time steps 
# #all_sets, all_meas_sets, all_oA, all_oA_vars = many_timestep_concretization(query, input_set; timed=true)

# #Similarly if we go inside, we just loop over timesteps, and concretize 

# #If we continue this, we eventually get to setup_overt_and_controller_constraints, and solve_for_reachability. This is what we want to compare OvertPoly to

# ##Setup overt and controller constraints
# dynamics = query.problem.overt_dynamics
# input_vars = query.problem.input_vars
# control_vars = query.problem.control_vars

# network_file = query.network_file
# last_layer_activation = query.last_layer_activation
# N_overt = query.N_overt

# range_dict = Dict{Symbol, Array{Float64,1}}()
# for i = 1:length(input_vars)
#     range_dict[input_vars[i]] = [input_set.center[i] - input_set.radius[i],
#                                 input_set.center[i] + input_set.radius[i]]
# end

# #Account for controller variable here via find_controller_bound
# cntr_bound = OVERTVerify.find_controller_bound(network_file, input_set, last_layer_activation)
# for i = 1:length(control_vars)
# range_dict[control_vars[i]] = [cntr_bound.center[i] - cntr_bound.radius[i],
#                              cntr_bound.center[i] + cntr_bound.radius[i]]
# end

# range_dict

# oA, oA_vars = dynamics(range_dict, N_overt, nothing)
# oA

# #This is the actual MIP model generated for the problem
# #NOTE:35 vars, 12 binary
# mip_model = OVERTVerify.OvertMIP(oA)
# mip_model

# #Need to include controller constraints as well
# mip_control_input_vars = [OVERTVerify.get_mip_var(v, mip_model) for v in input_vars]
# mip_control_output_vars = [OVERTVerify.get_mip_var(v, mip_model) for v in control_vars]
# controller_bound = OVERTVerify.add_controller_constraints(mip_model.model, network_file, input_set, mip_control_input_vars, mip_control_output_vars)

# mip_control_input_vars
# mip_control_output_vars
# OVERTVerify.mip_summary(mip_model.model)
# t_idx = nothing 

# @time reachSet = OVERTVerify.solve_for_reachability(mip_model, query, oA_vars, t_idx)

reachSet