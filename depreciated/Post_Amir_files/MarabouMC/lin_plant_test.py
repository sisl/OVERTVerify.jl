## Testing a linear plant model in the model checker

import numpy as np
from MC_constraints import Constraint, ConstraintType, Monomial, ReluConstraint
from transition_systems import TransitionRelation, TransitionSystem
from properties import ConstraintProperty
from MC_interface import BMC
from marabou_interface import MarabouWrapper
import colored_traceback.always

# States
tr = TransitionRelation()
tr.states = ["x", "y"]
tr.next_states = [s+"'" for s in tr.states]

# Constraints
# x' = relu(x + y)   ->   x + y - z = 0 , x' = relu(z)
c1 = Constraint(ConstraintType('EQUALITY'))
c1.monomials = [Monomial(1, "x"), Monomial(1,"y"), Monomial(-1,"z")]
c3 = ReluConstraint(varin="z", varout="x'")
# y' = y  ->  y - y' = 0
c2 = Constraint(ConstraintType('EQUALITY'))
c2.monomials = [Monomial(1,"y"), Monomial(-1, "y'")]
tr.constraints = [c1,c2,c3] 

# initial set
init_set = {"x": (1.1,2), "y": (-1,1)}

# build the transition system as an (S, I(S), TR) tuple
ts = TransitionSystem(states=tr.states, initial_set=init_set, transition_relation=tr)

# solver
solver = MarabouWrapper()

# property
p = Constraint(ConstraintType('GREATER'))
# x > c (complement will be x <= c)
p.monomials = [Monomial(1, "x")]
p.scalar = -1. # 0 #
prop = ConstraintProperty([p])

# algo
algo = BMC(ts = ts, prop = prop, solver=solver)
algo.check_invariant_until(3)




