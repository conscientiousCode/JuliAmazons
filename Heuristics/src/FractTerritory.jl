module FractTerritory

    using Board
    using DataStructures

    export getTerritoryScore

    equivalentScoreBias = 0.5

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

    function getTerritoryScore(b::BoardState, maxPlayerColour::Int)
        whiteScores = 1 ./ getDistances(b,b.whiteLocations)
        blackScores = 1 ./ getDistances(b,b.blackLocations)


        whiteScore = 0.0
        blackScore = 0.0
        for j = 1:size(b.board,2)
            for i = 1:size(b.board,1)
                if whiteScores[i,j] > 0 && blackScores[i,j] == 0 #do nothing
                    whiteScore += 1
                elseif blackScores[i,j] > 0 && whiteScores[i,j] == 0
                    blackScore += 1
                else #Either both 0 or non-zero, (I.E. Either both could reach the square or could not)
                    whiteScore += whiteScores[i,j]
                    blackScore += blackScores[i,j]
                end
            end
        end

        #println("Board eval: WHITE = $whiteScore, BLACK = $blackScore")
        if maxPlayerColour == WHITE.val
            return whiteScore/blackScore
        elseif maxPlayerColour == BLACK.val
            return blackScore/whiteScore
        else
            throw(DomainError("maxPlayerColour == $maxPlayerColour, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end

end
