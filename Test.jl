module Test
    struct TestStruct
        val
    end


    function f1()
        t1 = time()
        sleep(30)
        t2 = time()
        println((t2 - t1)/30.0)

    end

    function f2()
        whiteScores = [5.0 5.0 5.0 4.0 3.0 3.0 3.0 3.0 Inf 4.0; 6.0 6.0 5.0 Inf 3.0 3.0 3.0 2.0 3.0 3.0; 6.0 5.0 6.0 Inf 3.0 3.0 2.0 3.0 3.0 3.0; 5.0 6.0 6.0 Inf 3.0 2.0 3.0 Inf 3.0 Inf; 6.0 6.0 Inf Inf 2.0 Inf Inf Inf 2.0 3.0; 6.0 Inf Inf 1.0 1.0 Inf Inf 2.0 3.0 3.0; 6.0 6.0 Inf Inf 1.0 1.0 1.0 Inf 3.0 Inf; 5.0 Inf Inf Inf Inf 2.0 2.0 2.0 3.0 3.0; 4.0 4.0 4.0 4.0 3.0 3.0 2.0 2.0 2.0 3.0; 4.0 4.0 4.0 3.0 4.0 3.0 3.0 2.0 2.0 2.0]
        blackScores = [4.0 4.0 4.0 3.0 2.0 3.0 3.0 3.0 Inf 4.0; 5.0 5.0 4.0 Inf 2.0 3.0 3.0 2.0 3.0 3.0; 5.0 4.0 5.0 Inf 2.0 3.0 2.0 3.0 3.0 3.0; 4.0 5.0 5.0 Inf 2.0 2.0 3.0 Inf 3.0 Inf; 5.0 5.0 Inf Inf 1.0 Inf Inf Inf 2.0 3.0; 5.0 Inf Inf 1.0 1.0 Inf Inf 2.0 3.0 2.0; 5.0 5.0 Inf Inf 1.0 1.0 1.0 Inf 2.0 Inf; 4.0 Inf Inf Inf Inf 1.0 2.0 1.0 2.0 2.0; 3.0 3.0 3.0 3.0 2.0 1.0 2.0 2.0 1.0 2.0; 3.0 3.0 3.0 2.0 2.0 1.0 2.0 2.0 2.0 1.0]
        whiteLessBlack = whiteScores .< blackScores
        for i = 1:10
            print("$i: WHITE: ")
            for j = 1:10
                print("$(whiteScores[i,j]) ")
            end
            println("")
            print("$i: BLACK: ")
            for j = 1:10
                print("$(blackScores[i,j]) ")
            end
            println("")
            print("$i: White < Black: ")
            for j = 1:10
                print("$(whiteLessBlack[i,j]) ")
            end
            println("")
        end


    end

    f2()

end
