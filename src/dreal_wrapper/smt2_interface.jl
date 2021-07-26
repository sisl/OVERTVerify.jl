using Intervals
using IterTools: ncycle

global DEBUG = false

""" Types """

mutable struct FormulaStats
    bools # boolean vars. arraylike
    reals # real vars. arraylike
    bool_macros #arraylike
    new_bool_var_count::Int
    bool_macro_count::Int
end
FormulaStats() = FormulaStats([],[],[],0,0)

mutable struct SMTLibFormula
    formula # arraylike
    stats::FormulaStats
end
SMTLibFormula() = SMTLibFormula([], FormulaStats())

mutable struct MyError
    message::String
end

"""Printing/Writing Functions"""
function Base.show(io::IO, f::SMTLibFormula)
    s = "SMTLibFormula: "
    s *= "new_bool_var_count = " * string(f.stats.new_bool_var_count)
    s *= ", bools: " * string(f.stats.bools)
    s *= ", reals: " * string(f.stats.reals)
    println(io, s)
end

function write_to_file(f::SMTLibFormula, fname; dirname="sound/smtlibfiles/")
    # print expressions to file
    @debug println(join(f.formula, "\n"))

    # TODO: make dir before writing to file in it
    try
        mkdir(pwd() * "/" * dirname) # make dir if it doesn't exist
    catch
    end
    full_fname = pwd()* "/" * dirname * fname
    file = open(full_fname, "w")
    write(file, join(f.formula, "\n"))
    close(file)
    return full_fname
end

function write_result(fname, result; specifier="w")
    # results will be put in a txt  file of the same name but with "result" appended
    io = open(fname[1:end-5]*"_result.txt", specifier)
    write(io, result...)
    close(io)
    return nothing
end

function read_result(fname)
    # results will be put in a txt  file of the same name but with "result" appended
    io = open(fname[1:end-5]*"_result.txt", "r")
    result = read(io, String)
    close(io)
    return result
end

function define_domain(d, stats::FormulaStats)
    # d is a dictionary denoting the domain, e.g. {"x" => [-.3, 5.6], ...}
    assertions = []
    for (k,v) in d
        lb = v[1]
        ub = v[2]
        if k ∉ stats.reals
            add_real_var(k, stats)
        end
        box = assert_statement(define_box(string(k),lb, ub))
        push!(assertions, box)
    end
    return assertions
end

function handle_unary_negation(n::T where T <: Real)
    return n < 0 ? prefix_notate("-", [-n]) : string(n)
end
function handle_unary_negation(n::Symbol)
    return string(n)
end

function define_box(v::String, lb, ub)
    lb = handle_unary_negation(lb)
    ub = handle_unary_negation(ub)
    lb_e = prefix_notate("<=", [v, ub])
    ub_e = prefix_notate(">=", [v, lb])
    return prefix_notate("and", [lb_e, ub_e])
end

"""Low level functions for converting ϕ and ϕ̂ to smtlib2"""

"""
f is an array representing a conjunction.
Returns an array
"""
function assert_all(f::Array, fs::FormulaStats)
    assertions = []
    for item in f
        expr = convert_any_constraint(item, fs)::String
        push!(assertions, assert_statement(expr))
    end
    return assertions
end

function assert_conjunction(f::Array, fs::FormulaStats; conjunct_name=nothing)
    if length(f) == 1
        return [assert_literal(f[1], fs)]
    elseif length(f) > 1
        # assert conjunction
        return assert_actual_conjunction(f, fs; conjunct_name=conjunct_name)::Array
    else # empty list
        return []
    end
end

function assert_literal(l, fs::FormulaStats)
    return assert_statement(convert_any_constraint(l, fs::FormulaStats))
end

function assert_negated_literal(l, fs::FormulaStats)
    return assert_statement(negate(convert_any_constraint(l, fs::FormulaStats)))
end

