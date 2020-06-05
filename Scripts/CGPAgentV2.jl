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
    # path is either an array containing "update" or nothing so the following line means "if there is an update"
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
        println("Fitness: $(fitness(last_features))")
        """
        Since the Game is over we want to close the server
        """
        # closing the server generate an error, in order to keep the code running we use a try & catch
        try
            close(server)
        catch e
            return HTTP.post(404,JSON.json(Dict("socket closed"=>"0")))
        end
    else 
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
        println("Action made: $action")
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

    # initialize the server 
    server = Sockets.listen(Sockets.InetAddr(parse(IPAddr,agentIp),parse(Int64,agentPort)))
    # the url we need to trigger to start a game
    startUrl = "http://$breezyIp:$breezyPort/run/"
    # initialize game
    response = HTTP.post(startUrl, ["Content-Type" => "application/json"], JSON.json(startData))
    # will run the game until it is over, when it is over there is error because of the server closure
    try
        HTTP.serve(ServerHandler,args["agentIp"],parse(Int64,args["agentPort"]);server=server)
    # when there is the error we know the game is over and we can return the fitness
    catch e
        return fitness(last_features)
    end
end