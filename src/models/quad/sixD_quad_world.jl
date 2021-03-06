using OVERT
using SymEngine
g = 9.81
function quad_dynamics_6D_world(x::Array{T, 1} where {T <:Real},
                       u::Array{T,1} where {T <:Real})
    """
    Quadrotor 6D dynamics in a world-centered frame. More complicated than the body-centered dynamics. 
    """
    # state is px, py, pz, vx, vy, vz 
    px, py, pz, vx, vy, vz = x
    θ, ϕ, τ = u
    dpx = vx 
    dpy = vy 
    dpz = vz 
    dvx = -τ * sin(θ)  # assumes mass is one I think
    dvy = τ * cos(θ) * sin(ϕ)
    dvz =  g - τ * cos(θ) * cos(ϕ)

    return [dpx, dpy, dpz, dvx, dvy, dvz]
end

quad_6_dvx = :(-τ * sin(θ))
quad_6_dvy = :(τ * cos(θ) * sin(ϕ))
quad_6_dvz = :($g - τ * cos(θ) * cos(ϕ))

quad_dynamics_6D_world_overt = get_overt_dynamics([quad_6_dvx, quad_6_dvy, quad_6_dvz], [:θ, :ϕ, :τ], 1e-4)

quad_6D_world_inputs = [:px, :py, :pz, :vx, :vy, :vz]
quad_6D_world_controls = [:θ, :ϕ, :τ]

function quad_6D_world_update_rule(input_vars, control_vars, overt_output_vars)
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
Quad_6D_world = OvertProblem(
    quad_dynamics_6D_world,
    quad_dynamics_6D_world_overt,
    quad_6D_world_update_rule,
    quad_6D_world_inputs,
    quad_6D_world_controls
)

# then: use a random network to test!