local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")
local reasons = include("../reasons.lua")

local testFulfilled = helpers.testFulfilled
local testRejected = helpers.testRejected
local finishFunc = helpers.finishFunc

local sentiel = { sentiel = "sentiel" }
local other = { other = "other" }

return {
    groupName = "2.2.7: `then` must return a promise: `promise2 = promise1.then(onFulfilled, onRejected)`",
    cases = {
        {
            name = "Is promise",
            func = function()
                local p = Promise()
                local p2 = p:Then()

                expect(p2).to.beA("table")
                expect(p2).toNot.eq(nil)
                expect(p2.Then).to.beA("function")
            end
        },
        {
            name = "2.2.7.1: If either `onFulfilled` or `onRejected` returns a value `x`, run the Promise Resolution Procedure `[[Resolve]](promise2, x)`",
            func = function()
                -- see separate 3.3 tests
            end
        },
        {
            name = "2.2.7.2: If either `onFulfilled` or `onRejected` throws an exception `e`, `promise2` must be rejected with `e` as the reason.",
            async = true,
            timeout = 1,
            func = function()
                local finish = finishFunc(done, table.Count(reasons))
                local function testReason(expectedReason)
                    local finish2 = finishFunc(finish, 6)
                    testFulfilled(nil, function(p)
                        local p2 = p:Then(function()
                            error(expectedReason)
                        end)

                        p2:Then(nil, function(reason)
                            expect(reason).to.eq(expectedReason)
                            finish2()
                        end)
                    end)
                    testRejected(nil, function(p)
                        local p2 = p:Then(nil, function()
                            error(expectedReason)
                        end)

                        p2:Then(nil, function(reason)
                            expect(reason).to.eq(expectedReason)
                            finish2()
                        end)
                    end)
                end

                for k, v in pairs(reasons) do
                    testReason(v)
                end
            end
        },
        {
            name = "2.2.7.3: If `onFulfilled` is not a function and `promise1` is fulfilled, `promise2` must be fulfilled with the same value.",
            async = true,
            timeout = 1,
            func = function()
                local finish = finishFunc(done, 5)
                local function testNonFunction(nonFunction)
                    local finish2 = finishFunc(finish, 3)
                    testFulfilled(sentiel, function(p)
                        local p2 = p:Then(nonFunction)
                        p2:Then(function(value)
                            expect(value).to.eq(sentiel)
                            finish2()
                        end)
                    end)
                end

                testNonFunction(nil)
                testNonFunction(false)
                testNonFunction(5)
                testNonFunction({})
                testNonFunction({function() return other end})
            end,
        },
        {
            name = "2.2.7.4: If `onRejected` is not a function and `promise1` is rejected, `promise2` must be rejected with the same reason.",
            async = true,
            timeout = 1,
            func = function()
                local finish = finishFunc(done, 5)
                local function testNonFunction(nonFunction)
                    local finish2 = finishFunc(finish, 3)
                    testRejected(sentiel, function(p)
                        local p2 = p:Then(nil, nonFunction)
                        p2:Then(nil, function(value)
                            expect(value).to.eq(sentiel)
                            finish2()
                        end)
                    end)
                end

                testNonFunction(nil)
                testNonFunction(false)
                testNonFunction(5)
                testNonFunction({})
                testNonFunction({function() return other end})
            end,
        }
    }
}
