
module Mobility
    using Board

    export MobilityData, getMobilityScore, orderByMobilityScores

    #Returns the total mobility of colour/total mobility of opposite colour
    function getMobilityScore(b::BoardState, colour::Int)
        rMin, rMax = 1, size(b.board,1)
        cMin, cMax = 1, size(b.board,2)
        whiteTotal = 0
        blackTotal = 0
        #White Count
        for basePos in b.whiteLocations
            for moveVecDir in moveVectors
                for i in 1:9
                    qPos = basePos .+ moveVecDir[i]
                    if (rMin <= qPos[1] <= rMax
                        && cMin <= qPos[2] <= cMax
                        && b.board[qPos[1], qPos[2]] == EMPTY.val
                        )
                        whiteTotal += 1
                    else
                        break #Cannot move further in this direction
                    end
                end
            end
        end

        #Black Count
        for basePos in b.blackLocations
            for moveVecDir in moveVectors
                for i in 1:9
                    qPos = basePos .+ moveVecDir[i]
                    if (rMin <= qPos[1] <= rMax
                        && cMin <= qPos[2] <= cMax
                        && b.board[qPos[1], qPos[2]] == EMPTY.val
                        )
                        blackTotal += 1
                    else
                        break #Cannot move further in this direction
                    end
                end
            end
        end
        if colour == WHITE.val
            return whiteTotal/blackTotal
        elseif colour == BLACK.val
            return blackTotal/whiteTotal
        else
            throw(DomainError("colour == $colour, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
    end

    function orderByMobilityScores(b::BoardState, moves::Array{Move, 1}, colour::Int)
        movesWithScores = Array{Tuple{Float64, Move},1}(undef, length(moves))
        if !(colour == WHITE.val || colour == BLACK.val)
            throw(DomainError("colourOfMover == $colour, expected colour in {$(WHITE.val),$(BLACK.val)}"))
        end
        for i = 1:length(moves)
            m = moves[i]
            Board.applyMove(b, m)
            movesWithScores[i] =  (getMobilityScore(b, colour), m)
            Board.reverseMove(b, m)
        end
        return sort!(movesWithScores, by=moveOrdering, rev=true)
    end

    function moveOrdering(tup::Tuple{Float64, Move})
        return tup[1]
    end

    #=
    function getValueAfterMove(b::BoardState, m::Move, colour::Int)
        Board.applyMove(b, m)
        val = getMobility(b, colour)
        Board.reverseMove(b, m)
        return val
    end

    function generateMobilityData(b::BoardState)
        rMin, rMax = 1, size(b.board,1)
        cMin, cMax = 1, size(b.board,2)
        mobScores = zeros(Int, rMax, cMax)
        whiteTotal = 0
        blackTotal = 0
        #White Counts
        for p = 1:size(b.whiteLocations,1)
            count = 0
            basePos = (b.whiteLocations[p,1],b.whiteLocations[p,2])
            for moveVecDir in moveVectors
                for i in 1:9
                    qPos = basePos .+ moveVecDir[i]
                    if (rMin <= qPos[1] <= rMax
                        && cMin <= qPos[2] <= cMax
                        && b.board[qPos[1], qPos[2]] == EMPTY.val
                        )
                        count += 1
                    else
                        break #Cannot move further in this direction
                    end
                end
            end
            whiteTotal += count
            mobScores[basePos...] = count
        end

        #Black Counts
        for p = 1:size(b.blackLocations,1)
            basePos = (b.blackLocations[p,1],b.blackLocations[p,2])
            count = 0
            for moveVecDir in moveVectors
                for i in 1:9
                    qPos = basePos .+ moveVecDir[i]
                    if (rMin <= qPos[1] <= rMax
                        && cMin <= qPos[2] <= cMax
                        && b.board[qPos[1], qPos[2]] == EMPTY.val
                        )
                        count += 1
                    else
                        break #Cannot move further in this direction
                    end
                end
            end
            blackTotal += count
            mobScores[basePos...] = count
        end
        return MobilityData(mobScores, whiteTotal, blackTotal)
    end

    #Destroys the data  in mD, but does not allocate new space
    function generateMobilityDataReuseSpace(b::BoardState, mD::MobilityData)
        rMin, rMax = 1, size(b.board,1)
        cMin, cMax = 1, size(b.board,2)
        for j =  1:size(mD.mobility,2)
            for i =  1:size(mD.mobility,1)
                mD.mobility[i,j] = 0
            end
        end
        mD.whiteTotal = 0
        mD.blackTotal = 0
        #White Counts
        for p = 1:size(b.whiteLocations,1)
            count = 0
            basePos = (b.whiteLocations[p,1],b.whiteLocations[p,2])
            for moveVecDir in moveVectors
                for i in 1:9
                    qPos = basePos .+ moveVecDir[i]
                    if (rMin <= qPos[1] <= rMax
                        && cMin <= qPos[2] <= cMax
                        && b.board[qPos[1], qPos[2]] == EMPTY.val
                        )
                        count += 1
                    else
                        break #Cannot move further in this direction
                    end
                end
            end
            whiteTotal += count
            mD.mobility[basePos...] = count
        end

        #Black Counts
        for p = 1:size(b.blackLocations,1)
            basePos = (b.blackLocations[p,1],b.blackLocations[p,2])
            count = 0
            for moveVecDir in moveVectors
                for i in 1:9
                    qPos = basePos .+ moveVecDir[i]
                    if (rMin <= qPos[1] <= rMax
                        && cMin <= qPos[2] <= cMax
                        && b.board[qPos[1], qPos[2]] == EMPTY.val
                        )
                        count += 1
                    else
                        break #Cannot move further in this direction
                    end
                end
            end
            blackTotal += count
            mD.mobility[basePos...] = count
        end
        return mD
    end

    function copyMobilityDataFromTo(from::MobilityData, to::MobilityData)
        to.whiteTotal = from.whiteTotal
        to.blackTotal = from.blackTotal
        for j =  1:size(to.mobility,2)
            for i =  1:size(to.mobility,1)
                to.mobility[i,j] = from.mobility[i,j]
            end
        end
    end

    function getPieceMobility(b::BoardState, r::Int, c::Int)
        rMin, rMax = 1, size(b.board,1)
        cMin, cMax = 1, size(b.board,2)
        count = 0
        basePos = (r,c)
        for moveVecDir in moveVectors
            for i in 1:9
                qPos = basePos .+ moveVecDir[i]
                if (rMin <= qPos[1] <= rMax
                    && cMin <= qPos[2] <= cMax
                    && b.board[qPos[1], qPos[2]] == EMPTY.val
                    )
                    count += 1
                else
                    break #Cannot move further in this direction
                end
            end
        end
        return count
    end

    #To be used after a BoardState has had a moved m applied to it
    #DOES NOT UPDATE mD
    #Undefined behaviour if BoardState not in this state or mD has not been kept up to date
    function mobilityScoreFromData(b::BoardState, m::Move, mD::MobilityData)
        newVal = getPieceMobility(b, m.eR, m.eC)
        if b.board[m.eR, m.eC] == WHITE.val
            return (mD.whiteTotal + (newVal - mD.mobility[m.sR, m.sC]))/mD.blackTotal
        else
            return (mD.blackTotal + (newVal - mD.mobility[m.sR, m.sC]))/mD.whiteTotal
        end
    end

    #To be used after a BoardState has had a moved m applied to it
    #Updates mobilityData, but is invariant to repeated application
    #Undefined behaviour if BoardState not in this state or mD has not been kept up to date
    function mobilityScoreWithUpdate(b::BoardState, m::Move, mD::MobilityData)
        prevVal = mD.mobility[m.sR, m.sC]
        mD.mobility[m.sR, m.sC] = 0
        mD.mobility[m.eR, m.eC] = getPieceMobility(b, m.eR, m.eC)
        if b.board[m.eR, m.eC] == WHITE.val
            mD.whiteTotal = mD.whiteTotal + (mD.mobility[m.eR, m.eC] - prevVal)
            return mD.whiteTotal/mD.blackTotal
        else
            mD.blackTotal = mD.blackTotal + (mD.mobility[m.eR, m.eC] - prevVal)
            return mD.blackTotal/mD.whiteTotal
        end
    end

    #To be applied after move m has been reverted on b
    #updates mD
    function mobilityScoreReverseUpdate(b::BoardState, m::Move, mD::MobilityData)
        v = mD.mobility[m.eR, m.eC]
        mD.mobility[m.eR, m.eC] = 0
        mD.mobility[m.sR, m.sC] = getPieceMobility(b, m.sR, m.sC)
        if b.board[m.sR, m.sC] == WHITE.val
            mD.whiteTotal = mD.whiteTotal + (mD.mobility[m.sR, m.sC] - v)
            return mD.whiteTotal/mD.blackTotal
        else
            mD.blackTotal = mD.blackTotal + (mD.mobility[m.sR, m.sC] - v)
            return mD.blackTotal/mD.whiteTotal
        end
    end
    =#
    #=
    b = Board.DefaultBoard()
    mD = generateMobilityData(b)
    m = Move(1,4, 6,4, 6, 2)
    Board.applyMove(b, m)
    println(b)
    score1 = mobilityScoreFromData(b, m, mD)
    println(mD.whiteTotal)
    println(score1)
    score2 = mobilityScoreWithUpdate(b, m, mD)
    println(mD.whiteTotal)
    println(score2)
    Board.reverseMove(b,m)
    score3 = mobilityScoreReverseUpdate(b,m,mD)
    println(mD.whiteTotal)
    println(score3)
    =#
end
