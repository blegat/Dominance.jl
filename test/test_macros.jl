include("../src/dominance.jl")

module TestMain

using Test
using LinearAlgebra
using StaticArrays
using Main.Dominance
DO = Main.Dominance

sleep(0.1) # used for good printing
println("Started test")

@testset "Macros: symmodel_from_system!" begin
lb = SVector(0.0, 0.0)
ub = SVector(10.0, 11.0)
x0 = SVector(0.0, 0.0)
h = SVector(1.0, 2.0)
grid = DO.Grid(x0, h)
domain = DO.Domain(grid)
DO.add_set!(domain, DO.HyperRectangle(lb, ub), DO.OUTER)

tstep = 0.5
nsys = 3
F_sys(x) = SVector(0.5, -cos(x[1]))
DF_sys(x) = SMatrix{2,2}(0.0, sin(x[1]), 0.0, 0.0)
bound_DF = 1.0
bound_DDF = 1.0

sys = DO.ContSystemRK4(tstep, F_sys, DF_sys, bound_DF, bound_DDF, nsys)
symmodel = DO.SymbolicModel(domain)
DO.symmodel_from_system!(symmodel, sys)
@test DO.get_ntransitions(symmodel.autom) == 589

pos = (1, 2)
x = DO.get_coord_by_pos(grid, pos)
source = DO.get_state_by_pos(symmodel, pos)

dom1 = DO.Domain(grid)
DO.add_pos!(dom1, pos)
dom2 = DO.Domain(grid)
translist = Tuple{Int,Int,Int}[]
DO.compute_post!(translist, symmodel.autom, source)
for trans in translist
    DO.add_pos!(dom2, DO.get_pos_by_state(symmodel, trans[3]))
end

@static if get(ENV, "CI", "false") == "false"
    include("../src/plotting.jl")
    using PyPlot
    fig = PyPlot.figure()
    ax = fig.gca()
    ax.set_xlim((-1.0, 11.0))
    ax.set_ylim((-2.0, 14.0))
    Plot.domain!(ax, 1:2, domain, fa = 0.1)
    Plot.domain!(ax, 1:2, dom1)
    Plot.domain!(ax, 1:2, dom2)
    Plot.trajectory!(ax, 1:2, sys, x, 50)
    Plot.cell_image!(ax, 1:2, dom1, sys)
    Plot.cell_approx!(ax, 1:2, dom1, sys)
end

lb = SVector(-7.0, -7.0)
ub = SVector(7.0, 7.0)
x0 = SVector(0.0, 0.0)
h = SVector(1.0, 2.0)
grid = DO.Grid(x0, h)
domain = DO.Domain(grid)
DO.add_set!(domain, DO.HyperRectangle(lb, ub), DO.OUTER)

θ = π/5.0
U = 2*SMatrix{2,2}(cos(θ), -sin(θ), sin(θ), cos(θ))
F_sys(x) = U*SVector(atan(x[1]), atan(x[2]))
DF_sys(x) = U*SMatrix{2,2}(1/(1 + x[1]^2), 0, 0, 1/(1 + x[2]^2))
bound_DDF = norm(U, Inf)*3*sqrt(3)/8

sys = DO.DiscSystem(F_sys, DF_sys, bound_DDF)
symmodel = DO.SymbolicModel(domain)
DO.symmodel_from_system!(symmodel, sys)
@test DO.get_ntransitions(symmodel.autom) == 717

pos = (1, 2)
x = DO.get_coord_by_pos(grid, pos)
source = DO.get_state_by_pos(symmodel, pos)

dom1 = DO.Domain(grid)
DO.add_pos!(dom1, pos)
dom2 = DO.Domain(grid)
translist = Tuple{Int,Int,Int}[]
DO.compute_post!(translist, symmodel.autom, source)
for trans in translist
    DO.add_pos!(dom2, DO.get_pos_by_state(symmodel, trans[3]))
end

