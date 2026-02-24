using Gurobi
using OVERTVerify
using LazySets
using Dates
using JLD2
#ENV["JULIA_DEBUG"] = Main
println("Running Car Benchmark")
controller = "../../../nnet_files/L4DC/controllerUnicycle.nnet"
controller = "nnet_files/L4DC/controllerUnicycle.nnet"

query = OvertQuery(
	SimpleCar,  # problem
	controller,    # network file
	Id(),      	# last layer activation layer Id()=linear
	"MIP",     	# query solver, "MIP" or "ReluPlex"
	50,        	# ntime
	0.2,       	# dt
	2,        	# N_overt
	)

input_set = Hyperrectangle(low=[9.5, -4.5, 2.1, 1.5], high=[9.55, -4.45, 2.11, 1.51])
# concretization_intervals = [5,5,5,5,5,5,5,5,5,5]
# Untimed run
query1 = deepcopy(query)
concretization_intervals = [5,5]
# query1.ntime = 10
# @time concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query1, input_set, concretization_intervals);

# # #Timed Running
# tstart = Dates.now()
# query1 = deepcopy(query)
# concretization_intervals = [10,10,10,10,10]
# @time concrete_state_sets, symbolic_state_sets, concrete_meas_sets, symbolic_meas_sets = symbolic_reachability_with_concretization(query1, input_set, concretization_intervals);

# volume(symbolic_state_sets[end])
# symbolic_state_sets[end]
# symbolic_state_sets[2]
# tend = Dates.now()
# println(volume(symbolic_state_sets[end]))
# println(extrema(symbolic_state_sets[end]))
# println("#############################################################################################")
# println("Time taken to compute concrete reach: ", tend-tstart)
# println("###################################################################################")
# # clean up sets
# init_set0, reachable_state_sets = clean_up_sets(concrete_state_sets, symbolic_state_sets, concretization_intervals, dims=[1,2])

# # In this example, our property is the following:
# # We want the car to reach the box [-.6, .6] [-.2,.2]
# # at SOME point in the time history
# # constraint 1  x1 >= -0.6  --> -x1 <= 0.6
# c1 = HalfSpace([-1.0, 0.0, 0.0, 0.0], 0.6)
# # constraint 2 x1 <= 0.6
# c2 = HalfSpace([1.0, 0.0, 0.0, 0.0], 0.6)
# # constraint 3  x2 >= -0.2   -> -x2 <= 0.2
# c3 = HalfSpace([-1.0, 0.0, 0.0, 0.0], 0.2) 
# # constraint 4  x2 <= 0.2
# c4 = HalfSpace([1.0, 0.0, 0.0, 0.0], 0.2)
# goal_set = HPolyhedron([c1, c2, c3, c4])
# t1 = time()
# goal_reached_steps = reachable_state_sets .⊆ Ref(goal_set)
# goal_reached = any(goal_reached_steps)
# dt_check = time() - t1
# println("Goal reached: $goal_reached")
# println("Goal reached at step: $(findfirst(goal_reached_steps))")

# JLD2.@save "src/examples/jmlr/data/car_reachability_"*string(controller_name)*"_controller_data.jld2" query input_set concretization_intervals goal_set concrete_state_sets symbolic_state_sets concrete_meas_sets symbolic_meas_sets reachable_state_sets dt goal_reached goal_reached_steps dt_check 
#untimed run

#####Scaling Benchmark###############
for i=1:2
	squery = deepcopy(query)
	squery.ntime = i
	@time OVERTVerify.symbolic_reachability(squery::OvertQuery, input_set::Hyperrectangle)
end

for i=1:20
	println("Running for ntime = ", i)
	squery = deepcopy(query)
	squery.ntime = i
	println(i)
	@time OVERTVerify.symbolic_reachability(squery::OvertQuery, input_set::Hyperrectangle)
end
