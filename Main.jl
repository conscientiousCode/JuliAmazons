ROOT_PATH = @__DIR__
if !(ROOT_PATH in LOAD_PATH)
    push!(LOAD_PATH, ROOT_PATH)
end

using Board
using GameManager, GameManager.GameState, GameManager.Players
using Timers
using AlphaBeta.HistoryTransposition, AlphaBeta.BasicAlphaBeta, AlphaBeta.MobilityOrderingTerritory
using AlphaBeta.HTWithMobilityPreference, AlphaBeta.DistHTMob, AlphaBeta.HTMobFractTerritory

function main()
    turnTime = 30.0
    game = newGame(turnTime)
    #=
    whitePlayer = Player(WHITE.val, turnTime, HistoryTransposition.turnNotifier)
    blackPlayer = Player(BLACK.val, turnTime, MobilityOrderingTerritory.turnNotifier)
    =#
    #=
    whitePlayer = Player(WHITE.val, turnTime, MobilityOrderingTerritory.turnNotifier)
    blackPlayer = Player(BLACK.val, turnTime, HistoryTransposition.turnNotifier)
    =#

    #= Black wins strongly, but it was a close middle game
    whitePlayer = Player(WHITE.val, turnTime, HTWithMobilityPreference.turnNotifier)
    blackPlayer = Player(BLACK.val, turnTime, MobilityOrderingTerritory.turnNotifier)
    =#

    #=# HTWithMobilityPreference Slaughters MobilityOrderingTerritory
    whitePlayer = Player(WHITE.val, turnTime, MobilityOrderingTerritory.turnNotifier)
    blackPlayer = Player(BLACK.val, turnTime, HTWithMobilityPreference.turnNotifier)
    =#

    #= Dist == black => Dist Win
    whitePlayer = Player(WHITE.val, turnTime, DistHTMob.turnNotifier)
    blackPlayer = Player(BLACK.val, turnTime, HTWithMobilityPreference.turnNotifier)
    =#

    ##=#
    whitePlayer = Player(WHITE.val, turnTime, HTMobFractTerritory.turnNotifier)
    blackPlayer = Player(BLACK.val, turnTime, MobilityOrderingTerritory.turnNotifier)
    ##=#


    overseer = GameOverseer(game, whitePlayer, blackPlayer)
    println("Game Starting: Turn 0 Complete")
    println(game.masterBoard)
    while overseer.game.playerThatWon == nothing
        if 0 == length(Board.getMoves(overseer.game.masterBoard, overseer.game.currentPlayerTurn.val))
            overseer.game.playerThatWon = overseer.game.currentPlayerTurn == WHITE ? BLACK : WHITE
            continue
        end
        GameManager.startNewTurn(overseer)
    end

    println("Player: $(overseer.game.playerThatWon == WHITE ? "WHITE" : "BLACK") won!!!")
    println(overseer.game.moveHistory)
end

main()
