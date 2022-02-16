using LazySets
export
    OvertProblem,
    OvertQuery,
	InfiniteHyperrectangle


mutable struct OvertProblem
	true_dynamics
	overt_dynamics
	update_rule
	input_vars
	control_vars
 	measurement_model
end
OvertProblem(td, od, ur, iv, cv) = OvertProblem(td, od, ur, iv, cv, [])

mutable struct OvertQuery
	problem::OvertProblem
	network_file::String
	last_layer_activation ##::ActivationFunction
	solver::String
	ntime::Int64
	dt::Float64
	N_overt::Int64
end

Base.copy(x::OvertQuery) = OvertQuery(
	x.problem,
	x.network_file,
	x.last_layer_activation,
	x.type,
	x.ntime,
	x.dt,
	x.N_overt
	)

# this datastructure allows the hyperrectnagle to have inifinite length.
# used for satisfiability target.
struct InfiniteHyperrectangle
	low
	high
	function InfiniteHyperrectangle(low, high)
		@assert all(low .≤	high) "low must not be greater than high"
		return new(low, high)
	end
end

import LazySets.low
import LazySets.high
low(x::InfiniteHyperrectangle) = x.low
high(x::InfiniteHyperrectangle) = x.high


function time_exprs(exprs, vars_to_time, t)
	timed_vars = [Meta.parse("$(v)_$(t)") for v in vars_to_time]
	map = Dict(zip(vars_to_time, timed_vars))
	timed_exprs = []
	for e in exprs
		push!(timed_exprs, substitute(e, map))
	end
	return timed_exprs
end

# construct OVERT'ed version of problem given expressions of dynamics 
function get_overt_dynamics(exprs, vars_to_time=[], ϵ=1e-4)
	# return this function for a given problem.
	function overt_dynamics_fun(range_dict::Dict{Symbol, Array{T, 1}} where {T <: Real}, N_OVERT::Int=-1, t_idx::Union{Int, Nothing}=nothing)
		# first determine whether dynamics need to be timestamped 
		if !isnothing(t_idx)
			exprs = time_exprs(exprs, vars_to_time, t_idx)
			@debug("timed expressions: $(exprs)")
		end
		oAs = OVERT.OverApproximation[]
		for expr in exprs 
			push!(oAs, overapprox(expr, range_dict; N=N_OVERT, ϵ=ϵ))
		end
		oA_out = add_overapproximate(oAs)
		return oA_out, [oA.output for oA in oAs]
	end 
	return overt_dynamics_fun
end