local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")

local testFulfilled = helpers.testFulfilled
local testRejected = helpers.testRejected
local nextTick = helpers.nextTick
local wrap = helpers.wrap
local finishFunc = helpers.finishFunc

local sentiel = { sentiel = "sentiel" }
local sentiel2 = { sentiel2 = "sentiel2" }
local sentiel3 = { sentiel3 = "sentiel3" }
local other = { other = "other" }

return {
    groupName = "2.2.6: `then` may be called multiple times on the same promise.",
    cases = {
        {
            name = "2.2.6.1: If/when `promise` is fulfilled, all respective `onFulfilled` callbacks must execute in the order of their originating calls to `then`.",
            async = true,
            timeout = 1,
            func = function()
                local finish = finishFunc(done, 15)

                -- multiple boring fulfillment handlers
                testFulfilled(sentiel, function(p)
                    local s1 = stub()
                    local s2 = stub()
                    local s3 = stub()
                    
                    local spy = stub()
                    p:Then(wrap(s1, other), spy)
                    p:Then(wrap(s2, other), spy)
                    p:Then(wrap(s3, other), spy)

                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                    
                        expect(s1).was.called(1)
                        expect(s2).was.called(1)
                        expect(s3).was.called(1)
                        expect(spy).was.called(0)

                        finish()
                    end)
                end)

                -- multiple fulfillment handlers, one of which throws
                testFulfilled(sentiel, function(p)
                    local s1 = stub()
                    local s2 = stub()
                    local s3 = stub()
                    local spy = stub()

                    p:Then(wrap(s1, other), spy)
                    p:Then(wrap(s2, nil, other), spy)
                    p:Then(wrap(s3, other), spy)

                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                    
                        expect(s1).was.called(1)
                        expect(s2).was.called(1)
                        expect(s3).was.called(1)
                        expect(spy).was.called(0)

                        finish()
                    end)
                end)

                -- results in multiple branching chains with their own fulfillment values
                testFulfilled(nil, function(p)
                    local semiFinish = finishFunc(finish, 3)
                    p:Then(function()
                        return sentiel
                    end):Then(function(value)
                        expect(value).to.eq(sentiel)
                        semiFinish()
                    end)

                    p:Then(function()
                        error(sentiel2)
                    end):Then(nil, function(reason)
                        expect(reason).to.eq(sentiel2)
                        semiFinish()
                    end)

                    p:Then(function()
                        return sentiel3
                    end):Then(function(value)
                        expect(value).to.eq(sentiel3)
                        semiFinish()
                    end)
                end)

                -- `onFulfilled` handlers are called in the original order
                testFulfilled(nil, function(p)
                    local s1 = stub()
                    local s2 = stub()
                    local s3 = stub()

                    p:Then(s1)
                    p:Then(function() 
                        expect(s1).was.called(1) 
                        expect(s2).was.called(0) 
                        expect(s3).was.called(0) 
                    end)
                    p:Then(s2)
                    p:Then(function() 
                        expect(s1).was.called(1) 
                        expect(s2).was.called(1) 
                        expect(s3).was.called(0) 
                    end)
                    p:Then(s3)
                    p:Then(function() 
                        expect(s1).was.called(1) 
                        expect(s2).was.called(1) 
                        expect(s3).was.called(1) 
                    end)
                    p:Then(function()
                        finish()
                    end)
                end)

                -- even when one handler is added inside another handler
                testFulfilled(nil, function(p)
                    local s1 = stub()
                    local s2 = stub()
                    local s3 = stub()

                    p:Then(function()
                        s1()
                        p:Then(s3)
                    end)
                    p:Then(function()
                        expect(s1).was.called(1)
                        expect(s2).was.called(0)
                        expect(s3).was.called(0)
                        p:Then(function()
                            expect(s1).was.called(1) 
                            expect(s2).was.called(1) 
                            expect(s3).was.called(1) 
                            finish()
                        end)
                    end)
                    p:Then(s2)
                    p:Then(function()
                        expect(s1).was.called(1) 
                        expect(s2).was.called(1) 
                        expect(s3).was.called(0)
                    end)
                end)
            end,
        },
        {
            name = "2.2.6.2: If/when `promise` is rejected, all respective `onRejected` callbacks must execute in the order of their originating calls to `then`.",
            async = true,
            timeout = 1,
            func = function()
                local finish = finishFunc(done, 15)

                -- multiple boring rejection handlers
                testRejected(sentiel, function(p)
                    local s1 = stub()
                    local s2 = stub()
                    local s3 = stub()
                    
                    local spy = stub()
                    p:Then(spy, wrap(s1, other))
                    p:Then(spy, wrap(s2, other))
                    p:Then(spy, wrap(s3, other))

                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                    
                        expect(s1).was.called(1)
                        expect(s2).was.called(1)
                        expect(s3).was.called(1)
                        expect(spy).was.called(0)

                        finish()
                    end)
                end)

                -- multiple rejection handlers, one of which throws
                testRejected(sentiel, function(p)
                    local s1 = stub()
                    local s2 = stub()
                    local s3 = stub()
                    local spy = stub()

                    p:Then(spy, wrap(s1, other))
                    p:Then(spy, wrap(s2, nil, other))
                    p:Then(spy, wrap(s3, other))

                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                    
                        expect(s1).was.called(1)
                        expect(s2).was.called(1)
                        expect(s3).was.called(1)
                        expect(spy).was.called(0)

                        finish()
                    end)
                end)

                -- results in multiple branching chains with their own fulfillment values
                testRejected(nil, function(p)
                    local semiFinish = finishFunc(finish, 3)
                    p:Then(nil, function()
                        return sentiel
                    end):Then(function(value)
                        expect(value).to.eq(sentiel)
                        semiFinish()
                    end)

                    p:Then(nil, function()
                        error(sentiel2)
                    end):Then(nil, function(reason)
                        expect(reason).to.eq(sentiel2)
                        semiFinish()
                    end)

                    p:Then(nil, function()
                        return sentiel3
                    end):Then(function(value)
                        expect(value).to.eq(sentiel3)
                        semiFinish()
                    end)
                end)

                -- `onFulfilled` handlers are called in the original order
                testRejected(nil, function(p)
                    local s1 = stub()
                    local s2 = stub()
                    local s3 = stub()

                    p:Then(nil, s1)
                    p:Then(nil, function() 
                        expect(s1).was.called(1) 
                        expect(s2).was.called(0) 
                        expect(s3).was.called(0) 
                    end)
                    p:Then(nil, s2)
                    p:Then(nil, function() 
                        expect(s1).was.called(1) 
                        expect(s2).was.called(1) 
                        expect(s3).was.called(0) 
                    end)
                    p:Then(nil, s3)
                    p:Then(nil, function() 
                        expect(s1).was.called(1) 
                        expect(s2).was.called(1) 
                        expect(s3).was.called(1) 
                    end)
                    p:Then(nil, function()
                        finish()
                    end)
                end)

                -- even when one handler is added inside another handler
                testRejected(nil, function(p)
                    local s1 = stub()
                    local s2 = stub()
                    local s3 = stub()

                    p:Then(nil, function()
                        s1()
                        p:Then(nil, s3)
                    end)
                    p:Then(nil, function()
                        expect(s1).was.called(1)
                        expect(s2).was.called(0)
                        expect(s3).was.called(0)
                        p:Then(nil, function()
                            expect(s1).was.called(1) 
                            expect(s2).was.called(1) 
                            expect(s3).was.called(1) 
                            finish()
                        end)
                    end)
                    p:Then(nil, s2)
                    p:Then(nil, function()
                        expect(s1).was.called(1) 
                        expect(s2).was.called(1) 
                        expect(s3).was.called(0)
                    end)
                end)
            end,
        },
    }
}
