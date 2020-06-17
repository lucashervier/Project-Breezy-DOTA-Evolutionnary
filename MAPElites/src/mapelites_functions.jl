using Random

function count_elt(map_el::MapElites)
    return length(collect(skipmissing(map_el.solutions)))
end

function add_to_map(map_el::MapElites,coordinates,solution::Individual,performance::Array{Float64})
    if (!haskey(map_el.solutions.data,Tuple(coordinates)))
        map_el.solutions.data[Tuple(coordinates)] = solution
        map_el.performances.data[Tuple(coordinates)] = performance
    elseif (map_el.performances.data[Tuple(coordinates)] < performance)
        map_el.solutions.data[Tuple(coordinates)] = solution
        map_el.performances.data[Tuple(coordinates)] = performance
    end
end

function select_random(map_el::MapElites)
    available_ind = collect(skipmissing(map_el.solutions))
    nb_ind = length(available_ind)
    rand_idx = Random.rand(1:nb_ind)
    return available_ind[rand_idx]
end

function select_most_promising(map_el::MapElites)
    available_ind = collect(skipmissing(map_el.solutions))
    available_perf = collect(skipmissing(map_el.performances))
    idx_best = argmax(available_perf)
    return available_ind[idx_best]
end
