local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")

local function testFulfilled(expect, done, promise)
    local fulfilled = false
    promise:Then(function()
        fulfilled = true
    end, function()
        expect(fulfilled).to.eq(false)
        done()
    end)

    timer.Simple(0.5, function()
        expect(fulfilled).to.eq(true)
        done()
    end)
end

local function nextTick(fn)
    timer.Simple(0, fn)
end

return {
    groupName = "2.1.2.1: When fulfilled, a promise: must not transition to any other state.",
    cases = {
        {
            name = "trying different fulfilled promises",
            async = true,
            timeout = 1,
            func = function()
                local callCount = 0
                local finish = function()
                    callCount = callCount + 1
                    if callCount == 3 then done() end
                end
                helpers.testFulfilled({}, function(p)
                    testFulfilled(expect, finish, p)
                end)
            end
        },
        {
            name = "trying to fulfill then immediately reject",
            async = true,
            timeout = 1,
            func = function()
                local promise = Promise()
                testFulfilled(expect, done, promise)
                promise:Resolve()
                promise:Reject()
            end
        },
        {
            name = "trying to fulfill then reject, delayed",
            async = true,
            timeout = 1,
            func = function()
                local promise = Promise()
                testFulfilled(expect, done, promise)
                nextTick(function()
                    promise:Resolve()
                    promise:Reject()
                end)
            end
        },
        {
            name = "trying to fulfill immediately then reject delayed",
            async = true,
            timeout = 1,
            func = function()
                local promise = Promise()
                testFulfilled(expect, done, promise)
                promise:Resolve()
                nextTick(function() promise:Reject() end)
            end
        }
    }
}
