using OVERT
using OVERTVerify
include("../src/overt_parser_minimal.jl")
include("../src/overt_to_mip.jl")
 
@testset "overt_2_mip_test1" begin
    oA_test = OverApproximation()
    oA_test.approx_eq = [:(x1 == 1-x), :(x2 == 2.0*max(0, x) + 3.0*max(0, x1))]
    oA_test.ranges = Dict(:x => [-1., 2.], :x1 => [-1., 2.], :x2 => [2., 6.])
    overt_mip_model = OvertMIP(oA_test)
    JuMP.optimize!(overt_mip_model.model)
    for (x, x_var) in pairs(overt_mip_model.vars_dict)
       l, u = oA_test.ranges[x]
       @test l <= value(x_var)
       @test u >= value(x_var)
    end

    @objective(overt_mip_model.model, Min, overt_mip_model.vars_dict[:x2])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ 2.

    @objective(overt_mip_model.model, Max, overt_mip_model.vars_dict[:x2])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ 6.

    @objective(overt_mip_model.model, Min, overt_mip_model.vars_dict[:x2] - overt_mip_model.vars_dict[:x])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ 1.

    @objective(overt_mip_model.model, Max, overt_mip_model.vars_dict[:x2] - overt_mip_model.vars_dict[:x])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ 7.
end

@testset "overt_2_mip_test2" begin
    oA_test = OverApproximation()
    oA_test.approx_eq = [:(x1 == 1-x), :(x2 == 1.0*max(0, min(x,x1)) + 1.0*max(0, min(x,x1)))]
    oA_test.ranges = Dict(:x => [-1., 2.], :x1 => [-1., 2.], :x2 => [0., 0.5])
    overt_mip_model = OvertMIP(oA_test)
    JuMP.optimize!(overt_mip_model.model)
    for (x, x_var) in pairs(overt_mip_model.vars_dict)
       l, u = oA_test.ranges[x]
       @test l <= value(x_var)
       @test u >= value(x_var)
    end

    @objective(overt_mip_model.model, Min, overt_mip_model.vars_dict[:x2])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ 0.

    @objective(overt_mip_model.model, Max, overt_mip_model.vars_dict[:x2])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ 0.5

    @objective(overt_mip_model.model, Min, overt_mip_model.vars_dict[:x2] - overt_mip_model.vars_dict[:x])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ -2.

    @objective(overt_mip_model.model, Max, overt_mip_model.vars_dict[:x2] - overt_mip_model.vars_dict[:x])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ 1.
end

@testset "overt_2_mip_test3" begin
    oA_test = OverApproximation()
    oA_test.approx_eq = [:(x1 == 2x), :(x2 == 1-x), :(x3 == 2.0*max(0, x1) + 1.0*max(0, x2) + -3.0*max(0, min(x1,x2)))]
    oA_test.ranges = Dict(:x => [-1., 2.], :x1 => [-2., 4.], :x2 => [-1., 2.], :x3 => [0., 8.])
    overt_mip_model = OvertMIP(oA_test)
    JuMP.optimize!(overt_mip_model.model)
    for (x, x_var) in pairs(overt_mip_model.vars_dict)
       l, u = oA_test.ranges[x]
       @test l <= value(x_var)
       @test u >= value(x_var)
    end

    @objective(overt_mip_model.model, Min, overt_mip_model.vars_dict[:x3])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ 0.


    @objective(overt_mip_model.model, Max, overt_mip_model.vars_dict[:x3])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈  8.

    @objective(overt_mip_model.model, Min, overt_mip_model.vars_dict[:x3] - overt_mip_model.vars_dict[:x])
    JuMP.optimize!(overt_mip_model.model)
    @test 3.0*objective_value(overt_mip_model.model) ≈ -1.

    @objective(overt_mip_model.model, Max, overt_mip_model.vars_dict[:x3] - overt_mip_model.vars_dict[:x])
    JuMP.optimize!(overt_mip_model.model)
    @test objective_value(overt_mip_model.model) ≈ 6.
end
