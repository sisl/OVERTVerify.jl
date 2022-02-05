using OVERT
g = 9.81
function quad_dynamics_6D(x::Array{T, 1} where {T <:Real},
                       u::Array{T,1} where {T <:Real})
    # state is px, py, pz, vx, vy, vz 
    px, py, pz, vx, vy, vz = x
    θ, ϕ, τ = u
    dpx = vx 
    dpy = vy 
    dpz = vz 
    dvx = g*tan(θ)
    dvy = -g*tan(ϕ)
    dvz = τ - g 

    return [dpx, dpy, dpz, dvx, dvy, dvz]
end

quad_6_dvx = :($g * tan(θ))
quad_6_dvy = :($(-g) * tan(ϕ))
quad_6_dvz = :(τ - $g) # doesn't need overapproximation, but the pipeline as of now will pass it through OVERT and it will remain unchanged.

quad_dynamics_6D_overt = get_overt_dynamics([quad_6_dvx, quad_6_dvy, quad_6_dvz], [:θ, :ϕ, :τ], 1e-4)

quad_6D_inputs = [:px, :py, :pz, :vx, :vy, :vz]
quad_6D_controls = [:θ, :ϕ, :τ]

function quad_6D_update_rule(input_vars, control_vars, overt_output_vars)
    integration_map = Dict(input_vars[1] => input_vars[4],
                           input_vars[2] => input_vars[5],
                           input_vars[3] => input_vars[6],
                           input_vars[4] => overt_output_vars[1],
                           input_vars[5] => overt_output_vars[2],
                           input_vars[6] => overt_output_vars[3]
                        )
    return integration_map
end

# leave measurement model empty 
Quad_6D = OvertProblem(
    quad_dynamics_6D,
    quad_dynamics_6D_overt,
    quad_6D_update_rule,
    quad_6D_inputs,
    quad_6D_controls
)

# then: use a random network to test!