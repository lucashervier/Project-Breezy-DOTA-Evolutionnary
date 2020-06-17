include("../src/MAPElites.jl")
using Test
import YAML
using BlackBoxOptimizationBenchmarking


function test_struct(map::MapElites)
    @test typeof(map.feature_dimension) == Int64
    @test typeof(map.grid_mesh) == Int64
    @test typeof(map.solutions) == SparseArray{Union{Missing,Individual},map.feature_dimension}
    @test typeof(map.performances) == SparseArray{Union{Missing,Array{Float64}},map.feature_dimension}
    # test logics between dimension
    @test length(size(map.solutions)) == map.feature_dimension
    @test length(size(map.performances)) == map.feature_dimension
    for i in 1:map.feature_dimension
        @test size(map.solutions)[i] == map.grid_mesh
        @test size(map.performances)[i] == map.grid_mesh
    end
end

function test_donotchange_struct(map1::MapElites,map2::MapElites)
    @test map1.feature_dimension == map2.feature_dimension
    @test map1.grid_mesh == map2.grid_mesh
    @test typeof(map1.solutions) == typeof(map2.solutions)
    @test typeof(map1.performances) == typeof(map2.performances)
    @test size(map1.solutions) == size(map2.solutions)
    @test size(map1.performances) == size(map2.performances)
end

function map_ind_toyproblem(ind::Individual)
    x = ind.genes[1]
    y = ind.genes[2]
    grid_mesh = 100

    x_ind = Int(trunc(grid_mesh*x)) + 1
    y_ind = Int(trunc(grid_mesh*y)) + 1
    [x_ind,y_ind]
end

function rosenbrock(i::Individual)
    x = i.genes
    y = -(sum([(1.0 - x[i])^2 + 100.0 * (x[i+1] - x[i]^2)^2
              for i in 1:(length(x)-1)]))
    [y]
end

