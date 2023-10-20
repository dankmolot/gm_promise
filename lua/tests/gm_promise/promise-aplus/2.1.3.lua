local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")

local function testRejected(expect, done, promise)
    local rejected = false
    promise:Then(function()
        expect(rejected).to.eq(false)
        done()
    end, function()
        rejected = true
    end)

    timer.Simple(0.5, function()
        expect(rejected).to.eq(true)
        done()
    end)
end

local function nextTick(fn)
    timer.Simple(0, fn)
end

return {
    groupName = "2.1.3.1: When rejected, a promise: must not transition to any other state.",
    cases = {
        {
            name = "trying different rejected promises",
            async = true,
            timeout = 1,
            func = function()
                local callCount = 0
                local finish = function()
                    callCount = callCount + 1
                    if callCount == 3 then done() end
                end
                helpers.testRejected({}, function(p)
                    testRejected(expect, finish, p)
                end)
            end
        },
        {
            name = "trying to reject then immediately fulfill",
            async = true,
            timeout = 1,
            func = function()
                local promise = Promise()
                testRejected(expect, done, promise)
                promise:Reject()
                promise:Resolve()
            end
        },
        {
            name = "trying to reject then fulfill, delayed",
            async = true,
            timeout = 1,
            func = function()
                local promise = Promise()
                testRejected(expect, done, promise)
                nextTick(function()
                    promise:Reject()
                    promise:Resolve()
                end)
            end
        },
        {
            name = "trying to reject immediately then fulfill delayed",
            async = true,
            timeout = 1,
            func = function()
                local promise = Promise()
                testRejected(expect, done, promise)
                promise:Reject()
                nextTick(function() promise:Resolve() end)
            end
        }
    }
}
