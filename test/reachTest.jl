using Gurobi
using OVERTVerify
using LazySets
using Dates

controller_type = "small" # ARGS[1] # pass from command line, e.g. "small"
controller = "nnet_files/jmlr/single_pendulum_$(controller_type)_controller.nnet" #Expects a NN controller. What do we do with it? 

#Reference problems.jl OVertQuery struct. Takes an OVERT problem, a nnet file, a last layer activation, a solver, a time horizon, a time step size, and a number of approximation sampling points.
query = OvertQuery(
    SinglePendulum,    # problem
    controller,        # network file
    Id(),              # last layer activation layer Id()=linear, or ReLU()=relu
    "MIP",             # query solver, "MIP" or "ReluPlex"
    25,                # ntime
    0.1,               # dt
    2,                # N_overt
    )


#The query references SinglePendulum. Breakdown
#SinglePendulum is an OvertProblem
#The OvertProblem holds:
    #System dynamics in dx1 = ..., dx2 = ... format 
    #An overapproximation of this function
    #An update rule desribing how the variables of the system are updated between time steps 
    #An explicit list of input variables
    #An explicit list of control variables

input = Hyperrectangle(low=[1., 0.], high=[1.2, 0.2]) #Initial set of states
concretization_intervals = Int.(ones(query.ntime)) #Concretize every second.
t1 = Dates.time()

#This is where we call the symbolic reachibility + concretization function. Breakdown
#Takes: 
    #An OvertQuery
    #An initial set of states
    #A list of concretization intervals

ntime = query.ntime

all_concrete_sets = []
all_symbolic_sets = []
all_concrete_meas_sets = []
all_symbolic_meas_sets = []
this_set = copy(input)

##For each interval in concretization_intervals, call symbolic_reachability, then push results to a list
#In symbolic_reachability, we basically construct a MIP for the dynamics, then add control constraints, then solve (after some preprocessing)

#To construct a MIP, we first setup_mip_with_overt_constraints
    #in this step, we compute the reachable sets using concretization
    #Then we combine all the overapproximation objects into a single oA
    #Then we construct the MIP
    #Strangely, in this step, we already compute concrete reach sets over the entire time horizon.

    #In setup_mip_with_overt_constraints, we call many_timestep_concretization, which loops through timesteps in ntime, and computes one_timestep_concretization
        #In one_timestep_concretization, we set up yet another MIP? and solve for reachability (for a single timestep)
            #In one_timestep_concretization, we setup_mip_with_overt_constraints, then solve_for_reachability

            #setup_mip_with_overt_constraints seems to be the preprocessing step. We bound the controller, and add these values to the range_dict. We then overapproximate the dynamics, and convert the overapproximation to a JuMP model. Finally, we add a the controller to this model, and solve_for_reachability

            #In solve_for_reachability, we basically solve an optimization problem to obtain interval bounds (min and max), and define this hyperrectangle as the reachable set.
        #We return a hyperrectangle, which is the reachable set for a single timestep
    #We return a list of hyperrectangles, which is the reachable set for the entire time horizon
#We ignore the hyperrectangles for now, and combine the list of overapproximations into a single oA, then we convert that into yet another MIP 

#We combine the MIP with controller constraints, match inputs to outputs, then solve for reachability (with the added constraint that outputs need to match inputs between timesteps)