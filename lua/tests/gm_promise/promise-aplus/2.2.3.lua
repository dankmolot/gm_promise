local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")

local sentiel = { sentiel = "sentiel" }

local function nextTick(fn)
    timer.Simple(0, fn)
end

return {
    groupName = "2.2.3: If `onRejected` is a function",
    cases = {
        {
            name = "2.2.3.1: it must be called after `promise` is rejected, with `promise`’s rejection reason as its first argument.",
            async = true,
            timeout = 1,
            func = function()
                helpers.testRejected(sentiel, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)
            end
        },
        {
            name = "2.2.3.2: it must not be called before `promise` is rejected",
            async = true,
            timeout = 1,
            func = function()
                -- rejected after a delay
                local rejected = false
                local p = Promise()
                p:Then(nil, function()
                    expect(rejected).to.eq(true)
                    done()
                end)
                nextTick(function()
                    rejected = true
                    p:Reject()
                end)

                -- never rejected
                local called = false
                local p2 = Promise()
                p2:Then(nil, function()
                    called = true
                end)
                nextTick(function()
                    expect(called).to.eq(false)
                    done()
                end)
            end
        },
        {
            name = "2.2.3.3: it must not be called more than once.",
            async = true,
            timeout = 1,
            func = function()
                local s = stub()

                -- already rejected
                Promise.Reject():Then(nil, function() s() end)
                
                -- trying to reject a pending promise more than once, immediately
                local p1 = Promise()
                p1:Then(nil, function() s() end)

                p1:Reject()
                p1:Reject()

                -- trying to reject a pending promise more than once, delayed
                local p2 = Promise()
                p2:Then(nil, function() s() end)
                nextTick(function()
                    p2:Reject()
                    p2:Reject()
                end)

                -- trying to reject a pending promise more than once, immediately then delayed
                local p3 = Promise()
                p3:Then(nil, function() s() end)
                p3:Reject()
                nextTick(function()
                    p3:Reject()
                end)

                -- when multiple `then` calls are made, spaced apart in time
                local p4 = Promise()
                p4:Then(nil, function() s() end)
                nextTick(function()
                    p4:Then(nil, function() s() end)
                    nextTick(function()
                        p4:Then(nil, function() s() end)
                        nextTick(function()
                            p4:Reject()
                        end)
                    end)
                end)

                -- when `then` is interleaved with rejectment"
                local p5 = Promise()
                p5:Then(nil, function() s() end)
                p5:Reject()
                p5:Then(nil, function() s() end)

                timer.Simple(0.5, function()
                    expect(s).was.called(9)
                    done()
                end)
            end
        },
    }
}
