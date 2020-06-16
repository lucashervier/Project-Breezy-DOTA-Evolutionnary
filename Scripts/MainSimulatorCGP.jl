cd("C:/Lucas_Hervier/Lucas_Hervier/Documents/Cours/3A/SFE/Dota_challenge/Project-Breezy-DOTA-Evolutionnary") 
## Import necessary package
using HTTP
using Random
using JSON
using CartesianGeneticProgramming
using Cambrian
using ArgParse
using Sockets
using Formatting
using Dates
using PyCall
using Conda
include("Scripts/Evaluate.jl")
include("Scripts/SimulatorCGP.jl")
pushfirst!(PyVector(pyimport("sys")."path"), "Dota_Simulator")
Dota_Simulator = pyimport("DOTA_simulator")  
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
    default = "Config/CGPconfigV1.yaml"
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
global nbKill
global nbDeath
global earlyPenalty

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
#
nbKill = 0
nbDeath = 0
earlyPenalty = 0

## MAIN ###

e = Cambrian.Evolution(CGPInd, cfg;
                     populate=Populate,
                     evaluate=Evaluate)
Cambrian.run!(e)
best = sort(e.population)[end]
println("Final fitness: ", best.fitness[1])