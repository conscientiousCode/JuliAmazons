module Timers
    export TargetTimer, Flag, startTimer, getNewFlagTimer, SplatTimer

    struct TargetTimer
        timeToElapse::Float64
        target
        f #f is the function to call on target after elapsed time
    end

    struct SplatTimer
        timeToElapse::Float64
        fArgTuple
        f #f is the function to call on target after elapsed time
    end

    #This method should be called with the @async macro to run in the back
    function startTimer(timer::TargetTimer)
            sleep(timer.timeToElapse)
            timer.f(timer.target)
    end

    function startTimer(splatTimer::SplatTimer)
            sleep(splatTimer.timeToElapse)
            println("Done Splat Sleeping: $splatTimer")
            splatTimer.f(splatTimer.fArgTuple...)
    end

    mutable struct Flag
        isRaised::Bool
    end

    function raiseFlag(flag::Flag)
        flag.isRaised = true
    end

    function getNewFlagTimer(time::Float64)::Tuple{TargetTimer, Flag}
        flag = Flag(false)
        timer = TargetTimer(time, flag, raiseFlag)
        return (timer, flag)
    end



end
