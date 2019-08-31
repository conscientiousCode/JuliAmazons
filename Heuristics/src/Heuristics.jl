module Heuristics

# "Internal" is a submodule, defined in `Internal.jl`. The name
# "Internal" here is just an example; you should name your modules
# however you see fit.
include("History.jl")
include("Mobility.jl")
include("Territory.jl")
include("Transposition.jl")
include("DistributedHistory.jl")
include("FractTerritory.jl")
using .History
using .Mobility
using .Territory
using .Transposition


end
