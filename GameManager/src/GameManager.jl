module GameManager
    using Board
    using Timers
    using DataStructures
    #using .GameState

    module GameState
        using Board
        export Game, newGame, checkSpacesClear

        mutable struct Game
            masterBoard::BoardState
            currentPlayerTurn::Piece
            turnNumber::Int
            moveHistory::Array{Move,1}
            maxTimePerMove::Float64
            playerThatWon
        end

        function newGame(time::Float64)
            return Game(
                Board.DefaultBoard(),
                WHITE,
                1,
                Array{Move,1}(),
                time, #30 seconds,
                nothing
            )
        end

        #Not to be passed to either player in a match, meant to ensure no spoofed moves by the opponent

        function getDirectionVector(sR::Int, sC::Int, eR::Int, eC::Int)
            r = eR - sR
            c = eC - sC
            #println("(r,c) before: $((r,c))")
            if r > 0
                r = 1
            elseif r < 0
                r = -1
            end
            if c > 0
                c = 1
            elseif c < 0
                c = -1
            end
            #println("(r,c) after: $((r,c))")
            return (r,c)
        end

        function checkSpacesClearMove(game::Game, startPos::Tuple{Int, Int}, endPos::Tuple{Int, Int}, dir::Tuple{Int, Int})
            #println("DIR: $dir")
            currentPos = startPos .+ dir
            while currentPos[1] != endPos[1] && currentPos[2] != endPos[2]
                if game.masterBoard.board[currentPos...] != EMPTY.val
                        println("Position not empty: $currentPos, Value: $(game.masterBoard.board[currentPos...])")
                    return false
                end
                currentPos = currentPos .+ dir
            end
            return true
        end

        function checkSpacesClearArrow(game::Game, startPos::Tuple{Int, Int}, endPos::Tuple{Int, Int}, ignoreSpace::Tuple{Int, Int}, dir::Tuple{Int, Int})
            #println("DIR: $dir")
            currentPos = startPos .+ dir
            while currentPos[1] != endPos[1] && currentPos[2] != endPos[2]
                if currentPos[1] == ignoreSpace[1] && currentPos[2] == ignoreSpace[2]
                    currentPos = currentPos .+ dir
                    continue
                end
                if game.masterBoard.board[currentPos...] != EMPTY.val
                        println("Position not empty: $currentPos, Value: $(game.masterBoard.board[currentPos...])")
                    return false
                end
                currentPos = currentPos .+ dir
            end
            return true
        end

        function playMove(game::Game, m::Move)
            moveDir = getDirectionVector(m.sR, m.sC, m.eR, m.eC)
            arrowDir = getDirectionVector(m.eR, m.eC, m.aR, m.aC)

            if game.masterBoard.board[m.sR, m.sC] == EMPTY.val ||  game.masterBoard.board[m.sR, m.sC] == ARROW.val
                println("No piece at location requested by player : $(game.currentPlayerTurn == WHITE ? "WHITE" : "BLACK")")
            end

            println("Move: $m")

            if !(
                checkSpacesClearMove(game, (m.sR, m.sC), (m.eR, m.eC), moveDir)
                && checkSpacesClearArrow(game, (m.eR, m.eC), (m.aR, m.aC), (m.sR, m.sC) ,arrowDir)
            )
                if (game.currentPlayerTurn == WHITE)
                    println("Invalid move by WHITE")
                    game.playerThatWon = BLACK
                else
                    println("Invalid move by BLACK")
                    game.playerThatWon = WHITE
                end
                return false
            end

            #All clear to proceed with updating
            Board.applyMove(game.masterBoard, m)
            game.turnNumber += 1
            push!(game.moveHistory, m)
            #Toggle player turn
            game.currentPlayerTurn = game.currentPlayerTurn == WHITE ? BLACK : WHITE
            return true
        end
    end #end module

    module Players

        export Player, newPlayer

        #boardStateUpdater will be called with the most recent move after either player's move has been accepted
        #turnNotifier will let the player know that their turn has started
        struct Player
            playerColour::Int
            turnTime::Float64
            turnNotifier# function (GameOverseer, BoardState copy, Player)
        end

    end#end Module

    using .Players
    using .GameState

    export GameOverseer, playersTimeUp
    #timer objects will be non-null while active, attempting to playMove() with a timer == nothing will not work
    mutable struct GameOverseer
        game::Game
        whitePlayer::Player
        blackPlayer::Player
    end


    function playMove(overseer::GameOverseer, m::Move, player::Player)::Bool
        if player.playerColour != overseer.game.currentPlayerTurn.val
            println("Attempted to move when not thier turn player: $player.playerColour")
            return
        end

        GameState.playMove(overseer.game, m)
        println("TURN # COMPLETE: $(overseer.game.turnNumber -1)")
        println(overseer.game.masterBoard)
        return true
    end

    function playersTimeUp(overseer::GameOverseer, player::Player, turnNumberTimerStarted::Int)
        if overseer.game.turnNumber == turnNumberTimerStarted
            overseer.game.playerThatWon = player.colour == WHITE.val ? BLACK : WHITE
            print("$(overseer.playerThatWon) Won!!!")
        end
    end

    function startNewTurn(overseer::GameOverseer)
        turnTime = overseer.game.maxTimePerMove
        if overseer.game.turnNumber % 2 == 1 #white turn
            println("GameManager starting Timer for $(overseer.whitePlayer.playerColour)")
            overseer.whitePlayer.turnNotifier(overseer, Board.copy(overseer.game.masterBoard), overseer.whitePlayer)
            #overseer.whiteTurnTimer = SplatTimer(turnTime, (overseer, overseer.whitePlayer, overseer.game.turnNumber), GameManager.playersTimeUp)
            #@async startTimer(overseer.whiteTurnTimer)
        else #black turn
            println("GameManager starting Timer for $(overseer.blackPlayer.playerColour)")
            overseer.blackPlayer.turnNotifier(overseer, Board.copy(overseer.game.masterBoard), overseer.blackPlayer)
            #overseer.blackTurnTimer = SplatTimer(turnTime, (overseer, overseer.blackPlayer, overseer.game.turnNumber), GameOverseer.playersTimeUp)
            #@async startTimer(overseer.blackTurnTimer)
        end

    end

end
