module DistributedHistory
    using Board

    export DistributedMoveHistory, initializeDistributedMoveHistory, updateMoveScore, orderMoves, divideAllScores


    ##=
    struct DistributedMoveHistory
        whiteStartEnd::Array{Float64, 4}
        whiteEndArrow::Array{Float64, 4}
        blackStartEnd::Array{Float64, 4}
        blackEndArrow::Array{Float64, 4}
    end

    function initializeDistributedMoveHistory()
        whiteStartEnd = zeros(Float64, 10, 10, 10, 10)
        whiteEndArrow = zeros(Float64, 10, 10, 10, 10)
        blackStartEnd = zeros(Float64, 10, 10, 10, 10)
        blackEndArrow = zeros(Float64, 10, 10, 10, 10)
        return DistributedMoveHistory(whiteStartEnd, whiteEndArrow, blackStartEnd, blackEndArrow)
    end

    function getMoveScore(hist::DistributedMoveHistory, m::Move, colourOfMover::Int)
        if colourOfMover == WHITE.val
            return hist.whiteStartEnd[m.sR, m.sC, m.eR, m.eC] +
                    hist.whiteEndArrow[m.eR, m.eC, m.aR, m.aC]
        elseif colourOfMover == BLACK.val
            return hist.blackStartEnd[m.sR, m.sC, m.eR, m.eC] +
                    hist.blackEndArrow[m.eR, m.eC, m.aR, m.aC]
        else
            throw(DomainError("colourOfMover == $colourOfMover, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end

    function updateMoveScore(hist::DistributedMoveHistory, m::Move, colourOfMover::Int, nodeDepth::Int, maxDepth::Int)
        score = 2^(maxDepth-nodeDepth)
        if colourOfMover == WHITE.val
            hist.whiteStartEnd[m.sR, m.sC, m.eR, m.eC] += (1/3)*score
            hist.whiteEndArrow[m.eR, m.eC, m.aR, m.aC] += (2/3)*score
        elseif colourOfMover == BLACK.val
            hist.blackStartEnd[m.sR, m.sC, m.eR, m.eC] += (1/3)*score
            hist.blackEndArrow[m.eR, m.eC, m.aR, m.aC] += (2/3)*score
        else
            throw(DomainError("colourOfMover == $colourOfMover, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end

    function divideAllScores(hist::DistributedMoveHistory, divisor::Float64 = 2.0)
        @sync begin
            @async hist.whiteStartEnd .= hist.whiteStartEnd ./divisor
            @async hist.whiteEndArrow .= hist.whiteEndArrow ./divisor
            @async hist.blackStartEnd .= hist.blackStartEnd ./divisor
            @async hist.blackEndArrow .= hist.blackEndArrow ./divisor
        end

        return true
    end

    #Returns a sorted array of Tuple{score::Float64, Move}
    function orderMoves(hist::DistributedMoveHistory, moves::Array{Move,1}, colourOfMover::Int)
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
    ##=#

    #=
    struct DistributedMoveHistory
        whiteStartEnd::Array{Float64, 4}
        whiteArrow::Array{Float64, 2}
        blackStartEnd::Array{Float64, 4}
        blackArrow::Array{Float64, 2}
    end

    function initializeDistributedMoveHistory()
        whiteStartEnd = zeros(Float64, 10, 10, 10, 10)
        whiteArrow = zeros(Float64, 10, 10)
        blackStartEnd = zeros(Float64, 10, 10, 10, 10)
        blackArrow = zeros(Float64, 10, 10)
        return DistributedMoveHistory(whiteStartEnd, whiteArrow, blackStartEnd, blackArrow)
    end

    function getMoveScore(hist::DistributedMoveHistory, m::Move, colourOfMover::Int)
        if colourOfMover == WHITE.val
            return hist.whiteStartEnd[m.sR, m.sC, m.eR, m.eC] +
                    hist.whiteArrow[m.aR, m.aC]
        elseif colourOfMover == BLACK.val
            return hist.blackStartEnd[m.sR, m.sC, m.eR, m.eC] +
                    hist.blackArrow[m.aR, m.aC]
        else
            throw(DomainError("colourOfMover == $colourOfMover, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end

    function updateMoveScore(hist::DistributedMoveHistory, m::Move, colourOfMover::Int, nodeDepth::Int, maxDepth::Int)
        score = 2^(maxDepth-nodeDepth)
        if colourOfMover == WHITE.val
            hist.whiteStartEnd[m.sR, m.sC, m.eR, m.eC] += score
            hist.whiteArrow[m.aR, m.aC] += score
        elseif colourOfMover == BLACK.val
            hist.blackStartEnd[m.sR, m.sC, m.eR, m.eC] += score
            hist.blackArrow[ m.aR, m.aC] += score
        else
            throw(DomainError("colourOfMover == $colourOfMover, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end

    function divideAllScores(hist::DistributedMoveHistory, divisor::Float64 = 2.0)
        @sync begin
            @async hist.whiteStartEnd .= hist.whiteStartEnd ./divisor
            @async hist.whiteArrow .= hist.whiteArrow ./divisor
            @async hist.blackStartEnd .= hist.blackStartEnd ./divisor
            @async hist.blackArrow .= hist.blackArrow ./divisor
        end

        return true
    end

    #Returns a sorted array of Tuple{score::Float64, Move}
    function orderMoves(hist::DistributedMoveHistory, moves::Array{Move,1}, colourOfMover::Int)
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
    =#
end
