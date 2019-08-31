module Territory

    using Board
    using DataStructures

    export getTerritoryScore

    equivalentScoreBias = 0.5
    #=
    struct TerritoryData
        fixedColour::Int
        unfixedColour::Int
        fixedDistances::Array{Int,2}
        #partialMutableDistances::Dict{Tuple{Int,Int},Array{Int,2}} #Piece at key is ignored when generating distances
    end

    function generateTerritoryData(b::BoardState, fixedPlayerColour::Int)
        if fixedPlayerColour == WHITE.val
            fixedDistances = getDistancesIgnoreOtherColour(b::BoardState, b.whiteLocations)
            unfixedPieces = b.blackLocations
            unfixedColour = BLACK.val
        elseif fixedPlayerColour == BLACK.val
            fixedDistances = getDistancesIgnoreOtherColour(b::BoardState, b.blackLocations)
            unfixedPieces = b.whiteLocations
            unfixedColour = WHITE.val
        else
            throw(DomainError("fixedPlayerColour is not a recognized colour: colour == $fixedPlayerColour"))
        end
        return TerritoryData(fixedPlayerColour, unfixedColour, fixedDistances)
        #= TRASH
        singlePieceDistances = Array{Array{Int, 2},1}(undef, size(unfixedPieces, 1))
        for i = 1:size(unfixedPieces, 1)
            singlePieceDistances[i] = getSinglePieceDistancesIgnoreFellows(b, unfixedPieces[i,1], unfixedPieces[i,2], unfixedColour)
        end
        #Combine into groups of pieces ignoring 1 piece so that it is "free"
        unfixedCurrentIndexIgnored = Array{Array{Int, 2},1}(undef, size(unfixedPieces, 1))
        for i = 1:size(singlePieceDistances,1)
            combinedDistances = (i == 1) ? copy(singlePieceDistances[2]) : copy(singlePieceDistances[1])
            for j = 2:length(singlePieceDistances) #Can ignore 1 because covered above
                if j == i
                    break
                elseif i == 1 && j == 2 #Skip because already copied
                    break
                else
                    for q = 1:size(combinedDistances,2)
                        for p = 1:size(combinedDistances,1)
                            if combinedDistances[p,q] > singlePieceDistances[j][p,q]
                                combinedDistances[p,q] = singlePieceDistances[j][p,q]
                            end
                        end
                    end
                end

            end
            unfixedCurrentIndexIgnored[i] = combinedDistances
        end
        partialMutableDistances = Dict{Tuple{Int,Int},Array{Int,2}}()
        for i = 1:size(unfixedPieces, 1)
            partialMutableDistances[(unfixedPieces[i,1], unfixedPieces[i,2])] = unfixedCurrentIndexIgnored[i]
        end
        return TerritoryData(fixedPlayerColour, fixedDistances, partialMutableDistances)
        =#
    end
    =#
    function getDistances(b::BoardState, pieceLocations::Array{Tuple{Int,Int}, 1})
        rMin, rMax = 1, size(b.board,1)
        cMin, cMax = 1, size(b.board,2)
        q = Queue{Tuple{Tuple{Int, Int}, Int}}()
        for pLoc in pieceLocations
            enqueue!(q,(pLoc,0))
        end
        distances = Array{Float64, 2}(undef, 10, 10)
        distances .= Inf
        while length(q) > 0
            t = dequeue!(q)
            dist = t[2] + 1
            basePos = t[1]
            for moveVecDir in moveVectors
                for i in 1:9
                    qPos = basePos .+ moveVecDir[i]
                    if (rMin <= qPos[1] <= rMax
                        && cMin <= qPos[2] <= cMax
                        && b.board[qPos[1], qPos[2]] == EMPTY.val
                        && distances[qPos...] == Inf
                        )
                            distances[qPos...] = dist
                            enqueue!(q,(qPos, dist))
                    else
                        break #Cannot move further in this direction
                    end
                end
            end
        end
        return distances
    end
#=
    #Probably useless now... I was being stupid
    function getDistancesIgnoreOtherColour(b::BoardState, pieceLocations::Array{Int, 2})
        oppColour = b.boardstate[pieceLocations[1,1], pieceLocations[1,2]] == WHITE.val ? BLACK.val : WHITE.val
        rMin, rMax = 1, size(b.board,1)
        cMin, cMax = 1, size(b.board,2)
        q = Queue{Tuple{Int, Int, Int}}()
        for i = 1:size(pieceLocations,1)
            enqueue!(q,(pieceLocations[1],pieceLocations[2],0))
        end
        distances = zeros(Int, rMax, cMax)
        while length(q) > 0
            t = dequeue!(q)
            dist = t[3] + 1
            basePos = (t[1], t[2])
            for moveVecDir in moveVectors
                for i in 1:9
                    qPos = basePos .+ moveVecDir[i]
                    if (rMin <= qPos[1] <= rMax
                        && cMin <= qPos[2] <= cMax
                        && (
                            b.board[qPos[1], qPos[2]] == EMPTY.val
                            || b.board[qPos[1], qPos[2]] == oppColour
                            )
                        )
                        if distances[qPos...] == 0
                            distances[qPos...] = dist
                            enqueue!(q,(qPos..., dist))
                        end
                    else
                        break #Cannot move further in this direction
                    end
                end
            end
        end
        return distances
    end
