module History
    using Board

    export MoveHistory, initializeMoveHistory, updateMoveScore, orderMoves, divideAllScores

    #Bits required to index a move
    #colour = 1, to = 6, from = 6, arrowTo = 6
    BITS_REQUIRED = 2^19 # = 1/2 MB

    struct MoveHistory
        white::Array{Float64, 6}
        black::Array{Float64, 6}
    end

    function initializeMoveHistory()
        white = zeros(Float64,10, 10, 10, 10, 10, 10)
        black = zeros(Float64,10, 10, 10, 10, 10, 10)
        return MoveHistory(white, black)
    end

    function getMoveScore(hist::MoveHistory, m::Move, colourOfMover::Int)
        if colourOfMover == WHITE.val
            return hist.white[m.sR, m.sC, m.eR, m.eC, m.aR, m.aC]
        elseif colourOfMover == BLACK.val
            return hist.black[m.sR, m.sC, m.eR, m.eC, m.aR, m.aC]
        else
            throw(DomainError("colourOfMover == $colourOfMover, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end

    function updateMoveScore(hist::MoveHistory, m::Move, colourOfMover::Int, nodeDepth::Int, maxDepth::Int)
        score = 2^(maxDepth-nodeDepth)
        if colourOfMover == WHITE.val
            hist.white[m.sR, m.sC, m.eR, m.eC, m.aR, m.aC] = hist.white[m.sR, m.sC, m.eR, m.eC, m.aR, m.aC] + score
        elseif colourOfMover == BLACK.val
            hist.black[m.sR, m.sC, m.eR, m.eC, m.aR, m.aC] = hist.black[m.sR, m.sC, m.eR, m.eC, m.aR, m.aC] + score
        else
            throw(DomainError("colourOfMover == $colourOfMover, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end

    function divideAllScores(hist::MoveHistory, divisor::Float64 = 2.0)
        @sync begin
            @async hist.white .= hist.white ./divisor
            @async hist.black .= hist.black ./divisor
        end

        return true
    end

    #=
    struct MoveHistory
        lookup::Array{Float64,1}
    end

    function initializeMoveHistory()
        lookup = zeros{Float64, BITS_REQUIRED}
        return MoveHistory(lookup)
    end


    #BREAKS if colours of WHITE or BLACK Changes
    function getMoveScore(hist::MoveHistory, m::Move, colourOfMover::Int)
        if !(colourOfMover == WHITE.val || colourOfMover == BLACK.val)
            throw(DomainError("colourOfMover == $colourOfMover, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
        index = (colourOfMover-2) << 18 +
                m.sR << 15 + m.sC << 12 +
                m.eR << 9 + m.eC << 6 +
                m.aR << 3 + m.aC

        return hist.lookup[index]
    end


    #Call when a node in the tree is about to return up, update the value
    function updateMoveScore(hist::MoveHistory, move::Move, moveScore::Float64, colourOfMover::Int, nodeDepth::Int, maxDepth::Int)
        if !(colourOfMover == WHITE.val || colourOfMover == BLACK.val)
            throw(DomainError("colourOfMover == $colourOfMover, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
        if nodeDepth < 0 || maxDepth < 0
            throw(DomainError("nodeDepth and maxDepth expected to be non-negative"))
        end
        index = (colourOfMover-2) << 18 +
                m.sR << 15 + m.sC << 12 +
                m.eR << 9 + m.eC << 6 +
                m.aR << 3 + m.aC
        hist.lookup[index] += 2^(maxDepth-nodeDepth)*moveScore

    end
    =#

    #Returns a sorted array of Tuple{score::Float64, Move}
    function orderMoves(hist::MoveHistory, moves::Array{Move,1}, colourOfMover::Int)
        if !(colourOfMover == WHITE.val || colourOfMover == BLACK.val)
            throw(DomainError("colourOfMover == $colourOfMover, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
        #Tuples of moves with scores
        #TODO: Fix this for faster sort times.
        scoredMoves = [(getMoveScore(hist, moves[i], colourOfMover), moves[i]) for i = 1:length(moves)]
        return sort!(scoredMoves, by=moveOrdering, rev=true)
    end

    function moveOrdering(tup::Tuple{Float64, Move})
        return tup[1]
    end
end
