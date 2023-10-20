local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")

local function nextTick(fn)
    timer.Simple(0, fn)
end

return {
    groupName = "2.2.4: `onFulfilled` or `onRejected` must not be called until the execution context stack contains only platform code.",
    cases = {
        {
            name = "`then` returns before the promise becomes fulfilled or rejected",
            async = true,
            timeout = 1,
            func = function()
                local finish = helpers.finishFunc(done, 6)

                helpers.testFulfilled(nil, function(p)
                    local thenHasReturned = false
                    p:Then(function()
                        expect(thenHasReturned).to.eq(true)
                        finish()
                    end)
                    thenHasReturned = true
                end)
                helpers.testRejected(nil, function(p)
                    local thenHasReturned = false
                    p:Then(nil, function()
                        expect(thenHasReturned).to.eq(true)
                        finish()
                    end)
                    thenHasReturned = true
                end)
            end
        },
        {
            name = "Clean-stack execution ordering tests (fulfillment case)",
            async = true,
            timeout = 1,
            func = function()
                local finish = helpers.finishFunc(done, 5)

                -- when `onFulfilled` is added immediately before the promise is fulfilled
                local p = Promise()
                local onFulfilledCalled = false
                p:Then(function()
                    onFulfilledCalled = true
                    finish()
                end)
                p:Resolve()
                expect(onFulfilledCalled).to.eq(false)

                -- when `onFulfilled` is added immediately after the promise is fulfilled
                local p = Promise()
                local onFulfilledCalled = false
                p:Resolve()
                p:Then(function()
                    onFulfilledCalled = true
                    finish()
                end)
                expect(onFulfilledCalled).to.eq(false)

                -- when one `onFulfilled` is added inside another `onFulfilled`
                local p = Promise.Resolve()
                local firstOnFulfilledFinished = false
                p:Then(function()
                    p:Then(function()
                        expect(firstOnFulfilledFinished).to.eq(true)
                        finish()
                    end)
                    firstOnFulfilledFinished = true
                end)

                -- when `onFulfilled` is added inside an `onRejected`
                local p1 = Promise.Reject()
                local p2 = Promise.Resolve()
                local firstOnRejectedFinished = false
                p1:Then(nil, function()
                    p2:Then(function()
                        expect(firstOnRejectedFinished).to.eq(true)
                        finish()
                    end)
                    firstOnRejectedFinished = true
                end)

                -- when the promise is fulfilled asynchronously
                local p = Promise()
                local firstStackFinished = false
                nextTick(function()
                    p:Resolve()
                    firstStackFinished = true
                end)
                p:Then(function()
                    expect(firstStackFinished).to.eq(true)
                    finish()
                end)
            end
        },
        {
            name = "Clean-stack execution ordering tests (rejection case)",
            async = true,
            timeout = 1,
            func = function()
                local finish = helpers.finishFunc(done, 5)

                -- when `onRejected` is added immediately before the promise is rejected
                local p = Promise()
                local onRejectedCalled = false
                p:Then(nil, function()
                    onRejectedCalled = true
                    finish()
                end)
                p:Reject()
                expect(onRejectedCalled).to.eq(false)

                -- when `onRejected` is added immediately after the promise is rejected
                local p = Promise()
                local onRejectedCalled = false
                p:Reject()
                p:Then(nil, function()
                    onRejectedCalled = true
                    finish()
                end)
                expect(onRejectedCalled).to.eq(false)

                -- when `onRejected` is added inside an `onFulfilled`
                local p1 = Promise.Resolve()
                local p2 = Promise.Reject()
                local firstOnFulfilledFinished = false
                p1:Then(function()
                    p2:Then(nil, function()
                        expect(firstOnFulfilledFinished).to.eq(true)
                        finish()
                    end)
                    firstOnFulfilledFinished = true
                end)

                -- when one `onRejected` is added inside another `onRejected`
                local p = Promise.Reject()
                local firstOnRejectedFinished = false
                p:Then(nil, function()
                    p:Then(nil, function()
                        expect(firstOnRejectedFinished).to.eq(true)
                        finish()
                    end)
                    firstOnRejectedFinished = true
                end)

                -- when the promise is rejected asynchronously
                local p = Promise()
                local firstStackFinished = false
                nextTick(function()
                    p:Reject()
                    firstStackFinished = true
                end)
                p:Then(nil, function()
                    expect(firstStackFinished).to.eq(true)
                    finish()
                end)
            end
        }
    }
}
