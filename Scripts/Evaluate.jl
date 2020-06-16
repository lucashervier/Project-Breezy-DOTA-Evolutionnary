# we import the list of our features into a dict to map array indexes
const FEATURES_MAP = JSON.parsefile("features_list2.json")
const TIME_TO_KILL = Dict(180.0=>1,300.0=>2,420.0=>5)

"""
Helper functions to get the fitness whatever agent you are using.
"""
function Fitness(lastState::Array{Float64}{1})
	# array index in Julia start at 1
	gold = lastState[FEATURES_MAP["gold"]+1]
	return gold
end

function Fitness1(lastState::Array{Float64}{1},nbKill::Int64,nbDeath::Int64,earlyPenalty::Int64)
	netWorth = lastState[FEATURES_MAP["net worth"]+1]
	lastHits = lastState[FEATURES_MAP["last hits"]+1]
	denies = lastState[FEATURES_MAP["last hits"]+1]
	towerHealth = lastState[FEATURES_MAP["bad tower health"]+1]
	maxTowerHealth = lastState[FEATURES_MAP["bad tower max health"]+1]
	ratioTower = (maxTowerHealth-towerHealth)/maxTowerHealth
	reward = netWorth + 100*lastHits + 100*denies + 2000*ratioTower + 1000*nbKill - 250*nbDeath - 500*earlyPenalty
	# reward = netWorth + 100*lastHits + 100*denies + 400*trunc(ratioTower/0.2)
	return reward
end

"""
Helper function to know if you should quit the game earlier than the GameOver
"""
function EarlyStop(lastState::Array{Float64}{1})
	dotaTime = lastState[FEATURES_MAP["dota time"]+1]
	lastHits = lastState[FEATURES_MAP["last hits"]+1]
	for (timeCreep,killedCreep) in TIME_TO_KILL
		if (dotaTime>timeCreep&&lastHits<killedCreep)
			return true
		end
	end
	return false
end

"""
Function to save a CGP Individual
"""
function SaveInd(ind::Individual;name::String="None")
	saveFile = JSON.json(String(ind))
	if (name=="None")
		fileName = Dates.now()
		fileName = Dates.format(fileName, "yyyy-mm-dd-HH-MM")
	else
		fileName = name
	end
	open("best/$fileName.json","w") do f
		write(f,saveFile)
	end
end

"""
Function to load a CGP Individual
"""
function LoadInd(path::String)
	indInfo = JSON.parsefile(path)
	return CGPInd(cfg,indInfo)
end

"""
Function to load an entire population from a gen folder.
The evolution need to be initialized first.
"""
function LoadGen(e::Evolution, path::String)
	individualNameList = readdir("gens/$path")
	individualList = Cambrian.Individual[]
	for i in eachindex(individualNameList)
		indString = read("gens/$path/$(individualNameList[i])", String)
		ind = CGPInd(cfg,indString)
		push!(individualList,ind)
	end
	e.population = individualList
end

"""
Function to change the evolution id
"""
function ChangeId(e::Evolution;name::String="None")
	if (name == "None")
		id = Dates.now()
		id = Dates.format(id, "dd-mm-yyyy-HH-MM")
		id = "GenerationsFrom-$id"
	else
		id = name
	end
	e.id = id
end
