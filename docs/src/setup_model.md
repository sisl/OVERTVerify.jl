## Setup model
Your model can be specified in `my_model.jl` file, preferably located in `examples/models/my_model` folder. The file may include three functions:
- `1) my_model_dynamics(x, u)`: where `x` is the vector of system variables and `u` is the vector of control variables. This function returns a vector `dx` which specifies how the derivative of system variables are computed. For example, for a single pendulum system, the continuous-time system is:

<img src="https://render.githubusercontent.com/render/math?math=\dot{x}_1 = x_2">

<img src="https://render.githubusercontent.com/render/math?math=\dot{x}_2 = \frac{g}{l} \sin(x_1)"> +
<img src="https://render.githubusercontent.com/render/math?math=\frac{u_1 - c x_2}{ml^2}">

where
<img src="https://render.githubusercontent.com/render/math?math=g, l, m">  and
<img src="https://render.githubusercontent.com/render/math?math=c"> are model parameters: gravitational acceleration, pendulum length, pendulum mass and viscous drag coefficient). For the single pendulum model, `single_pend_dynamics(x, y)` looks like this:

```julia
function single_pend_dynamics(x, u)
    m, l, g, c = 0.5, 0.5, 1., 0.
    dx1 = x[2]
    dx2 = g/l * sin(x[1]) + 1 / (m*l^2) * (u[1] - c * x[2])
    return [dx1, dx2]
end
```

- `2) my_model_dynamics_overt(range_dict, N_overt; t_idx)`: This function generates an relational overapproximation of the original model. `range_dict` indicates the range of system variables as a dictionary and `N_overt` is the number of linear segments per region of uniform convexity, the parameter that the OVERT library takes. Passing `N_overt=-1` lets OVERT choose this parameter efficiently.
In order to verify a desired property of the closed-loop system over
a number of timesteps, OVERT keeps a symbolic expression of the model over time. This allows OVERTVerify to be significantly less conservative; see [here](link to paper) for more details. To allow this to happen, we need to assign a secondary subscript to the system variables to keep track of the time step. parameter `t_idx` is that extra subscript. The default value `t_idx=nothing` means no symbolic representation is kept over time. The output of this function is a tuple of `(v_oA, [v_oA.output])` where `v_oA` is the `OverApproximation` object that includes overapproximation of nonlinear part of your model. For example, for the single pendulum model, the function looks like this:
```julia
function single_pend_dynamics_overt(range_dict, N_OVERT; t_idx=nothing)
    m, l, g, c = 0.5, 0.5, 1., 0.
    if isnothing(t_idx)
        v1 = :($(g/l) * sin(x1) + $(1/(m*l^2)) * u - $(c/(m*l^2)) * x2)
    else
        v1 = "$(g/l) * sin(x1_$t_idx) + $(1/(m*l^2)) * u_$t_idx - $(c/(m*l^2)) * x2_$t_idx"
        v1 = Meta.parse(v1) # turns into Expr type
    end
    v1_oA = overapprox_nd(v1, range_dict; N=N_OVERT)
    return v1_oA, [v1_oA.output]
end
```
Notice how `t_idx` is used as an extra subscript for system and control variables. While the single pendulum problem has only one nonlinear relation, more complicated models may include multiple such equations. To combine all over-approximation objects, use `add_overapproximate`:
```
combined_v_oA = add_overapproximate([v1_oA, v2_oA])
```
see other models in `example\models` folder for your reference.

- `3) my_model_update_rule(input_vars, control_vars, overt_output_vars)`: this function determines how the over-approximated model will be constructed. The output is a dictionary that indicates how the time-discrete integration of each state variable is computed.
For example, for the single pendulum model, the function looks like this:
```julia
function single_pend_update_rule(input_vars, control_vars, overt_output_vars)
    ddth = overt_output_vars[1]
    integration_map = Dict(input_vars[1] => input_vars[2], input_vars[2] => ddth)
    return integration_map
end
```

In addition to these three functions, you need to define the state and control variable symbols, and eventually define the problem as an `OvertProblem`. For the case of single pendulum problem, we have:
```julia
single_pend_input_vars = [:x1, :x2]
single_pend_control_vars = [:u1]

SinglePendulum = OvertProblem(
    single_pend_dynamics,
    single_pend_dynamics_overt,
    single_pend_update_rule,
    single_pend_input_vars,
    single_pend_control_vars
)
```

### Measurement Models
An `OvertProblem` may also contain a measurement model. For example for the acc problem, the following measurement model is used:
```julia
acc_measurement_model = [[1, 0, 0, -1, -T_gap, 0]::Array{Float64}] # relative distance  - v_ego*Tgap 
```
A measurement model can contain multiple rows of measurements instead of just one.

### Note that won't apply to most users: 

If your model specifies $\textbf{x}_{t+1} = f(\textbf{x}_t, \textbf{u}_t)$ directly, without forward Euler integration and is incomptable with re-arrangement to that form, you can set the timestep $dt=1$ and re-arrange your difference equation to be of the form $\textbf{x}_{t+1} = \textbf{x}_t + g(\textbf{x}_t, \textbf{u}_t)\times 1$ where  $g(\textbf{x}_t, \textbf{u}_t) = f(\textbf{x}_t, \textbf{u}_t) - \textbf{x}_t$ is the function specified by  `my_model_dynamics(x, u)`. Be mindful that the timestep used for any Monte Carlo simulation comparison matches the timestep used in `my_model_dynamics`. 
