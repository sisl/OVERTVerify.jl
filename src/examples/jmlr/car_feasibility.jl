include("../../models/problems.jl")
include("../../overt_to_mip.jl")
include("../../reachability_functions.jl")
include("../../models/car/simple_car.jl")
include("../../overt_parser_minimal.jl")
using JLD2
using LazySets

function run_query(query_number, avoid_set, controller_name; threads=0)
	controller = "nnet_files/jmlr/car_"*controller_name*"_controller.nnet"
	println("Controller is: ", controller)

	query = OvertQuery(
		SimpleCar,  # problem
		controller,    # network file
		Id(),      	# last layer activation layer Id()=linear
		"MIP",     	# query solver, "MIP" or "ReluPlex"
		10,        	# ntime
		0.2,       	# dt
		-1,        	# N_overt
		)

	input_set = Hyperrectangle(low=[9.5, -4.5, 2.1, 1.5], high=[9.55, -4.45, 2.11, 1.51])
	t1 = Dates.time()
	SATii, valii, statii = symbolic_satisfiability(query, input_set, avoid_set; return_all=true, threads=threads)
	println("satii is: ", SATii)
	t2 = Dates.time()
	dt = (t2-t1)
	println("dt is $dt")

	JLD2.@save "src/examples/jmlr/data/car_satisfiability_"*string(controller_name)*"_controller_data_q"*string(query_number)*".jld2" query input_set avoid_set SATii valii statii dt

	println("satii after save is: ", SATii)
	return SATii
end

function run_car_satisfiability(; controller_name="smallest", threads=0)
	# In this example, our property is the following:
	# We want the car to reach the box [-.6, .6] [-.2,.2]
	# at SOME point in the time history
	# we will perform 4 separate queries and "AND" them together to look
	# for a point where all properties hold

	# query 1  x1 <= -0.6
	avoid_set1 = HalfSpace([1.0, 0.0, 0.0, 0.0], -0.6)
	# query 2 x1 >= 0.6  ->  -0.6 >= -x1   ->  -x1 <= -0.6
	avoid_set2 = HalfSpace([-1.0, 0.0, 0.0, 0.0], -0.6)
	# query 3  x2 <= -0.2
	avoid_set3 = HalfSpace([1.0, 0.0, 0.0, 0.0], -0.2) 
	# query 4  x2 >= 0.2  aka -x2 <= -0.2
	avoid_set4 = HalfSpace([-1.0, 0.0, 0.0, 0.0], -0.2)
	avoid_sets = [avoid_set1, avoid_set2, avoid_set3, avoid_set4]

	SAT = []

	s = ["unsat", "unsat"]
	for enum = enumerate(avoid_sets)
		i, avoid_set = enum
		if ~all(s .== "sat") # possibly quit early if all of s = "sat"
			s = run_query(i, avoid_set, controller_name, threads=threads)
			# BOOKMARK: add breakpoint here to see why s isn't being pushed onto the SAT array...
			push!(SAT, s)
		else
			println("skipping property ", i, " because prior property does not hold any time.")
		end
	end

	# now we want to know when all properties hold
	all_hold = [true for _ in 1:length(SAT[1])]
	for i = 1:length(SAT)
		all_hold = all_hold .& (SAT[i] .== "unsat")
	end
	timesteps_where_properties_hold = findall(all_hold)
	if length(timesteps_where_properties_hold) > 0
		println("The property holds at timestep: ", timesteps_where_properties_hold)
	else
		println("The property does not hold.")
	end

	JLD2.@save "src/examples/jmlr/data/car_satisfiability_"*string(controller_name)*"_controller_data_final_result.jld2" SAT timesteps_where_properties_hold
end

# 0 threads means "let gurobi decide how many threads it wants"
run_car_satisfiability(controller_name=ARGS[1], threads=0)
