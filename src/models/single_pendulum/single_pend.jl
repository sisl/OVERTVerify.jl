using OVERT

pend_mass, pend_len, grav_const, friction = 0.5, 0.5, 1., 0.

function single_pend_dynamics(x::Array{T, 1} where {T <: Real},
	                          u::Array{T, 1} where {T <: Real})
    dx1 = x[2]
    dx2 = grav_const/pend_len * sin(x[1]) + 1 / (pend_mass*pend_len^2) * (u[1] - friction * x[2])
    return [dx1, dx2]
end

single_pend_θ_doubledot = :($(grav_const/pend_len) * sin(x1) + $(1/(pend_mass*pend_len^2)) * u1 - $(friction/(pend_mass*pend_len^2)) * x2)

function single_pend_dynamics_overt(range_dict::Dict{Symbol, Array{T, 1}} where {T <: Real},
	                                N_OVERT::Int,
									t_idx::Union{Int, Nothing}=nothing)
	if isnothing(t_idx)
		v1 = single_pend_θ_doubledot
	else
    	v1 = "$(grav_const/pend_len) * sin(x1_$t_idx) + $(1/(pend_mass*pend_len^2)) * u1_$t_idx - $(friction/(pend_mass*pend_len^2)) * x2_$t_idx"
    	v1 = Meta.parse(v1)
	end
    v1_oA = overapprox(v1, range_dict; N=N_OVERT)
    return v1_oA, [v1_oA.output]
end

function single_pend_update_rule(input_vars::Array{Symbol, 1},
	                             control_vars::Array{Symbol, 1},
								 overt_output_vars::Array{Symbol, 1})
    ddth = overt_output_vars[1]
    integration_map = Dict(input_vars[1] => input_vars[2], input_vars[2] => ddth)
    return integration_map
end

single_pend_input_vars = [:x1, :x2]
single_pend_control_vars = [:u1]

SinglePendulum = OvertProblem(
	single_pend_dynamics,
	single_pend_dynamics_overt,
	single_pend_update_rule,
	single_pend_input_vars,
	single_pend_control_vars
)
