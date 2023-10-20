local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")

local asyncTest = helpers.asyncTest
local nextTick = helpers.nextTick
local testFulfilled = helpers.testFulfilled
local testRejected = helpers.testRejected

local dummy = { dummy = "dummy" }

return {
    groupName = "2.3.4: If `x` is not an object or function, fulfill `promise` with `x`",
    cases = {
        {
            name = "test all values",
            async = true,
            timeout = 1,
            func = function()
                local function testValue(expectedValue, stringRep)
                    testFulfilled(dummy, function(p1, done)
                        local p2 = p1:Then(function()
                            return expectedValue
                        end)

                        p2:Then(function(actualValue)
                            expect(actualValue).to.eq(actualValue)
                            done()
                        end)
                    end)

                    testRejected(dummy, function(p1, done)
                        local p2 = p1:Then(nil, function()
                            return expectedValue
                        end)

                        p2:Then(function(actualValue)
                            expect(actualValue).to.eq(actualValue)
                            done()
                        end)
                    end)
                end

                testValue(nil, "`nil`")
                testValue(false, "`false`")
                testValue(true, "`true`")
                testValue(0, "`0`")
            end
        }
    }
}
