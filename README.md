# Project-Breezy-DOTA-Evolutionnary
Evolutionary Algorithm bot for the [Breezy Project competition](https://web.cs.dal.ca/~dota2/?page_id=353) 

# Pre-requisites

To be able to make things work you first need to follow the [instructions](https://web.cs.dal.ca/~dota2/?page_id=307) in order to have DOTA2 downloaded with the right set-up and to have the Breezy Server working. You also need to have [Julia](https://julialang.org/) set and ready. From there, once the server is started we will be able to train evolutionnary agent implemented in Julia.

# Random Agent

First thing first, you can check if you have everything installed right by running the [RandomAgent.jl](./Scripts/RandomAgent.jl) script once the Breezy Server is started. If everything is set up correctly the scripts will launch five games of DOTA2 making the agent random action, once those five games are finished it will restart indefinetely five games until you manually interrupt the script. The point of this script was mainly to have the HTTP request system work in Julia and was hugely inspire by the Python file originally provided. Following scripts will focus on training an agent with Evolutionnary method.
