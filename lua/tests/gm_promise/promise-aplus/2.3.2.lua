local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")

local asyncTest = helpers.asyncTest
local nextTick = helpers.nextTick

local sentiel = { sentiel = "sentiel" }

local function testPromiseResolution(xFactory, test)
    asyncTest("via return from a fulfilled promise", function(done)
        local promise = Promise.Resolve():Then(function()
            return xFactory()
        end)
    
        test(promise, done) 
    end)

    asyncTest("via return from a rejected promise", function(done)
        local promise = Promise.Reject():Then(nil, function()
            return xFactory()
        end)
    
        test(promise, done) 
    end)
end

return {
    groupName = "2.3.2: If `x` is a promise, adopt its state",
    cases = {
        {
            name = "2.3.2.1: If `x` is pending, `promise` must remain pending until `x` is fulfilled or rejected.",
            async = true,
            timeout = 1,
            func = function()
                testPromiseResolution(function() return Promise() end, function(p, done)
                    local wasFulfilled = false
                    local wasRejected = false

                    p:Then(function() wasFulfilled = true end, function() wasRejected = true end)

                    nextTick(function()
                        expect(wasFulfilled).to.eq(false)
                        expect(wasRejected).to.eq(false)
                        done()
                    end, 0.2)
                end)
            end
        },
        {
            name = "2.3.2.2: If/when `x` is fulfilled, fulfill `promise` with the same value.",
            async = true,
            timeout = 1,
            func = function()
                -- `x` is already-fulfilled
                testPromiseResolution(function() return Promise.Resolve(sentiel) end, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- `x` is eventually-fulfilled
                local function xFactory()
                    local p = Promise()
                    nextTick(function() p:Resolve(sentiel) end)
                    return p
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)
            end
        },
        {
            name = "2.3.2.3: If/when `x` is rejected, reject `promise` with the same reason.",
            async = true,
            timeout = 1,
            func = function()
                -- `x` is already-rejected
                testPromiseResolution(function() return Promise.Reject(sentiel) end, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- `x` is eventually-rejected
                local function xFactory()
                    local p = Promise()
                    nextTick(function() p:Reject(sentiel) end)
                    return p
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)
            end
        }
    }
}
