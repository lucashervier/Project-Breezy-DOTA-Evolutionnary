## Import necessary packages
using JSON

# we import the list of our features into a dict to map array indexes
const FEATURES_MAP = JSON.parsefile("features_list2.json")

## for now the fitness function will only be the amount of gold
function fitness(lastState::Array{Any}{1})
	# array index in Julia start at 1
	gold = lastState[FEATURES_MAP["gold"]+1]
	return gold
end