# we import the list of our features into a dict to map array indexes
const FEATURES_MAP = JSON.parsefile("features_list2.json")
const TIME_TO_KILL = 120.0

"""
Helper function to get the fitness whatever agent you are using. For now,
the fitness is only the amount of gold you have at the end of the game
"""
function Fitness(lastState::Array{Float64}{1})
	# array index in Julia start at 1
	gold = lastState[FEATURES_MAP["gold"]+1]
	return gold
end

function Fitness1(lastState::Array{Float64}{1})
	netWorth = lastState[FEATURES_MAP["net worth"]+1]
	lastHits = lastState[FEATURES_MAP["last hits"]+1]
	denies = lastState[FEATURES_MAP["last hits"]+1]
	towerHealth = lastState[FEATURES_MAP["bad tower health"]+1]
	maxTowerHealth = lastState[FEATURES_MAP["bad tower max health"]+1]
	ratioTower = (maxTowerHealth-towerHealth)/maxTowerHealth
	reward = netWorth + 100*lastHits + 100*denies + 2000*ratioTower
	return reward 
end

"""
Helper function to know if you should quit the game earlier than the GameOver
"""
function EarlyStop(lastState::Array{Float64}{1})
	dotaTime = lastState[FEATURES_MAP["dota time"]+1]
	lastHits = lastState[FEATURES_MAP["last hits"]+1]
	if (dotaTime>TIME_TO_KILL&&lastHits<1)
		return true
	else
		return false
	end
end
