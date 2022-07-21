"""
Single Inverted Pendulum
θₜ₊₁ = θₜ + dt*θdotₜ
θdotₜ₊₁ = θdotₜ + dt((g/l)sinθₜ + (1/ml²)uₜ
"""
using LinearAlgebra
using ControlSystems
using Plots
using LazySets
using QHull
include("../../../../dependencies.jl")

# Construct OVERT problem with NN controller inside 
controller_type = "small" # pass from command line, e.g. "small"
controller = "../../../../../nnet_files/jmlr/single_pendulum_$(controller_type)_controller.nnet"
println("Controller: ", controller)
query = OvertQuery(
	SinglePendulum,    # problem
	controller,        # network file
	Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
	"MIP",             # query solver, "MIP" or "ReluPlex"
	100,                # ntime
	0.1,               # dt
	-1,                # N_overt
	)



# define starting set 
input_set = Hyperrectangle(low=[-pi, -1.], high=[pi, 1.])

# define LQR controller 
function LQR_single_pend(query; check_lqr=false)
    """
    Function to create LQR controller for single pendulum.
    Returns function to compute control given x
    """
    # Define linearized system (xt+1 = Axt + but) about point [θ, θdot] = [0, 0]
    query.dt = 0.1 
    m = pend_mass # defined in single_pend.jl in models
    l = pend_len
    g = grav_const
    A = [1 dt; 0 1]
    B = [0, dt / (m*l^2)]
    # check if controllable 
    @assert rank(ctrb(A,B)) == 2
    # measurement model, identity 
    C = I(2)
    D = [0,0]
    # state space model 
    sys = ss(A,B,C,D,dt)
    Q = I 
    R = I
    L = lqr(sys, Q, R) # infinite time gain, I think 
    get_control(x) = -L*x 
    if check_lqr
        # to check it is working 
        u(x,t) = -L*x 
        t = 0:dt:25*dt 
        x0 = [1, 0.]
        y, t, x, uout = lsim(sys, u, t, x0=x0)
        plot(t, x', lab=["θ" "θdot"], xlabel="Time [s]")
        # seems to work! 
    end
    return get_control
end
lqr_controller = LQR_single_pend(query)

# now do simulations with network and with lqr and compare
n_sim = 10000
nnet_sim_data = monte_carlo_simulate(query, input_set, n_sim=n_sim);
lqr_sim_data = monte_carlo_simulate(query, input_set, lqr_controller, n_sim=n_sim);

# concatenate initial points to simulation data 
nnet_pts = cat(extend_dims(nnet_sim_data[3], 2), nnet_sim_data[2], dims=2);
@assert nnet_pts[:,1,:] == nnet_sim_data[3] # first step is x0 data
lqr_pts = cat(extend_dims(lqr_sim_data[3], 2), lqr_sim_data[2], dims=2);

# sim data consists of state_sets, xvec sim points, x0, meas_sets, yvec, y0
# xvec is n_sim X nsteps X 2   (2 is state dim)
# plot! 
# plot in θ-θdot space first
scatter([0],[0], markersize=5, label="origin", xlabel="θ", ylabel="θdot", legend=:topleft)
for i=1:500
    plot!(nnet_pts[i,:,1], nnet_pts[i,:,2], color=:blue, label="")
    plot!(lqr_pts[i,:,1], lqr_pts[i,:,2], color=:purple, label="")
end
plot!(nnet_pts[end,:,1], nnet_pts[end,:,2], color=:blue, label="nnet")
plot!(lqr_pts[end,:,1], lqr_pts[end,:,2], color=:purple, label="lqr")

# plot the set of ending points in theta-thetadot space
plot(input_set, label="input set", xlabel="theta", ylabel="thetadot") 
border_idx_nnet = chull(nnet_pts[:,end,:]).vertices
x_nnet = nnet_pts[border_idx_nnet, end, 1]
y_nnet = nnet_pts[border_idx_nnet, end, 2]
plot!([x_nnet..., x_nnet[1]], [y_nnet..., y_nnet[1]], label="end set for nnet")
border_idx_lqr = chull(lqr_pts[:,end,:]).vertices
x_lqr = lqr_pts[border_idx_lqr, end, 1]
y_lqr = lqr_pts[border_idx_lqr, end, 2]
plot!([x_lqr..., x_lqr[1]], [y_lqr..., y_lqr[1]], label="end set for lqr")

# plot θ vs time 
scatter([0],[0], markersize=0, label="")
for i=1:100
    plot!(nnet_pts[i,:,1], color=:blue, label="")
    plot!(lqr_pts[i,:,1], color=:purple, label="")
end
plot!(nnet_pts[end,:,1], color=:blue, label="nnet")
plot!(lqr_pts[end,:,1], color=:purple, label="lqr", xlabel="t", ylabel="θ", legend=:topright)

# plot θdot vs time 
scatter([0],[0], markersize=0, label="")
for i=1:100
    plot!(nnet_pts[i,:,2], color=:blue, label="")
    plot!(lqr_pts[i,:,2], color=:purple, label="")
end
plot!(nnet_pts[end,:,2], color=:blue, label="nnet")
plot!(lqr_pts[end,:,2], color=:purple, label="lqr", xlabel="t", ylabel="θdot", legend=:topright)