function assert_negation_of_conjunction(f::Array, fs::FormulaStats; conjunct_name=nothing)
    if length(f) == 1
        return [assert_negated_literal(f[1], fs)]
    elseif length(f) >= 1
        return assert_actual_negation_of_conjunction(f, fs; conjunct_name=conjunct_name)::Array
    else # empty list
        return []
    end
end

function not(atom)
    return ~atom::Bool
end

function add_real_var(v, fs::FormulaStats)
    if not(v in fs.reals)
        push!(fs.reals, v)
    end
end

function add_real_vars(vlist::Array, fs::FormulaStats)
    for v in vlist
        add_real_var(v, fs)
    end
end

function get_new_bool(fs::FormulaStats)
    fs.new_bool_var_count += 1
    v = "b"*string(fs.new_bool_var_count) # b for boolean
    @assert not(v in fs.bools)
    push!(fs.bools, v)
    return v
end

"""
Creates prefix notation syntax of smtlib2.
Turn an op into its prefix form: (op arg1 arg2 ...).
A 'pure' style function that doesn't modify state. 
"""
function prefix_notate(op, args)
    expr = "(" * op * " "
    expr *= print_args(args)
    expr *= ")"
    return expr
end

function print_args(args::Array)
    s = ""
    for a in args
        s *= string(a) * " "
    end
    s = s[1:end-1] # chop trailing whitespace
    return s
end

function declare_const(constname, consttype)
    return prefix_notate("declare-const", [constname, consttype])
end

# e.g. (define-fun _def1 () Bool (<= x 2.0))
function define_fun(name, args, return_type, body)
    arg_string = "("*print_args(args)*")"
    return prefix_notate("define-fun", [name, arg_string, return_type, body])
end

function declare_reals(fs::FormulaStats)
    real_decls = []
    for v in fs.reals
        push!(real_decls, declare_const(v, "Real"))
    end
    return real_decls
end

function define_atom(atomname, atomvalue)
    eq_expr = prefix_notate("=", [atomname, atomvalue])
    return assert_statement(eq_expr)
end

function define_bool_macro(macro_name, expr)
    return define_macro(macro_name, expr; return_type="Bool")
end

# (define-fun _def1 () Bool (<= x 2.0))
function define_macro(macro_name, expr; return_type="Bool")
    return define_fun(macro_name, [], return_type, expr)
end

function assert_statement(expr)
    return prefix_notate("assert", [expr])
end

function negate(expr)
    return prefix_notate("not", [expr])
end

function footer()
    return ["(check-sat)", "(get-model)"]
end

function header()
    h = [produce_models(), set_logic()]
    # push!(h, define_max(), define_min(), define_relu()) # min and max already defined by dreal
    return h
end

function set_logic()
    return "(set-logic QF_NRA)"
end

function produce_models()
    return "(set-option :produce-models true)"
end

# define-fun is a macro.
# if x < y return y else x
function define_max()
    return "(define-fun max ((x Real) (y Real)) Real (ite (< x y) y x))"
end

# if x < y return x else y
function define_min()
    return "(define-fun min ((x Real) (y Real)) Real (ite (< x y) x y))"
end

function define_relu()
    return "(define-fun relu ((x Real)) Real (max x 0))"
end

function assert_actual_conjunction(constraint_list, fs::FormulaStats; conjunct_name=nothing)
    formula, conjunct_name = declare_conjunction(constraint_list, fs; conjunct_name=conjunct_name) # declare conjunction
    push!(formula, assert_statement(conjunct_name)) # assert conjunction
    return formula
end

function assert_actual_negation_of_conjunction(constraint_list, fs::FormulaStats; conjunct_name=nothing)
    """
    Assert the negation of conjunction of the constraints passed in constraint_list.
    not (A and B and C and ...)
    """
    formula, conjunct_name = declare_conjunction(constraint_list, fs; conjunct_name=conjunct_name) # declare conjunction
    push!(formula, assert_statement(negate(conjunct_name))) # assert NEGATED conjunction
    return formula