@static if get(ENV, "CI", "false") == "false"
    include("../src/plotting.jl")
    using PyPlot
    fig = PyPlot.figure()
    ax = fig.gca()
    ax.set_xlim((-8.0, 8.0))
    ax.set_ylim((-9.5, 9.5))
    Plot.domain!(ax, 1:2, domain, fa = 0.1)
    Plot.domain!(ax, 1:2, dom1)
    Plot.domain!(ax, 1:2, dom2)
    Plot.trajectory!(ax, 1:2, sys, x, 50)
    Plot.cell_image!(ax, 1:2, dom1, sys)
    Plot.cell_approx!(ax, 1:2, dom1, sys)
end
end

@testset "Macros: viable_controller!" begin
nstates = 10
nsymbols = 5
autom = DO.Automaton(nstates, nsymbols)

DO.add_transition!(autom, (5, 1, 9))
DO.add_transition!(autom, (5, 1, 8))
DO.add_transition!(autom, (5, 1, 3))
DO.add_transition!(autom, (8, 1, 3))
DO.add_transition!(autom, (5, 3, 5))
DO.add_transition!(autom, (8, 1, 5))
DO.add_transition!(autom, (1, 1, 2))
DO.add_transition!(autom, (2, 1, 4))
DO.add_transition!(autom, (4, 1, 6))
DO.add_transition!(autom, (6, 1, 7))
DO.add_transition!(autom, (7, 1, 8))
DO.add_transition!(autom, (9, 1, 10))
@test DO.get_ntransitions(autom) == 12

viablelist = 1:nstates
contr = DO.Controller()
DO.viable_controller!(contr, autom, viablelist)
@test Set(DO.enum_states(contr)) == Set([5, 8])
end

@testset "Macros: symmodel_from_system! + viabel_controller" begin
lb = SVector(-7.0, -7.0)
ub = SVector(7.0, 7.0)
x0 = SVector(0.0, 0.0)
h = SVector(1.0, 2.0)/10
grid = DO.Grid(x0, h)
domain = DO.Domain(grid)
DO.add_set!(domain, DO.HyperRectangle(lb, ub), DO.OUTER)
DO.remove_set!(domain, DO.HyperRectangle(lb/5, ub/5), DO.OUTER)

θ = π/5.0
U = 2*SMatrix{2,2}(cos(θ), -sin(θ), sin(θ), cos(θ))
F_sys(x) = U*SVector(atan(x[1]), atan(x[2]))
DF_sys(x) = U*SMatrix{2,2}(1/(1 + x[1]^2), 0, 0, 1/(1 + x[2]^2))
bound_DDF = norm(U, Inf)*3*sqrt(3)/8

sys = DO.DiscSystem(F_sys, DF_sys, bound_DDF)
symmodel = DO.SymbolicModel(domain)
DO.symmodel_from_system!(symmodel, sys)
@test DO.get_ntransitions(symmodel.autom) == 23468

viablelist = Int[]
for pos in DO.enum_pos(domain)
    push!(viablelist, DO.get_state_by_pos(symmodel, pos))
end

contr = DO.Controller()
DO.viable_controller!(contr, symmodel.autom, viablelist)
@test length(collect(DO.enum_states(contr))) == 292

pos = (1, 2)
x = DO.get_coord_by_pos(grid, pos)

dom1 = DO.Domain(grid)
for state in DO.enum_states(contr)
    DO.add_pos!(dom1, DO.get_pos_by_state(symmodel, state))
end

@static if get(ENV, "CI", "false") == "false"
    include("../src/plotting.jl")
    using PyPlot
    fig = PyPlot.figure()
    ax = fig.gca()
    ax.set_xlim((-8.0, 8.0))
    ax.set_ylim((-9.5, 9.5))
    Plot.domain!(ax, 1:2, domain, fa = 0.1)
    Plot.domain!(ax, 1:2, dom1)
    Plot.trajectory!(ax, 1:2, sys, x, 50)
    Plot.cell_image!(ax, 1:2, dom1, sys)
    Plot.cell_approx!(ax, 1:2, dom1, sys)
end
end

sleep(0.1) # used for good printing
println("End test")

end  # module TestMain
