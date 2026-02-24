using OVERT

function att_dynamics(x::Array{T, 1} where {T <: Real},
                      u::Array{T, 1} where {T <: Real})
    ψ₁′  = x[1] + (0.5*(x[5]*(x[1]^2 + x[2]^2 + x[3]^2 - x[3]) + x[6]*(x[1]^2 + x[2]^2 + x[2] + x[3]^2) + x[4]*(x[1]^2 + x[2]^2 + x[3]^2 + 1)))*0.1
    ψ₂′  = x[2] + (0.5*(x[4]*(x[1]^2 + x[2]^2 + x[3]^2 + x[3]) + x[6]*(x[1]^2 -x[1] + x[2]^2 + x[3]^2) + x[5]*(x[1]^2 + x[2]^2 + x[3]^2 + 1)))*0.1
    ψ₃′ = x[3] + (0.5*(x[4]*(x[1]^2 + x[2]^2 - x[2] + x[3]^2) + x[5]*(x[1]^2 + x[1] + x[2]^2 + x[3]^2) + x[6]*(x[1]^2 + x[2]^2 + x[3]^2 + 1)))*0.1
    p′ = x[4] + (0.25*(u[1] + x[5]*x[6]))*0.1
    q′ = x[5] + (0.5*(u[2] - 3*x[4]*x[6]))*0.1
    r′ = x[6] + (u[3] + 2*x[4]*x[5])*0.1
    return [ψ₁′, ψ₂′, ψ₃′, p′, q′, r′]
end

function next_state(ψ₁,ψ₂,ψ₃,p,q,r,u1,u2,u3;dt = 0.1)
    """
    Attitude control benchmark. ψ₁,ψ₂,ψ₃ are angular velocities, and p,q,r are rodrigues parameters. u1,u2,u3 are control inputs.

    New map x[1] = ψ₁, x[2] = ψ₂, x[3] = ψ₃, x[4] = p, x[5] = q, x[6] = r
    """
    ψ₁′  = ψ₁ + (0.5*(q*(ψ₁^2 + ψ₂^2 + ψ₃^2 - ψ₃) + r*(ψ₁^2 + ψ₂^2 + ψ₂ + ψ₃^2) + p*(ψ₁^2 + ψ₂^2 + ψ₃^2 + 1)))*dt
    ψ₂′  = ψ₂ + (0.5*(p*(ψ₁^2 + ψ₂^2 + ψ₃^2 + ψ₃) + r*(ψ₁^2 -ψ₁ + ψ₂^2 + ψ₃^2) + q*(ψ₁^2 + ψ₂^2 + ψ₃^2 + 1)))*dt
    ψ₃′ = ψ₃ + (0.5*(p*(ψ₁^2 + ψ₂^2 - ψ₂ + ψ₃^2) + q*(ψ₁^2 + ψ₁ + ψ₂^2 + ψ₃^2) + r*(ψ₁^2 + ψ₂^2 + ψ₃^2 + 1)))*dt
    p′ = p + (0.25*(u1 + q*r))*dt
    q′ = q + (0.5*(u2 - 3*p*r))*dt
    r′ = r + (u3 + 2*p*q)*dt
    return ψ₁′, ψ₂′, ψ₃′, p′, q′, r′
end

function next_state_vectorized(samples, controls; dt = 0.1)
    println("Size of samples: ", size(samples))
    println("Size of controls: ", size(controls))
    ψ₁s = samples[1, :]
    ψ₂s = samples[2, :]
    ψ₃s = samples[3, :]
    ps = samples[4, :]
    qs = samples[5, :]
    rs = samples[6, :]
    u1s = controls[1, :]
    u2s = controls[2, :]
    u3s = controls[3, :]

    ψ₁_news = ψ₁s .+ (0.5.*(qs .*(ψ₁s.^2 .+ ψ₂s.^2 .+ ψ₃s.^2 .- ψ₃s) .+ rs .*(ψ₁s.^2 .+ ψ₂s.^2 .+ ψ₂s .+ ψ₃s.^2) .+ ps .*(ψ₁s.^2 .+ ψ₂s.^2 .+ ψ₃s.^2 .+ 1))).*dt
    ψ₂_news = ψ₂s .+ (0.5.*(ps .*(ψ₁s.^2 .+ ψ₂s.^2 .+ ψ₃s.^2 .+ ψ₃s) .+ rs .*(ψ₁s.^2 .-ψ₁s .+ ψ₂s.^2 .+ ψ₃s.^2) .+ qs .*(ψ₁s.^2 .+ ψ₂s.^2 .+ ψ₃s.^2 .+ 1))).*dt
    ψ₃_news = ψ₃s .+ (0.5.*(ps .*(ψ₁s.^2 .+ ψ₂s.^2 .- ψ₂s .+ ψ₃s.^2) .+ qs .*(ψ₁s.^2 .+ ψ₁s .+ ψ₂s.^2 .+ ψ₃s.^2) .+ rs .*(ψ₁s.^2 .+ ψ₂s.^2 .+ ψ₃s.^2 .+ 1))).*dt
    p_news = ps .+ (0.25.*(u1s .+ qs.*rs)).*dt
    q_news = qs .+ (0.5.*(u2s .- 3*ps.*rs)).*dt
    r_news = rs .+ (u3s .+ 2*ps.*qs).*dt

    return ψ₁_news, ψ₂_news, ψ₃_news, p_news, q_news, r_news
end

att_ps1 = :(0.5*(q*(ψ₁^2 + ψ₂^2 + ψ₃^2 - ψ₃) + r*(ψ₁^2 + ψ₂^2 + ψ₂ + ψ₃^2) + p*(ψ₁^2 + ψ₂^2 + ψ₃^2 + 1)))
att_ps2 = :(0.5*(p*(ψ₁^2 + ψ₂^2 + ψ₃^2 + ψ₃) + r*(ψ₁^2 -ψ₁ + ψ₂^2 + ψ₃^2) + q*(ψ₁^2 + ψ₂^2 + ψ₃^2 + 1)))
att_ps3 = :(0.5*(p*(ψ₁^2 + ψ₂^2 - ψ₂ + ψ₃^2) + q*(ψ₁^2 + ψ₁ + ψ₂^2 + ψ₃^2) + r*(ψ₁^2 + ψ₂^2 + ψ₃^2 + 1)))
att_p = :(0.25*(u1 + q*r))
att_q = :(0.5*(u2 - 3*p*r))
att_r = :(u3 + 2*p*q)

att_dynamics_overt = get_overt_dynamics([att_ps1, att_ps2, att_ps3, att_p, att_q, att_r], [:ψ₁, :ψ₂, :ψ₃, :p, :q, :r, :u1, :u2, :u3], 1e-4)

att_dynamics_inputs = [:ψ₁, :ψ₂, :ψ₃, :p, :q, :r]
att_dynamics_controls = [:u1, :u2, :u3]

function att_update_rule(input_vars, control_vars, overt_output_vars)
    integration_map = Dict(input_vars[1] =>  overt_output_vars[1],
                           input_vars[2] => overt_output_vars[2],
                           input_vars[3] => overt_output_vars[3],
                           input_vars[4] => overt_output_vars[4],
                           input_vars[5] => overt_output_vars[5],
                           input_vars[6] => overt_output_vars[6]
                        )
    return integration_map
end

Attitude = OvertProblem(
    att_dynamics,
    att_dynamics_overt,
    att_update_rule,
    att_dynamics_inputs,
    att_dynamics_controls
)