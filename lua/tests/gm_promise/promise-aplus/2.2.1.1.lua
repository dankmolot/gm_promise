local Promise = include("../promise.lua")

local function nextTick(fn, time)
    timer.Simple(time or 0, fn)
end

return {
    groupName = "2.2.1.1: If `onFulfilled` is not a function, it must be ignored.",
    cases = {
        {
            name = "applied to a directly-rejected promise",
            async = true,
            timeout = 1,
            func = function()
                local function testNonFunction(nonFunction)
                    local s = stub()
                    Promise.Reject():Then(nonFunction, function() s() end)
                    nextTick(function()
                        expect(s).was.called(1)
                    end, 0.5)
                end

                testNonFunction(nil)
                testNonFunction(false)
                testNonFunction(5)
                testNonFunction({})
                nextTick(function()
                    done()
                end, 0.6)
            end
        },
        {
            name = "applied to a promise rejected and then chained off of",
            async = true,
            timeout = 1,
            func = function()
                local function testNonFunction(nonFunction)
                    local s = stub()
                    Promise.Reject():Then(function()end, nil):Then(nonFunction, function() s() end)
                    nextTick(function()
                        expect(s).was.called(1)
                    end, 0.5)
                end

                testNonFunction(nil)
                testNonFunction(false)
                testNonFunction(5)
                testNonFunction({})
                nextTick(function()
                    done()
                end, 0.6)
            end
        },
    }
}
