module HTWithMobilityPreference
    using GameManager, GameManager.Players
    using Heuristics.History, Heuristics.Transposition, Heuristics.Territory, Heuristics.Mobility
    using Board
    using Timers

    export turnNotifier

    bestFoundMoveDict = Dict{Player, Move}()
    historyRefenceStorage = Dict{Player, MoveHistory}()

    mutable struct TrackedState
        b::BoardState
        p::Player
        transTable::TranspositionTable
        history::MoveHistory
        colour::Int
        maxDepth::Int
        timeOffset::Float64
    end

    #Part of the api for player
    #Should begin the search
    function turnNotifier(overseer::GameOverseer, b::BoardState, player::Player)
        println("player $(player.playerColour) notified!")
        #println("Waiting for search")
        iterativeDeepening(overseer, b, player)
        #Play the best move found
        #println("Playing best move found")
        GameManager.playMove(overseer, bestFoundMoveDict[player], player)
    end

    #Root acts like a max node
    function iterativeDeepening(overseer::GameOverseer,b::BoardState, player::Player)
        moveHist = haskey(historyRefenceStorage, player) ? historyRefenceStorage[player] : initializeMoveHistory()

        state = TrackedState(b, player, generateTranspositionTable(), moveHist, player.playerColour, 1, overseer.game.maxTimePerMove + time())
        while !(time()-state.timeOffset > 0)
            println("Player: $(player.playerColour): depth: $(state.maxDepth)")
            movesWithScores = orderMoves(state.history, getMoves(b, state.colour), state.colour)
            alpha = -Inf
            if length(movesWithScores) != 0
                bestMoveFoundAtDepth = movesWithScores[1][2]#(score,m)[2]
            else#Game over because
                throw(ErrorException("Game is over, no moves from this starting position for $(state.colour == WHITE.val ? "WHITE" : "BLACK")"))
            end
            moveNum = 1
            if state.maxDepth == 1
                println("Number of possible moves: $(length(movesWithScores))")
            end
            for (score,m) in movesWithScores
                moveNum+=1
                if moveNum %50 == 1 && state.maxDepth > 1
                    println("Move number $moveNum considered")
                end
                if time()-state.timeOffset > 0
                    return
                end
                applyMove(state.b, m)
                moveScore = min(state, 1, alpha, Inf)
                if alpha <= moveScore
                    if alpha < moveScore
                        reverseMove(state.b, m)
                        alpha = moveScore
                        bestMoveFoundAtDepth = m
                        println("Move and score: $((m, moveScore))")
                    else #Equivalent, alpha == movescore, Try to prefer the more mobile one
                        candidateMobility = getMobilityScore(state.b, state.colour)
                        reverseMove(state.b, m)
                        applyMove(state.b, bestMoveFoundAtDepth)
                        incumbentMobility = getMobilityScore(state.b, state.colour)
                        reverseMove(state.b, bestMoveFoundAtDepth)
                        #Sort by least mobile?
                        if candidateMobility > incumbentMobility
                            alpha = moveScore
                            bestMoveFoundAtDepth = m
                        end
                        println("Move and score: $((m, moveScore)): incumbentMobility = $incumbentMobility : candidateMobility  = $candidateMobility")
                    end
                else
                    reverseMove(state.b, m)
                end

            end
            bestFoundMoveDict[player] = bestMoveFoundAtDepth
            updateMoveScore(state.history, bestMoveFoundAtDepth, state.colour, 1, state.maxDepth)
            divideAllScores(state.history)
            state.transTable = generateTranspositionTable()
            state.maxDepth += 1
            if alpha == Inf || alpha == -Inf
                println("Saw the end of the Game: Our score = $alpha")
                break
            end
        end
        #println("Interupt Flag isRaised")

    end

    function max(state::TrackedState, currentDepth::Int, alpha::Float64, beta::Float64)::Float64
        #println("maxNode Reached")
        if hasEntry(state.transTable, state.b)
            value = getValue(state.transTable, state.b)
            if state.maxDepth == currentDepth #Is the correct value
                return value
            elseif value >= beta #board state depth unique, so sufficient for cutoff attempt
                return value
            else #This might be the case anyways? Will narrow window
                alpha = Base.max(alpha, value)
            end
        end
        if state.maxDepth == currentDepth
            boardValue = getTerritoryScore(state.b, state.colour, Board.oppositeColourValue(state.colour), 0.25)
            setValue(state.transTable, state.b, boardValue)
            return boardValue
        end

        orderedMoves = orderMoves(state.history, getMoves(state.b, state.colour), state.colour)
        if length(orderedMoves) == 0 #Max player lost, so utility is -Inf
            return -Inf
        end
        v = -Inf
        bestMove = orderedMoves[1][2]

        for (histScore, m) in orderedMoves
            if time()-state.timeOffset > 0
                return v
            end
            applyMove(state.b, m)
            moveScore = min(state, currentDepth + 1, alpha, beta)
            reverseMove(state.b, m)

            if v < moveScore #v = max(v, movescore)
                v = moveScore
                bestMove = m
            end
            if v >= beta
                setValue(state.transTable, state.b, v)
                updateMoveScore(state.history, bestMove, state.colour, currentDepth, state.maxDepth)
                return v
            end
            alpha = Base.max(alpha, v)
        end
        setValue(state.transTable, state.b, v)
        updateMoveScore(state.history, bestMove, state.colour, currentDepth, state.maxDepth)
        return v

    end

    function min(state::TrackedState, currentDepth::Int, alpha::Float64, beta::Float64)::Float64
        if hasEntry(state.transTable, state.b)
            value = getValue(state.transTable, state.b)
            if state.maxDepth == currentDepth #Is the correct value
                return value
            elseif value <= alpha #board state depth unique, so sufficient for cutoff attempt
                return value
            else #This might be the case anyways? Will narrow window
                beta = Base.min(beta, value)
            end
        end
        if state.maxDepth == currentDepth
            boardValue = getTerritoryScore(state.b, state.colour, state.colour, 0.25)
            setValue(state.transTable, state.b, boardValue)
            return boardValue
        end

        minColour = Board.oppositeColourValue(state.colour)
        orderedMoves = orderMoves(state.history, getMoves(state.b, minColour), minColour)
        if length(orderedMoves) == 0 #Min player lost, so utility is Inf
            return Inf
        end
        v = Inf
        bestMove = orderedMoves[1][2]

        for (histScore, m) in orderedMoves
            if time()-state.timeOffset > 0
                return v
            end
            applyMove(state.b, m)
            moveScore = max(state, currentDepth + 1, alpha, beta)
            reverseMove(state.b, m)

            if v > moveScore #v = max(v, movescore)
                v = moveScore
                bestMove = m
            end
            if v <= alpha
                setValue(state.transTable, state.b, v)
                updateMoveScore(state.history, bestMove, minColour, currentDepth, state.maxDepth)
                return v
            end
            beta = Base.min(beta, v)
        end
        setValue(state.transTable, state.b, v)
        updateMoveScore(state.history, bestMove, minColour, currentDepth, state.maxDepth)
        return v
    end

end#End Module
