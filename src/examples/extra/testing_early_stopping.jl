using Gurobi
include("../../dependencies.jl")
using LazySets
# using Dates 
# using JLD2
using Plots
plotly()
using JuMP
OPTIMAL = JuMP.MathOptInterface.OPTIMAL
TIME_LIMIT = JuMP.MathOptInterface.TIME_LIMIT
MOI = JuMP.MathOptInterface

# The goal of this sandbox script is to test early stopping techiques.
# This means stop before the optimization problem is fully solved and report the solution
# I think I could probably test giving different lengths of time and plotting the optimum until fully solved to see how close/far the bound gets as I give more time. 

# Another thing I want to test is stopping solve when the bound is below/above a threshold that I pass. I think that can be done with a callback. 

function solve_model_with_timeout(timeout; verbose=false)
    threads=0
    model = Model(optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag" => 0, "Threads" => threads))  

    network_nnet_address = "../../../nnet_files/jmlr/tora_big_controller.nnet"
    input_set = Hyperrectangle(low=[0.6, -0.7, -0.4, 0.5], high=[0.7, -0.6, -0.3, 0.6])
    input_vars = @variable(model, inputs[1:4])
    output_var = @variable(model, output)

    # this just adds a neural network
    add_controller_constraints(model, network_nnet_address, input_set, input_vars, output_var; last_layer_activation=Id())

    set_time_limit_sec(model, timeout)
    @objective(model, Max, output_var)
    JuMP.optimize!(model)

    # goal find min and max of output node 
    # after: retrieve bound (maybe gap too?)
    if termination_status(model) == OPTIMAL
        println("Solution is optimal")
        println("  objective value = ", objective_value(model))
        println("  objective bound is= ", objective_bound(model))
        println(" relative gap is: ", relative_gap(model))
        return objective_value(model), objective_bound(model), termination_status(model)
    elseif termination_status(model) == TIME_LIMIT && has_values(model)
        println("Solution is suboptimal due to a time limit, but a primal solution is available")
        println("  objective value = ", objective_value(model))
        println("  objective bound is= ", objective_bound(model))
        println(" relative gap is: ", relative_gap(model))
        return objective_value(model), objective_bound(model), termination_status(model)
    else
        println("model ", has_values(model) ? "has values" : "does not have values.")
        println("termination status is: ", termination_status(model))
        println("primal status is: ", primal_status(model))
        return 0., 0., termination_status(model)
    end
    

    
end
# what is primal_status(model)
# solution_summary(model, verbose=true)

function plot_obj_vs_timeout()
    obj_vals = []
    obj_bnds = []
    term_stat = []
    times = 10 .^ (range(-2,stop=0,length=20))
    for t in times 
        ov, ob, ts = solve_model_with_timeout(t; verbose=true)
        push!(obj_vals, ov)
        push!(obj_bnds, ob)
        push!(term_stat, ts)
    end
    label_colors = [ts == OPTIMAL ? :green : (ts == TIME_LIMIT ? :blue : :red) for ts in term_stat ]
    plot(times, obj_bnds, seriestype=:scatter, label="objective bound (upper)")
    plot!(times, obj_vals, seriestype=:scatter,label="objective value (max)", xlabel="timeout", ylabel="value", color = label_colors)
end

# okay! So it can be done. 
# set_optimizer_attribute(model, "BestBdStop", val) "Terminates as soon as the engine determines that the best bound on the objective value is at least as good as the specified value."
# 
function solve_model_with_threshold()
    threads=0
    model = Model(optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag" => 0, "Threads" => threads))  

    network_nnet_address = "../../../nnet_files/jmlr/tora_big_controller.nnet"
    input_set = Hyperrectangle(low=[0.6, -0.7, -0.4, 0.5], high=[0.7, -0.6, -0.3, 0.6])
    input_vars = @variable(model, inputs[1:4])
    output_var = @variable(model, output)

    # this just adds a neural network
    add_controller_constraints(model, network_nnet_address, input_set, input_vars, output_var; last_layer_activation=Id())

    # # sample bound
    # using Flux
    # flux_net = Flux.Chain(read_nnet(network_nnet_address))
    # samps = sample(input_set, 10000)
    # Ys = flux_net(hcat(samps...))
    # samp_max = maximum(Ys)
    # println("sampled max is: ", samp_max)
    # # sample bound is not very good. 

    # add threshold to stop based on primal value being at least this good 
    # didn't really notice a difference bc problem is so small 
    set_optimizer_attribute(model, "BestObjStop", -0.5)

    @objective(model, Max, output_var)
    JuMP.optimize!(model)
    println("objective_value(model): ", objective_value(model))
end

# terminate using callback on MIPGap parameter from Gurobi 
function solve_model_with_callback()
    threads=0
    model = Model(optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag" => 0, "Threads" => threads))  

    network_nnet_address = "../../../nnet_files/jmlr/tora_big_controller.nnet"
    input_set = Hyperrectangle(low=[0.6, -0.7, -0.4, 0.5], high=[0.7, -0.6, -0.3, 0.6])
    input_vars = @variable(model, inputs[1:4])
    output_var = @variable(model, output)

    # this just adds a neural network
    add_controller_constraints(model, network_nnet_address, input_set, input_vars, output_var; last_layer_activation=Id())

    # callback function to terminate based on MIPGap 
    function MIPgapcallback(cb_data, code)
        println("code is: ", code)
        # calculate MIPgap 
        # println("objective value is: ", callback_value(cb_data, output_var))
        # println("mipgap is: ", mipgap)
    end
    MOI.set(model, Gurobi.CallbackFunction(), MIPgapcallback)
    """
    Nevermind, seems terribly complicated to use a callback. there is some documentation here
    https://github.com/jump-dev/Gurobi.jl#callbacks
    and here 
    https://discourse.julialang.org/t/ann-upcoming-breaking-changes-to-cplex-jl-and-gurobi-jl/47814
    about how to query model values like objective and dual/bound in a callback. and then terminate if it's within some tolerance, but honestly seems like way more work than it's worth. 
    Better to just set MIPGap to be loose/large and know that it won't be optimal even if it says so. 
    """

    @objective(model, Max, output_var)
    JuMP.optimize!(model)
    println("objective_value(model): ", objective_value(model))
end

function solve_model_with_MIPGap()
    threads=0
    model = Model(optimizer_with_attributes(Gurobi.Optimizer, "OutputFlag" => 1, "Threads" => threads))  

    network_nnet_address = "../../../nnet_files/jmlr/tora_big_controller.nnet"
    input_set = Hyperrectangle(low=[0.6, -0.7, -0.4, 0.5], high=[0.7, -0.6, -0.3, 0.6])
    input_vars = @variable(model, inputs[1:4])
    output_var = @variable(model, output)

    # this just adds a neural network
    add_controller_constraints(model, network_nnet_address, input_set, input_vars, output_var; last_layer_activation=Id())

    # add threshold to stop based on MIPGap being at least this small 
    # didn't really notice a difference bc problem is so small 
    set_optimizer_attribute(model, "MIPGap", 0.5)

    @objective(model, Max, output_var)
    JuMP.optimize!(model)
    println("objective_value(model): ", objective_value(model))
    println("relative gap is: ", relative_gap(model)*100, " %")
    println("termination status is: ", termination_status(model))
end

# then: integrate into other software!
