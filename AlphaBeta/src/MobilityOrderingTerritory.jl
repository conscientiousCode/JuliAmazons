module MobilityOrderingTerritory
    using GameManager, GameManager.Players
    using Heuristics.Territory, Heuristics.Mobility
    using Board
    using Timers

    export turnNotifier

    bestFoundMoveDict = Dict{Player, Move}()

    mutable struct TrackedState
        b::BoardState
        p::Player
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

        state = TrackedState(b, player,  player.playerColour, 1, overseer.game.maxTimePerMove + time())
        while !(time()-state.timeOffset > 0)
            println("Player: $(player.playerColour): depth: $(state.maxDepth)")
            moves = getMoves(b, state.colour)
            alpha = -Inf
            v = -Inf
            if length(moves) != 0
                #Order the moves by their mobility scores descending
                moves = orderByMobilityScores(state.b, moves, state.colour)
                bestMoveFoundAtDepth = moves[1][2]
            else#Game over because
                throw(ErrorException("Game is over, no moves from this starting position for $(state.colour == WHITE.val ? "WHITE" : "BLACK")"))
            end
            moveNum = 1
            if state.maxDepth == 1
                println("Number of possible moves: $(length(moves))")
            end
            initialTime = time()
            for (score, m) in moves
                moveNum+=1
                if moveNum %50 == 1 && state.maxDepth > 1
                    println("Move number $moveNum considered")
                end
                if time()-state.timeOffset > 0
                    return
                end
                applyMove(state.b, m)
                v = min(state, 1, alpha, Inf)
                reverseMove(state.b, m)
                if alpha < v
                    alpha = v
                    bestMoveFoundAtDepth = m
                    println("Move and score: $((m, v))")
                end

            end
            bestFoundMoveDict[player] = bestMoveFoundAtDepth
            state.maxDepth += 1
        end
        #println("Interupt Flag isRaised")

    end

    function max(state::TrackedState, currentDepth::Int, alpha::Float64, beta::Float64)::Float64
        #println("maxNode Reached")

        if state.maxDepth == currentDepth
            boardValue = getTerritoryScore(state.b, state.colour, Board.oppositeColourValue(state.colour), 0.25)
            return boardValue
        end

        moves = getMoves(state.b, state.colour)
        if length(moves) == 0 #Max player lost, so utility is -Inf
            return -Inf
        else
            moves = orderByMobilityScores(state.b, moves, state.colour)
        end

        v = -Inf
        bestMove = moves[1]

        for (score, m) in moves
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
                return v
            end
            alpha = Base.max(alpha, v)
        end
        return v

    end

    function min(state::TrackedState, currentDepth::Int, alpha::Float64, beta::Float64)::Float64
        if state.maxDepth == currentDepth
            boardValue = getTerritoryScore(state.b, state.colour, state.colour, 0.25)
            return boardValue
        end

        minColour = Board.oppositeColourValue(state.colour)
        moves = getMoves(state.b, minColour)
        if length(moves) == 0 #min player lost, so utility is Inf
            return Inf
        else
            moves = orderByMobilityScores(state.b, moves, minColour)
        end
        v = Inf
        bestMove = moves[1]

        for (score, m) in moves
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
                return v
            end
            beta = Base.min(beta, v)
        end
        return v
    end

end#End Module