end

function declare_conjunction(constraint_list, fs::FormulaStats; conjunct_name=nothing, use_macros=false)
    """
    Given a list of constraints, declare their conjunction but DO NOT
    assert their conjunction.
    can use macros e.g. 
    (define-fun _def1 () Bool (<= x 2.0))
    (define-fun _def2 () Bool (>= y 3.0))
    
    or can use new boolean variables
    (declare-const b1 Bool)
    (assert (== b1 (<= x 2.0)))
    
    ...
    (declare ... phi)
    (assert (= phi (and A B)))

    But notice we are just _defining_ phi, we are not asserting that
    phi _holds_, which would be: (assert phi) [not doing that tho!]
    """
    defs, names = declare_list(constraint_list, fs; use_macros=use_macros)
    if isnothing(conjunct_name)
        conjunct_name = get_new_bool(fs)
    end
    @assert length(names) > 1
    conjunct = prefix_notate("and", names)
    conjunct_decl = [declare_const(conjunct_name, "Bool")]
    conjunct_def = [define_atom(conjunct_name, conjunct)]
    formula = vcat(defs, conjunct_decl, conjunct_def)
    return formula, conjunct_name
end

function assert_disjunction(constraint_list, fs::FormulaStats; disjunct_name=nothing)
    throw(MyError("NotImplementedError"))
end

"""
Convert julian relational operators into smtlib2 friendly ones. 
"""
function convert_f(f::Symbol)
    if f == :(==)
        return "="
    elseif f == :≤ || f == :≦
        return "<="
    elseif f == :≥ || f == :≧
        return ">="
    else 
        return string(f)
    end
end

function convert_any_constraint(c::Expr, fs::FormulaStats)
    # basically just prefix notate the constraint and take from expr -> string
    # base case: numerical number
    try
        constant = eval(c)
        return convert_any_constraint(constant::Real, fs)
    catch e
    end
    # recursive case
    f = convert_f(c.args[1])
    args = c.args[2:end]
    converted_args = []
    for a in args
        push!(converted_args, convert_any_constraint(a, fs))
    end
    return prefix_notate(string(f), converted_args)
end
# base cases:
function convert_any_constraint(s::Symbol, fs::FormulaStats)
    add_real_var(s, fs) # log var
    return string(s)
end
function convert_any_constraint(n::Real, fs::FormulaStats)
    if n >= 0
        return string(n)
    else #if n < 0
        return prefix_notate("-", [-n]) # smtlib2 can't handle negative numbers and needs unary minus, ugh (!)
    end
end

function declare_list(constraint_list::Array, fs::FormulaStats; use_macros=false)
    """
    turn a list of some type of AbstractConstraint <: into 
    
    smtlib macro declarations/definitions:
    (define-fun _def1 () Bool (<= x 2.0))
    
    But DON'T assert either true or false for the macro (e.g. (assert _def1()) )
    
    OR new binary variables:
    
    (declare-const b1 Bool)
    (assert (= b1 (<= v 9)))
    
    And again DON'T assert either (assert b1) or (assert (not b1))
    """
    defs = [] # definitions + declarations
    names = [] # names
    for item in constraint_list 
        expr = convert_any_constraint(item, fs)::String
        if use_macros 
            macro_name = get_new_macro(fs)
            push!(names, macro_name)
            push!(defs, define_bool_macro(macro_name, expr))
        else # use new bools
            bool_name = get_new_bool(fs)
            push!(names, bool_name)
            push!(defs, declare_const(bool_name, "Bool"))
            push!(defs, define_atom(bool_name, expr))
        end
    end
    return defs, names
end

function get_new_macro(fs::FormulaStats)
    """ Get new macro name """
    fs.bool_macro_count += 1
    v = "_def"*string(fs.bool_macro_count) 
    @assert not(v in fs.bool_macros)
    push!(fs.bool_macros, v)
    return v
end

