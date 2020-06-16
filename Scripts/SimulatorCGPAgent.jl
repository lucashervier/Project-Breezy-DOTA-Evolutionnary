using PyCall

"""
This function is the one generating population  
"""
function Populate(evo::Cambrian.Evolution)
    mutation = i::CGPInd->goldman_mutate(cfg, i)
    Cambrian.oneplus_populate!(evo; mutation=mutation, reset_expert=true)
end

"""
This function is the one that allow us to evaluate an individual 
"""
function Evaluate(evo::Cambrian.Evolution)
    # define the fitness function
    fit = i::CGPInd->PlayDota(i)
    Cambrian.fitness_evaluate!(evo; fitness=fit)
    evo.text = Formatting.format("{1:e}", cfg["n_game"])
end
