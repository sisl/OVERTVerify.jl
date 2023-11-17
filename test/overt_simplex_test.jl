#Core Libraries
using OVERT
# using OVERTVerify
using Test
using Polyhedra
using CDDLib
using Gurobi
#using GLMakie
#using Makie

include("../src/overt_parser_minimal.jl")
include("../src/overt_to_mip.jl")

#Use Gurobi Solver
set_default_model("gurobi")
DEFAULT_MODEL

# #Define OverApproximation object
# oATest1 = OverApproximation()

# #Add equations
# oATest1.approx_eq = [:(x1 == 1-x), :(x2 == 2.0*max(0,x) + 3.0*max(0,x1))]
# oATest1.ranges = Dict(:x => [-1., 2.], :x1 => [-1., 2.], :x2 => [2., 6.])

# #Define MIP form of dynamics
# oATest1Mip = OvertMIP(oATest1)

# #Solve the MIP First 
# JuMP.optimize!(oATest1Mip.model)
# value(oATest1Mip.vars_dict[:x])

# #Polyhedral representation for MIP does not work, get convex relaxation
# undo = relax_integrality(oATest1Mip.model)
# #Polyhedral prepresentation 
# oApoly = polyhedron(oATest1Mip.model, CDDLib.Library(:exact))

# #Visualization libraries 


# #Reduce dimensionality
# redOAPoly = project(oApoly, 1:3, BlockElimination())

# #Convert n-d object to mesh 
# meshoAPoly = Polyhedra.Mesh(redOAPoly)
# Makie.mesh(meshoAPoly, color=:blue)


#Dynamics from Siefert Et al
# (uₖ == -17.60*x₁ₖ + -5.61*x₂ₖ)
# :(uₖ == max((-17.60*x₁ₖ + -5.61*x₂ₖ), -20)*(-17.60*x₁ₖ + -5.61*x₂ₖ < 20) + min((-17.60*x₁ₖ + -5.61*x₂ₖ), 20)*(-17.60*x₁ₖ + -5.61*x₂ₖ >= 20))


function simp_test()
    simpDyn = [:(sin(x₁))]
    simpRag = Dict(:x₁ => [-4, 4])
    simpDyn_overt = OVERTVerify.get_overt_dynamics(simpDyn)
    simp_oA, simp_Vars = simpDyn_overt(simpRag, 1)
    simp_Vars
    simp_oA
    simpMip = OvertMIP(simp_oA)
    simpMip.model
end
# simp_test()

function simp_vis()
    undo = relax_integrality(simpMip.model)
    simpPoly = polyhedron(simpMip.model, CDDLib.Library(:exact))
    subSimp = project(simpPoly, (1:2), BlockElimination())
    simpMesh = Polyhedra.Mesh(subSimp)
    Makie.mesh(simpMesh, color=:blue)
end

function sief_test()
    siefDyn = [:(x₁ₖ + 0.1*x₂ₖ), :(sin(x₁ₖ) + x₂ₖ + 0.1*uₖ)]

    siefDyn_overt = OVERTVerify.get_overt_dynamics(siefDyn)
    siefRange = Dict(:x₂ₖ => [-8, 8], :x₁ₖ => [-4, 4], :uₖ => [-20, 20])
    sief_oA, sief_Vars = siefDyn_overt(siefRange, 1)
    sief_Vars
    sief_oA     

    siefMIP = OvertMIP(sief_oA)

    siefMIP.model

    undo2 = relax_integrality(siefMIP.model)

    siefPoly = polyhedron(siefMIP.model, CDDLib.Library(:exact))
end
#sief_test()

function sief_vis()
    #Extract specific dimensions
    sief_112 = project(siefPoly, (1:3), BlockElimination())
    siefMesh = Polyhedra.Mesh(sief_112)
    Makie.mesh(siefMesh, color=:blue)
end

# include("../../Expr2MIP.jl/src/parsing.jl")
function simp_test2()
    altModel = Model(Gurobi.Optimizer)
    EncodingParameters()
    simpDyn = [:(sin(x₁))]
    simpDyn[1]
    simpRag = Dict(:x₁ => [-4, 4])
    altMIP = breakdown_and_encode!(altModel, simpDyn[1], expr_map=simpRag)
end

# altModel = Model(Gurobi.Optimizer)
# simpDyn = [:(sin(x₁))]
# simpRag = Dict(:x₁ => [-4, 4])
# simpDyn_overt = OVERTVerify.get_overt_dynamics(simpDyn)
# simp_oA, simp_Vars = simpDyn_overt(simpRag, 1)

# define_state_variables!(altModel, simpRag)
# altModel
# for c in simp_oA.approx_eq
#     # constraints are of the form: v_1 == 5*v_6 - 12*v_9 - 7
#     LHS = c.args[2] # just a symbol
#     @assert typeof(LHS) == Symbol 
#     RHS = c.args[3] # an expr
#     con_ref, output_ref = add_constraint!(altModel, RHS, LHS; params=EncodingParameters(), expr_map=Dict())
# end


# for c in simp_oA.approx_ineq
#     # these constraints are of the form: v_1 <= v_3
#     @assert typeof(c.args[2]) == Symbol 
#     @assert typeof(c.args[3]) == Symbol
#     LHS = JuMP.variable_by_name(altModel, string(c.args[2]))
#     RHS = JuMP.variable_by_name(altModel, string(c.args[3]))
#     @constraint(altModel, LHS <= RHS)
# end

# c = simp_oA.approx_ineq[1]
# @assert typeof(c.args[2]) == Symbol 
# @assert typeof(c.args[3]) == Symbol
# c.args
# LHS = JuMP.variable_by_name(altModel, string(c.args[2]))
# RHS = JuMP.variable_by_name(altModel, string(c.args[3]))

include("../src/models/problems.jl")
simpDyn = [:(sin(x₁))]
simpRag = Dict(:x₁ => [-4, 4])
simpDyn_overt = get_overt_dynamics(simpDyn)
simpDyn2_overt = overapprox(simpDyn[1], simpRag; N=1,ϵ=0.0001)
fieldnames(simpDyn2_overt)
simp_oA, simp_Vars = simpDyn_overt(simpRag, 1)
simp_Vars
simp_oA
simpMip = OvertMIP(simp_oA)
simpMip.model