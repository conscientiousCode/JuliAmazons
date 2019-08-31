module Board

    export BoardState, Move, moveVectors, Piece, EMPTY, ARROW, BLACK, WHITE, getMoves, applyMove, reverseMove


    struct Piece
        val::Int
    end
    ##Board Constants
    EMPTY = Piece(0);
    ARROW = Piece(1);
    WHITE = Piece(2);
    BLACK = Piece(3);

    function oppositeColourValue(colour::Int)
        if colour == WHITE.val
            return BLACK.val
        elseif colour == BLACK.val
            return WHITE.val
        else
            throw(DomainError("No piece of colour specified"))
        end
    end

    ##Movement vectors
    moveVectors = [[alpha.*(r,c) for alpha in 1:9] for r in -1:1 for c in -1:1 if r !=0 || c!= 0 ]

    #Note that the row hashes technicaly store the game in a column mirrored game
    struct BoardState
        board::Array{Int, 2};
        rowHashes::Array{Int, 1};
        whiteLocations::Array{Tuple{Int, Int}, 1};
        blackLocations::Array{Tuple{Int, Int}, 1};
    end

    struct Move
        #(startRow, startCol, endRow, endCol, arrowRow, arrowCol)
        sR::Int
        sC::Int
        eR::Int
        eC::Int
        aR::Int
        aC::Int
    end

    #Standard Layout of 10x10 board
    #RowxColumn format
    function DefaultBoard()::BoardState
        whiteLocs = [(4, 1); (1, 4); (1, 7); (4, 10)];
        blackLocs = [(7, 1); (10, 4); (10, 7); (7, 10)];
        rowHashes = [
        Int(0b00000010000010000000),
        Int(0b0),
        Int(0b0),
        Int(0b10000000000000000010),
        Int(0b0),
        Int(0b0),
        Int(0b11000000000000000011),
        Int(0b0),
        Int(0b0),
        Int(0b00000011000011000000)
        ];
        b = BoardState(zeros(Int,10,10), rowHashes, whiteLocs, blackLocs);
        b.board[4,1] = WHITE.val;
        b.board[1,4] = WHITE.val;
        b.board[1,7] = WHITE.val;
        b.board[4,10] = WHITE.val;

        b.board[7,1] = BLACK.val;
        b.board[10,4] = BLACK.val;
        b.board[10,7] = BLACK.val;
        b.board[7,10] = BLACK.val;

        return b;
    end

    #This function assumes the movement is valid
    function applyMove(b::BoardState, m::Move)
        colour = b.board[m.sR, m.sC];
        startLoc = (m.sR, m.sC)
        endLoc = (m.eR, m.eC)
        if colour == WHITE.val
            for i in 1:length(b.whiteLocations)
                if b.whiteLocations[i] == startLoc
                    b.whiteLocations[i] = endLoc
                    b.rowHashes[m.sR] = xor(b.rowHashes[m.sR], WHITE.val << ((m.sC-1)*2))
                    b.rowHashes[m.eR] = b.rowHashes[m.eR] | (WHITE.val << ((m.eC-1)*2))
                    b.rowHashes[m.aR] = b.rowHashes[m.aR] | (ARROW.val << ((m.aC-1)*2))
                end
            end
            #=
            if !(Base.allunique(b.whiteLocations))
                println("WHITE FORWARD: NOT ALL UNIQUE")
                println(whiteLocations)
                println(m)
            end
            =#
        elseif colour == BLACK.val
            for i in 1:length(b.blackLocations)
                if b.blackLocations[i] == startLoc
                    b.blackLocations[i] = endLoc
                    b.rowHashes[m.sR] = xor(b.rowHashes[m.sR], BLACK.val << ((m.sC-1)*2))
                    b.rowHashes[m.eR] = b.rowHashes[m.eR] | (BLACK.val << ((m.eC-1)*2))
                    b.rowHashes[m.aR] = b.rowHashes[m.aR] | (ARROW.val << ((m.aC-1)*2))
                end
            end
            #=
            if !(Base.allunique(b.blackLocations))
                println("BLACK FORWARD: NOT ALL UNIQUE")
                println(blackLocations)
                println(m)
            end
            =#
        else
            throw(DomainError("Expected start location colour to be 2 or 3, instead $colour"));
        end


        b.board[m.sR, m.sC] = EMPTY.val;
        b.board[m.eR, m.eC] = colour;
        b.board[m.aR, m.aC] = ARROW.val;
    end

    #If boardstate reached by move m, reverseMoves reverts to before m was applied
    function reverseMove(b::BoardState, m::Move)
        colour = b.board[m.eR, m.eC];
        startLoc = (m.sR, m.sC)
        endLoc = (m.eR, m.eC)
        if colour == WHITE.val
            for i in 1:length(b.whiteLocations)
                if b.whiteLocations[i] == endLoc
                    b.whiteLocations[i] = startLoc
                    b.rowHashes[m.aR] = xor(b.rowHashes[m.aR], ARROW.val << ((m.aC-1)*2))
                    b.rowHashes[m.eR] = xor(b.rowHashes[m.eR], WHITE.val << ((m.eC-1)*2))
                    b.rowHashes[m.sR] = b.rowHashes[m.sR] | (WHITE.val << ((m.sC-1)*2))
                end
            end
            #=
            if !(Base.allunique(b.whiteLocations))
                println("WHITE REVERSE: NOT ALL UNIQUE")
                println(whiteLocations)
                println(m)
            end
            =#
        elseif colour == BLACK.val
            for i in 1:length(b.blackLocations)
                if b.blackLocations[i] == endLoc
                    b.blackLocations[i] = startLoc
                    b.rowHashes[m.aR] = xor(b.rowHashes[m.aR], ARROW.val << ((m.aC-1)*2))
                    b.rowHashes[m.eR] = xor(b.rowHashes[m.eR], BLACK.val << ((m.eC-1)*2))
                    b.rowHashes[m.sR] = b.rowHashes[m.sR] | (BLACK.val << ((m.sC-1)*2))
                end
            end
            #=
            if !(Base.allunique(b.blackLocations))
                println("BLACK REVERSE: NOT ALL UNIQUE")
                println(blackLocations)
                println(m)
            end
            =#
        else
            throw(DomainError("Expected start location colour to be 2 or 3, instead $colour"));
        end

        b.board[m.aR, m.aC] = EMPTY.val;
        b.board[m.eR, m.eC] = EMPTY.val;
        b.board[m.sR, m.sC] = colour;
    end


    function Base.show(io::IO, b::BoardState)
        numRow = size(b.board, 1)
        numCol = size(b.board, 2)
        buff = IOBuffer()
        for i in 1:numRow
            for j in 1:numCol
                print(buff,"$(b.board[i,j]) ")
            end
            print(buff, '\n')
        end
        for i = 1:numCol
            print(buff,"- ")
        end
        print(io,String(take!(buff)))
    end

    function getMovesForPieceAt(b::BoardState, basePos::Tuple{Int,Int})
        rMin, rMax = 1, size(b.board,1)
        cMin, cMax = 1, size(b.board,2)
        movesGenerated = Array{Move, 1}()
        for moveVecDir in moveVectors
            for i in 1:9
                qPos = basePos .+ moveVecDir[i]
                if (rMin <= qPos[1] <= rMax
                    && cMin <= qPos[2] <= cMax
                    && b.board[qPos...] == EMPTY.val
                    )
                    for arrowVecDir in moveVectors
                        for j in 1:9
                            aPos = qPos .+ arrowVecDir[j]
                            if (rMin <= aPos[1] <= rMax
                                && cMin <= aPos[2] <= cMax
                                && (b.board[aPos...] == EMPTY.val || aPos == basePos)
                                )
                                push!(movesGenerated, Move(basePos[1], basePos[2], qPos[1], qPos[2], aPos[1], aPos[2]))
                            else
                                break #Cannot shoot futher in this direction
                            end
                        end
                    end
                else
                    break #Cannot move further in this direction
                end

            end
        end
        return movesGenerated
    end

    function getMoves(b::BoardState, colour::Int)
        moves = Array{Move,1}()
        if colour == WHITE.val
            for loc in b.whiteLocations
                append!(moves,getMovesForPieceAt(b,loc));
            end
            return moves
        elseif colour == BLACK.val
            for loc in b.blackLocations
                append!(moves, getMovesForPieceAt(b, loc));
            end
            return moves
        else
            throw(DomainError("Colour should be in {$(BLACK.val), $(WHITE.val)}. Instead colour = $colour."))
        end

    end

    function copy(b::BoardState)
        board = Base.copy(b.board)
        #rowHashes = copy(b.rowHashes)
        return BoardState(Base.copy(b.board),
                Base.copy(b.rowHashes),
                Base.copy(b.whiteLocations),
                Base.copy(b.blackLocations)
        )
    end
end

#=
printhash = (x) -> for n in x println(string(n, base = 2)) end
b = Board.DefaultBoard()
println(b.rowHashes)
#printhash(b.rowHashes)
println(string(b.rowHashes[1], base = 2))
m = Board.Move(1,4, 6,4, 6,2)
Board.applyMove(b,m)
println(b.rowHashes)
#printhash(b.rowHashes)
println(string(b.rowHashes[1], base = 2))
Board.reverseMove(b,m)
println(b.rowHashes)
#printhash(b.rowHashes)
println(string(b.rowHashes[1], base = 2))
println([string(x, base = 2) for x in b.rowHashes])
=#
#=
b = Board.DefaultBoard()
println(b)
@time begin
moves = Board.getMoves(b,2)
end
println(Board.moveVectors[1])
#for m in Board.moveVectors println(m) end
=#
