## Import necessary package
using HTTP
using Random
using JSON
using CartesianGeneticProgramming
using Cambrian
using ArgParse
using Sockets

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
- getting features and returning action.
- close the server when a game is over
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
    global breezyIp
    global breezyPort
    global agentIp
    global agentPort

    close(server)
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr,agentIp),parse(Int64,agentPort)))
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