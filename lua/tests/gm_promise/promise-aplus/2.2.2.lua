local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")

local sentiel = { sentiel = "sentiel" }

local function nextTick(fn)
    timer.Simple(0, fn)
end

return {
    groupName = "2.2.2: If `onFulfilled` is a function",
    cases = {
        {
            name = "2.2.2.1: it must be called after `promise` is fulfilled, with `promise`'s fulfillment value as its first argument.",
            async = true,
            timeout = 1,
            func = function()
                helpers.testFulfilled(sentiel, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)
            end
        },
        {
            name = "2.2.2.2: it must not be called before `promise` is fulfilled after delay",
            async = true,
            timeout = 1,
            func = function()
                local p = Promise()
                local fulfilled = false
                p:Then(function()
                    expect(fulfilled).to.eq(true)
                    done()
                end)
                nextTick(function()
                    fulfilled = true
                    p:Resolve()
                end)
            end
        },
        {
            name = "2.2.2.2: it must not be called if `promise` never fulfilled",
            async = true,
            timeout = 1,
            func = function()
                local p = Promise()
                local called = false
                p:Then(function()
                    called = true
                end)
                nextTick(function()
                    expect(called).to.eq(false)
                    done()
                end)
            end
        },
        {
            name = "2.2.2.3: it must not be called more than once.",
            async = true,
            timeout = 1,
            func = function()
                local s = stub()

                -- already resolved
                Promise.Resolve():Then(function() s() end)
                
                -- trying to fulfill a pending promise more than once, immediately
                local p1 = Promise()
                p1:Then(function() s() end)

                p1:Resolve()
                p1:Resolve()

                -- trying to fulfill a pending promise more than once, delayed
                local p2 = Promise()
                p2:Then(function() s() end)
                nextTick(function()
                    p2:Resolve()
                    p2:Resolve()
                end)

                -- trying to fulfill a pending promise more than once, immediately then delayed
                local p3 = Promise()
                p3:Then(function() s() end)
                p3:Resolve()
                nextTick(function()
                    p3:Resolve()
                end)

                -- when multiple `then` calls are made, spaced apart in time
                local p4 = Promise()
                p4:Then(function() s() end)
                nextTick(function()
                    p4:Then(function() s() end)
                    nextTick(function()
                        p4:Then(function() s() end)
                        nextTick(function()
                            p4:Resolve()
                        end)
                    end)
                end)

                -- when `then` is interleaved with fulfillment"
                local p5 = Promise()
                p5:Then(function() s() end)
                p5:Resolve()
                p5:Then(function() s() end)

                timer.Simple(0.5, function()
                    expect(s).was.called(9)
                    done()
                end)
            end
        },
    }
}
