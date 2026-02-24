using Gurobi
#using OVERTVerify
using LazySets
using Dates
using JLD2
using JuMP
# include("../../utilities.jl")
# include("../../OVERTVerify.jl")
# include("models/problems.jl")
# include("models/car/simple_car.jl")
# include("../../overt_to_mip.jl")
include("../../dependencies.jl")
include("../../reachability_functions.jl")
#ENV["JULIA_DEBUG"] = Main
println("Running Car Benchmark")

controller = "nnet_files/Breach/controller250Unicycle.nnet"

query = OvertQuery(
	SimpleCar,  # problem
	controller,    # network file
	Id(),      	# last layer activation layer Id()=linear
	"MIP",     	# query solver, "MIP" or "ReluPlex"
	2,        	# ntime
	0.2,       	# dt
	2,        	# N_overt
	)

goal_set = Hyperrectangle(low=[-0.5,-0.5,-0.5,-0.5], high = [0.5,0.5,0.5,0.5])
bw_domain = Hyperrectangle(low=[-12,-12,-3.14,-1], high = [12,12,3.14,1])
depMat = [[1,0,1,1],[0,1,1,1], [0,0,1,0], [0,0,0,1]]
query1 = deepcopy(query)
query2 = deepcopy(query)
@time bset = one_timestep_bconcretization(query1, bw_domain, goal_set)
# LazySets.volume(bset)
# extrema(bset)
query2.ntime = 5
@time bsets = many_timestep_bconcretization(query2, bw_domain, goal_set)

extrema(bsets[end])

query2 = deepcopy(query)
@time refined_bset = refine_drip(query2, goal_set, bset)

extrema(refined_bset)
LazySets.volume(refined_bset)

bsets
# #####Scaling Benchmark###############
# for i=1:2
# 	squery = deepcopy(query)
# 	squery.ntime = i
# 	@time OVERTVerify.symbolic_reachability(squery::OvertQuery, input_set::Hyperrectangle)
# end

# for i=1:20
# 	println("Running for ntime = ", i)
# 	squery = deepcopy(query)
# 	squery.ntime = i
# 	println(i)
# 	@time OVERTVerify.symbolic_reachability(squery::OvertQuery, input_set::Hyperrectangle)
# end
