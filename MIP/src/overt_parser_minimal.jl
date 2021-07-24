using OVERT: get_symbols, find_variables, substitute!

""" this function turns :(w == -(x+1)) to :(w == -1(x+1)) """
function fix_negation!(expr::Expr)
    if length(expr.args[3].args) == 2
        if expr.args[3].args[1] == :-
            arg = expr.args[3].args[2]
            expr.args[3].args = [:*, -1, arg]
        end
    end
    return expr
end

""" find if this expr constains max """
is_max_expr(expr::Union{Symbol, Expr}) = :max in get_symbols(expr)
is_min_expr(expr::Union{Symbol, Expr}) = :min in get_symbols(expr)

"given expr = :(2x+3y-3z+1) return [:x, :y, :c], [2, 3, -3], 1"
get_linear_coeffs(expr::Symbol) = [expr], [1.0], 0
function get_linear_coeffs(expr::Expr)
    vars = find_variables(expr)
    coeffs = zeros(length(vars))
    scalar = deepcopy(expr)
    for v in vars
        substitute!(scalar, v, 0)
    end
    scalar = eval(scalar)


    for i = 1:length(vars)
        expr_copy = deepcopy(:($expr - $scalar))
        for v in vars
            if vars[i] == v
                substitute!(expr_copy, v, 1)
            else
                substitute!(expr_copy, v, 0)
            end
        end
        coeffs[i] = eval(:($expr_copy))
    end
    return vars, coeffs, scalar
end