@testset "MAPElites.jl" begin
    @testset "mapelites_struct.jl" begin
        # a first test simple enough fill with missing value
        map_el = MapElites(1,1)
        test_struct(map_el)
        @test isequal(map_el.solutions[1],missing)
        @test isequal(map_el.performances[1],missing)
        # a more difficult test fill with missing value
        map_el = MapElites(2,2)
        test_struct(map_el)
        @test isequal(map_el.solutions[1,1],missing)
        @test isequal(map_el.performances[1,1],missing)
        @test isequal(map_el.solutions[1,2],missing)
        @test isequal(map_el.performances[1,2],missing)
        @test isequal(map_el.solutions[2,1],missing)
        @test isequal(map_el.performances[2,1],missing)
        @test isequal(map_el.solutions[2,2],missing)
        @test isequal(map_el.performances[2,2],missing)
        # try a 3-D array with a mesh of 5 fill with missing value
        map_el = MapElites(3,5)
        test_struct(map_el)
        @test size(map_el.solutions) == (5,5,5)
        @test size(map_el.performances) == (5,5,5)
        @test isequal(map_el.solutions[3,2,1],missing)
        @test isequal(map_el.performances[3,2,1],missing)
        # test of the function test_donotchange_struct
        test_donotchange_struct(map_el,map_el)
        # map_el2 = MapElites(3,4)
        # test_donotchange_struct(map_el,map_el2)
    end

    @testset "mapelites_functions.jl" begin
        @testset "count element" begin
            map_el = MapElites(2,2)
            @test count_elt(map_el) == 0
            map_el.solutions[1,1] = Individual([0,1,0],[10.0])
            map_el.performances[1,1] = [10.0]
            @test count_elt(map_el) == 1
            map_el.solutions[1,2] = Individual([1,1,0],[15.0])
            map_el.performances[1,2] = [15.0]
            @test count_elt(map_el) == 2
            map_el = MapElites(3,4)
            @test count_elt(map_el) == 0
            map_el.solutions[1,1,1] = Individual([0,1,0],[10.0])
            map_el.performances[1,1,1] = [10.0]
            @test count_elt(map_el) == 1
            map_el.solutions[2,2,3] = Individual([1,1,0],[15.0])
            map_el.performances[2,2,3] = [15.0]
            @test count_elt(map_el) == 2
            test_struct(map_el)
        end

        @testset "add_to_map function" begin
            map_el = MapElites(3,10)
            map_el_old = deepcopy(map_el)
            coordinate = [5,4,3]
            solution = Individual([1,1,0],[5.0])
            performance = [5.0]
            add_to_map(map_el,coordinate,solution,performance)
            # check if we do not alterate structure by adding information
            test_struct(map_el)
            test_donotchange_struct(map_el_old,map_el)
            # check if we actually add at the right place our Individual
            @test count_elt(map_el)==count_elt(map_el_old)+1
            @test map_el.solutions[5,4,3] == solution
            @test map_el.performances[5,4,3] == performance
            # check if we add an object at the same place if it is still working
            map_el_old = deepcopy(map_el)
            new_solution = Individual([1,1,1],[10.0])
            new_perf = [10.0]
            add_to_map(map_el,coordinate,new_solution,new_perf)
            @test count_elt(map_el) == count_elt(map_el_old)
            @test map_el.solutions[5,4,3] == new_solution
            @test map_el.performances[5,4,3] == new_perf
            test_struct(map_el)
            # check if we add an individual with a lower performance (theorically no)
            worse_ind = Individual([1,0,0],[8.0])
            worse_perf = [8.0]
            add_to_map(map_el,coordinate,worse_ind,worse_perf)
            @test map_el.solutions[5,4,3] == new_solution
            @test map_el.performances[5,4,3] == new_perf
            # check if a better ind replace a worse one
            better_ind = Individual([1,0,0],[12.0])
            better_perf = [12.0]
            add_to_map(map_el,coordinate,better_ind,better_perf)
            @test map_el.solutions[5,4,3] == better_ind
            @test map_el.performances[5,4,3] == better_perf
        end

        @testset "select_random function" begin
            map_el = MapElites(3,4)
            ind1 = Individual([0,0,0],[1.0])
            ind2 = Individual([0,1,0],[2.0])
            add_to_map(map_el,[1,1,1],ind1,[1.0])
            add_to_map(map_el,[1,2,1],ind2,[2.0])
            ind = select_random(map_el)
            @test typeof(ind) <: Individual
            @test ((ind == ind1) || (ind == ind2))
            test_struct(map_el)
        end

        @testset "select_most_promising function" begin
            map_el = MapElites(3,4)
            ind1 = Individual([0,0,0],[10.0])
            perf1 = [10.0]
            coord1 = [1,2,3]
            ind2 = Individual([0,1,0],[18.0])
            perf2 = [18.0]
            coord2 = [2,2,1]
            ind3 = Individual([0,0,0],[15.0])
            perf3 = [15.0]
            coord3 = [3,4,1]
            add_to_map(map_el,coord1,ind1,perf1)
            add_to_map(map_el,coord2,ind2,perf2)
            add_to_map(map_el,coord3,ind3,perf3)
            @test count_elt(map_el) == 3
            most_promising = select_most_promising(map_el)
            @test most_promising == ind2
            @test most_promising.fitness == perf2
            @test typeof(most_promising) <: Individual
            ind4 = Individual([1,0,0],[20.0])
            perf4 = [20.0]
            coord4 = [3,2,2]
            add_to_map(map_el,coord4,ind4,perf4)
            most_promising = select_most_promising(map_el)
            @test most_promising == ind4
            @test most_promising.fitness == perf4
            @test typeof(most_promising) <: Individual
        end
    end

    @testset "populate_function.jl" begin
        @testset "mapelites_step!" begin
            map_el = MapElites(2,20)
            cfg = YAML.load_file("cfg/mapelites.yaml")
            e = Cambrian.Evolution(Cambrian.FloatIndividual,cfg)
            fit = i::Individual->[Random.rand()]
            Cambrian.fitness_evaluate!(e; fitness=fit)
            best = sort(e.population)[end]
            e_old = deepcopy(e)
            map_ind_to_b(ind::Individual) = [Random.rand(1:map_el.grid_mesh) for dim in 1:map_el.feature_dimension]
            mapelites_step!(e,map_el,map_ind_to_b)
            @test length(e.population) == cfg["n_population"]
            @test e_old.population != e.population
            @test count_elt(map_el) >= length(e_old.population)
            new_best = sort(e.population)[end]
            @test new_best.fitness >= best.fitness
        end

        @testset "mapelites_run!" begin
            cfg = YAML.load_file("cfg/mapelites.yaml")
            e = Cambrian.Evolution(Cambrian.FloatIndividual,cfg)
            features_dim = e.cfg["features_dim"]
            grid_mesh = e.cfg["grid_mesh"]
            mapel = MapElites(features_dim,grid_mesh)
            map_ind_to_b(ind::Individual) = [Random.rand(1:grid_mesh) for dim in 1:features_dim]
            mapelites_run!(e,mapel,map_ind_to_b)
            test_struct(mapel)
            @test count_elt(mapel) > 0
            @test length(e.population) == cfg["n_population"]
            @test e.gen == cfg["n_gen"]
            best = sort(e.population)[end]
            best_map = select_most_promising(mapel)
            @test best_map.fitness == best.fitness
        end
    end

    @testset "toyproblem" begin
        cfg = YAML.load_file("cfg/mapelites.yaml")
        cfg["n_genes"] = 2
        features_dim = 2
        grid_mesh = 100
        cfg["n_gen"] = 10
        cfg["n_population"] = 1000
        rast = BlackBoxOptimizationBenchmarking.F15
        evaluate1(ind::Individual) = rosenbrock(ind)
        e = Cambrian.Evolution(Cambrian.FloatIndividual,cfg)
        mapel = MapElites(features_dim,grid_mesh)
        mapelites_run!(e,mapel,map_ind_toyproblem;evaluate=evaluate1)
        test_struct(mapel)
        @test count_elt(mapel) > 0
        @test length(e.population) == cfg["n_population"]
        @test e.gen == cfg["n_gen"]
        best = sort(e.population)[end]
        best_map = select_most_promising(mapel)
        @test best_map.fitness == best.fitness
        # println(best_map)
        # println(best)
        # println(mapel.solutions)
    end
end