=#
    function getTerritoryScore(b::BoardState, maxPlayerColour::Int, nextToMoveColour::Int, equivalentDistBias::Float64 = 0.0)
        whiteScores = getDistances(b,b.whiteLocations)
        blackScores = getDistances(b,b.blackLocations)

        whiteScore = 0
        blackScore = 0
        nextToMoveScoreBias = 0.0
        for j = 1:size(b.board,2)
            for i = 1:size(b.board,1)
                if whiteScores[i,j] < blackScores[i,j]
                    whiteScore += 1
                elseif whiteScores[i,j] > blackScores[i,j]
                    blackScore += 1
                elseif whiteScores[i,j] != Inf
                    nextToMoveScoreBias += equivalentDistBias
                end
            end
        end

        if nextToMoveColour == WHITE.val
            whiteScore += nextToMoveScoreBias
        elseif nextToMoveColour == BLACK.val
            blackScore += nextToMoveScoreBias
        else
            throw(DomainError("nextToMoveColour == $nextToMoveColour, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end

        #println("Board eval: WHITE = $whiteScore, BLACK = $blackScore")
        if maxPlayerColour == WHITE.val
            #=
            if  whiteScore/blackScore == Inf
                println("!!!!!INF OCCURED: WHITE DOMINANT: whiteScore = $whiteScore,     blackScore = $blackScore")
                println("WHITE: $whiteScores")
                println("BLACK: $blackScores")
                println("WHITE LOCATIONS: ")
                for i = 1:4
                    println(b.whiteLocations)
                end

                println("BLACK LOCATIONS: ")
                for i = 1:4
                    println(b.blackLocations)
                end
            end
            =#
            return whiteScore/blackScore
        elseif maxPlayerColour == BLACK.val
            #=
            if  blackScore/whiteScore == Inf
                println("!!!!!INF OCCURED: BLACK DOMINANT: whiteScore = $whiteScore,     blackScore = $blackScore")
                println("WHITE: $whiteScores")
                println("BLACK: $blackScores")
                println("WHITE LOCATIONS: ")
                for i = 1:4
                    println(b.whiteLocations)
                end

                println("BLACK LOCATIONS: ")
                for i = 1:4
                    println(b.blackLocations)
                end
            end
            =#
            return blackScore/whiteScore
        else
            throw(DomainError("maxPlayerColour == $maxPlayerColour, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end

#= TRASH
    function getSinglePieceDistancesIgnoreFellows(b::BoardState, r::Int, c::Int, ignoreColour::Int)
        rMin, rMax = 1, size(b.board,1)
        cMin, cMax = 1, size(b.board,2)
        q = Queue{Tuple{Int, Int, Int}}()
        enqueue!(q,(r,c,0))
        distances = zeros(Int, rMax, cMax)
        while length(q) > 0
            t = dequeue!(q)
            dist = t[3] + 1
            basePos = (t[1], t[2])
            for moveVecDir in moveVectors
                for i in 1:9
                    qPos = basePos .+ moveVecDir[i]
                    if (rMin <= qPos[1] <= rMax
                        && cMin <= qPos[2] <= cMax
                        && (
                            b.board[qPos[1], qPos[2]] == EMPTY.val
                            || (
                                b.board[qPos[1], qPos[2]] == ignoreColour
                                && qPos != (r,c)
                                )
                            )
                        )
                        if distances[qPos...] == 0
                            distances[qPos...] = dist
                            enqueue!(q,(qPos..., dist))
                        end
                    else
                        break #Cannot move further in this direction
                    end
                end
            end
        end
        return distances
    end
    =#
    #=
    function getScoreFromData(b::BoardState, td::TerritoryData, allyColour::Int)

        unfixedDistances = getDistances(b, td.unfixedColour)
        #Ensure that spaces occupied by unfixed pieces now are not counted
        if td.fixedColour == WHITE.val
            tempVals = [(b.whiteLocs[i,1], b.whiteLocs[i,2], b.board[b.whiteLocs[i,1], b.whiteLocs[i,2] for i = 1:size(b.whiteLocs,1)])]
        else
            tempVals = [(b.blackLocs[i,1], b.blackLocs[i,2], b.board[b.blackLocs[i,1], b.blackLocs[i,2] for i = 1:size(b.blackLocs,1)])]
        end
        for val in tempVals
            td.fixedDistances[val[1], val[2]] = 0
        end


        if allyColour == WHITE.val

        elseif allyColour == BLACK.val

        else
            throw(DomainError("allyColour == $allyColour, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end=#
    #=
    b = Board.DefaultBoard()
    println(Territory.getTerritoryScore(b, BLACK.val, BLACK.val, 1/8))
    =#
end
