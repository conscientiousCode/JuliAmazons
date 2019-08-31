module Transposition

    using Board

    export TranspositionTable, generateTranspositionTable, setValue, hasEntry, getValue

    struct TranspositionTable
        lookup::Dict{Tuple{Int,Int,Int,Int,Int,Int,Int,Int,Int,Int},Float64}
    end

    function generateTranspositionTable()
        return TranspositionTable(Dict{Tuple{Int,Int,Int,Int,Int,Int,Int,Int,Int,Int}, Float64}())
    end

    function setValue(tt::TranspositionTable, b::BoardState, heuristicValue::Float64)
        tt.lookup[Tuple(b.rowHashes)] = heuristicValue
    end


    function hasEntry(tt::TranspositionTable, b::BoardState)::Bool
        return haskey(tt.lookup, Tuple(b.rowHashes))
    end

    function getValue(tt::TranspositionTable, b::BoardState)::Float64
        return tt.lookup[Tuple(b.rowHashes)]
    end

    #=
    b = Board.DefaultBoard()
    m = Move(1,4,6,4,6,2)
    value = 2.44
    tt = Transposition.generateTranspositionTable()
    println(Transposition.hasEntry(tt, b))
    Transposition.setValueAndMove(tt,b,m,value)
    println(Transposition.hasEntry(tt, b))
    println(Transposition.getValueAndMove(tt, b))
    Board.applyMove(b,m)
    println(Transposition.hasEntry(tt, b))
    =#

    #=
    temp = Dict{Tuple{Int,Int,Int,Int,Int,Int,Int,Int,Int,Int}, Int}()
    for i = 1:20
        println(haskey(temp, Tuple([j for j = i:i+9])))
    end
    =#

end
