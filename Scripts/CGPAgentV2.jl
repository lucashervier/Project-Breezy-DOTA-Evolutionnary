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
                "size"=> 1
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
        global server

        println("Game done.")
        content = GetContent(request)
        rundata = JSON.json(content)
        println("Fitness from Handler: $(fitness(last_features))")
        # close the communication
        try
            close(server)
        catch e
            return HTTP.post(404,JSON.json(Dict("socket closed"=>"0")))
        end
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

"""
This function allow us to play one game and to get the fitness score 
"""
function PlayDota() 
    global server
    close(server)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr,args["agentIp"]),parse(Int64,args["agentPort"])))
    startUrl = "http://$breezyIp:$breezyPort/run/"
    # initialize a first set of games
    response = HTTP.post(startUrl, ["Content-Type" => "application/json"], JSON.json(startData))
    # will run the game until it is over
    try
        HTTP.serve(ServerHandler,args["agentIp"],parse(Int64,args["agentPort"]);server=server)
    catch e
        return fitness(last_features)
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
global server

breezyIp = args["breezyIp"]
breezyPort = args["breezyPort"]
startData = args["startData"]
# to be able to evaluate the fitness
last_features = Dict("no_lastfeat_fornow"=>0)
server = Sockets.listen(Sockets.InetAddr(parse(IPAddr,args["agentIp"]),parse(Int64,args["agentPort"])))
    

