## Import necessary package
using HTTP
using Random
using JSON
using CartesianGeneticProgramming
using Cambrian
using ArgParse
using Sockets
using Formatting
include("Scripts/Evaluate.jl")
include("Scripts/CGPAgentV0.jl")

## Settings
## Necessary settings
s = ArgParseSettings()
@add_arg_table! s begin
    "--breezyIp"
    help = "breezy server IP adress"
    default = "127.0.0.1"
    "--breezyPort"
    help = "breezy server port number"
    default = "8085"
    "--agentIp"
    help = "agent server IP adress"
    default = "127.0.0.1"
    "--agentPort"
    help = "agent server port number"
    default = "8086"
    "--startData"
    help = "the initial number of games launch when the agent is started"
    arg_type = Dict{String}{Any}
    default = Dict(
                "agent"=> "Sample Random Agent",
                "size"=> 1
            )
    "--cfg"
    help = "configuration script"
    default = "Config/CGPconfigV0.yaml"
end


args = parse_args(ARGS, s)
cfg = get_config(args["cfg"])

# add to cfg the number of input(i.e nb of feature) and output
cfg["n_in"] = 310
cfg["n_out"] = 30

cfg["n_game"] = 0

"""
Declare variables global that you want the agent server to have access to.
"""
global breezyIp
global breezyPort
global agentIp
global agentPort
global startData
global last_features
global server
global individual

breezyIp = args["breezyIp"]
breezyPort = args["breezyPort"]
agentIp = args["agentIp"]
agentPort = args["agentPort"]
startData = args["startData"]
# to be able to evaluate the fitness
last_features = Dict("no_lastfeat_fornow"=>0)
# the server will be reinitialize when playing Dota
server = "whatever"
#
individual = "not_initialized"
# # test of the PlayDota function
# fitnesses = []
# for i in 1:3
#     fit = PlayDota()
#     push!(fitnesses,fit)
# end
# println(fitnesses)

e = Cambrian.Evolution(CGPInd, cfg;
                     populate=Populate,
                     evaluate=Evaluate)
Cambrian.run!(e)
best = sort(e.population)[end]
println("Final fitness: ", best.fitness[1])
