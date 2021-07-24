
import os
import sys
sys.path.insert(0, "..")
sys.path.insert(0, "/home/amaleki/Downloads/Marabou/")
print(sys.path)

import numpy as np
from keras.models import load_model
from overt_to_python import OvertConstraint
from transition_systems import KerasController, Dynamics, TFControlledTransitionRelation, TransitionSystem
from MC_constraints import Constraint, ConstraintType, ReluConstraint, Monomial
from marabou_interface import MarabouWrapper
from properties import ConstraintProperty
from MC_interface import BMC
from IterativeReachability import ReachabilityIterator
#from MC_simulate import simulate_double_pend

# This is trained controller with lqr data.
model = load_model("../OverApprox/models/double_pend_nn_controller_lqr_data.h5")
# This a untrained controller
# model = load_model("../OverApprox/models/double_pend_controller_nn_not_trained.h5")
# super simple controller
# model = load_model("/home/amaleki/Downloads/test_6_linear.h5")
controller = KerasController(keras_model=model)

# create overt dynamics objects
overt_obj_1 = OvertConstraint("../OverApprox/models/double_pend_acceleration_1_overt.h5")
overt_obj_2 = OvertConstraint("../OverApprox/models/double_pend_acceleration_2_overt.h5", var_dict=overt_obj_1.var_dict)

# sanity checks
assert(len(overt_obj_1.state_vars) == len(overt_obj_2.state_vars))
assert(len(overt_obj_1.control_vars) == len(overt_obj_2.control_vars))
for s in overt_obj_1.state_vars:
    assert(s in overt_obj_2.state_vars)
for c in overt_obj_1.control_vars:
    assert(c in overt_obj_2.control_vars)

# setup states, control and dynamics variables.
states = overt_obj_1.state_vars
theta1 = states[0]
theta2 = states[1]
theta1d = states[2]
theta2d = states[3]


controls = overt_obj_1.control_vars
acceleration_1 = overt_obj_1.output_vars[0]
acceleration_2 = overt_obj_2.output_vars[0]

double_pendulum_dynamics = Dynamics(np.array(states).reshape(-1, 1), np.array(controls).reshape(-1, 1))
next_states = double_pendulum_dynamics.next_states.reshape(4,)

print(states, controls, acceleration_1, acceleration_2, next_states)

dt = 0.01

# x1_next = x1 + dt*u1
c1 = Constraint(ConstraintType('EQUALITY'))
c1.monomials = [Monomial(1, theta1), Monomial(dt, theta1d), Monomial(-1, next_states[0])]
print(c1.monomials)


# x2_next = x2 + dt*u2
c2 = Constraint(ConstraintType('EQUALITY'))
c2.monomials = [Monomial(1, theta2), Monomial(dt, theta2d), Monomial(-1, next_states[1])]
print(c2.monomials)

# u1_next = u1 + dt*a1
c3 = Constraint(ConstraintType('EQUALITY'))
c3.monomials = [Monomial(1, theta1d), Monomial(dt, acceleration_1), Monomial(-1, next_states[2])]
print(c3.monomials)

# u2_next = u2 + dt*a2
c4 = Constraint(ConstraintType('EQUALITY'))
c4.monomials = [Monomial(1, theta2d), Monomial(dt, acceleration_2), Monomial(-1, next_states[3])]
print(c4.monomials)

dynamics_constraints = [c1, c2, c3, c4]
dynamics_constraints += overt_obj_1.constraints
dynamics_constraints += overt_obj_2.constraints
double_pendulum_dynamics.constraints = dynamics_constraints


###################################
init_set = {theta1: (-0.1, 0.1), theta2: (-0.1, 0.1), theta1d: (-0.1, 0.1), theta2d: (-0.1, 0.1)}
ri = ReachabilityIterator(model, double_pendulum_dynamics, init_set, alpha=1.5, cap_values=[[-1., -1.],[1., 1.]])
ri.run(6)
for h in ri.init_history:
    print(h)

##########################################
print(dsdsfd)


# create transition relation using controller and dynamics
tr = TFControlledTransitionRelation(dynamics_obj=double_pendulum_dynamics,
                                        controller_obj=controller)

# initial set
init_set = {theta1: (0.1, 0.6), theta2: (0.5, 0.6), theta1d: (-0.5, 0.5), theta2d: (-0.5, 0.5)}

# build the transition system as an (S, I(S), TR) tuple
ts = TransitionSystem(states=tr.states, initial_set=init_set, transition_relation=tr)

print(len([c for c in double_pendulum_dynamics.constraints if isinstance(c, ReluConstraint)]))
print(len([c for c in controller.constraints if isinstance(c, ReluConstraint)]))

# solver
solver = MarabouWrapper()

def constraint_variable_to_interval(variable, LB, UB):
    p1 = Constraint(ConstraintType('GREATER'))
    p1.monomials = [Monomial(1, variable)]
    p1.scalar = LB # 0 #
    #
    p2 = Constraint(ConstraintType('LESS'))
    p2.monomials = [Monomial(1, variable)]
    p2.scalar = UB
    return [p1, p2]


# property th1 < some_number
prop_list = []
prop_list += constraint_variable_to_interval(theta1, .2, .8)
prop_list+=constraint_variable_to_interval(theta2, .2, .8)
prop_list+=constraint_variable_to_interval(theta1d, -.6, .6)
prop_list+=constraint_variable_to_interval(theta2d, -.6, .6)

prop = ConstraintProperty(prop_list)

# algo
ncheck_invariant = 2
algo = BMC(ts=ts, prop=prop, solver=solver)
result = algo.check_invariant_until(ncheck_invariant)

# random runs to give intuition to MC result
# n_simulation = 10000
# print("Now running %d simulations: " %n_simulation, end="")
# simulate_double_pend(prop, n_simulation, ncheck_invariant, model, dt, init_set, states)
