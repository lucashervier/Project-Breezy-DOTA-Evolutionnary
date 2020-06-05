## Import necessary package
using HTTP
using Random
using JSON
using CartesianGeneticProgramming
using Cambrian
using ArgParse
using Sockets
include("Scripts/Evaluate.jl")

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
                "size"=> 5
            )
    "--cfg"
    help = "configuration script"
    default = "Config/CGPconfig.yaml"
end


args = parse_args(ARGS, s)
cfg = get_config(args["cfg"])

# add to cfg the number of input(i.e nb of feature) and output
cfg["n_in"] = 310
cfg["n_out"] = 30

## Modified service functions
"""
Helper function to get content passed with http request.
"""
function GetContent(request::HTTP.Request)
    content = JSON.parse(String(request.body))
    return content
end

"""
Sends a response containing a json object (usually the action or fitness value).
"""
function PostResponse(response::Dict{String}{Int64})
    return HTTP.Response(200,JSON.json(response))
end


"""
ServerHandler used for handling the different service:
- starting a new set of games
- start a game in existing set of games
- getting features and returning action.
"""
function ServerHandler(request::HTTP.Request)
    global last_features
    path = HTTP.URIs.splitpath(request.target)
    println("Path is: $path")
    # path is either an array containing "update" or nothing
    # so the following line means "if there is an update"
    if (size(path)[1] != 0) 
        """
        Update route is called, game finished.
        """
        
        global breezyIp
        global breezyPort

        content = GetContent(request)
        rundata = JSON.json(content)
        println(fitness(last_features))
        gameOver = true
        # webhook to start new game in existing set of games
        if (occursin("webhook",rundata))
            """
            A webhook was sent to the agent to start a new game in the current
            set of games.
            """
            webhookUrl = "http://$breezyIp:$breezyPort$(content["webhook"])"
            #println(webhookUrl)
            
            # call webhook to trigger new game
            response = HTTP.get(webhookUrl)
            println("Starting a new game amoong the set")
        # otherwise start new set of games, or end session
        else
            """
            This sample agent just runs indefinately. So here I will just start
            a new set of 5 games. You could just always set the amount of games
            to 1, and forget about the webhook part, whatever works for you.
            In here would probably be where you put the code to ready a new agent
            (update NN weights, evolutions, next agent in current gen. etc.).
            """
            
            # build url to dota 2 breezy server
            startUrl = "http://$breezyIp:$breezyPort/run/"
            # create a run config for this agent, to run 5 games
            global startData
            response = HTTP.post(startUrl, ["Content-Type" => "application/json"], JSON.json(startData))
            println("A new set of $(startData["size"]) game is triggered with a $(startData["agent"])")
        end
        # send whatever to server
        PostResponse(Dict("fitness"=>42))

        
    else # relay path gives features from current game to agent
        """
        Relay route is called, gives features from the game for the agent.
        """
        
        println("Received features.")
        # get data as json, then save to list
        content = GetContent(request)       
        features = JSON.json(content)
        println(features)
        last_features = content
        """
        Agent code to determine action from features would go here.
        """
        action = Random.rand(0:29) # just random action for this example
        println(action)
        PostResponse(Dict("actionCode"=>action))
    end
end

### Main Loop ###
"""
Declare variables global that you want the agent server to have access to.
"""
global breezyIp
global breezyPort
global startData
global last_features

breezyIp = args["breezyIp"]
breezyPort = args["breezyPort"]
startData = args["startData"]
# to be able to evaluate the fitness
last_features = Dict("no_lastfeat_fornow"=>0)

# build url to dota 2 breezy server
startUrl = "http://$breezyIp:$breezyPort/run/"
# initialize a first set of games
response = HTTP.post(startUrl, ["Content-Type" => "application/json"], JSON.json(startData))
# will run until forced termination
HTTP.serve(ServerHandler,args["agentIp"],parse(Int64,args["agentPort"]))


	



