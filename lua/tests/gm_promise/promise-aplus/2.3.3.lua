local Promise = include("../promise.lua")
local helpers = include("../helpers.lua")
local reasons = include("../reasons.lua")
local thenables = include("../thenables.lua")

local asyncTest = helpers.asyncTest
local nextTick = helpers.nextTick
local getTestEnv = helpers.getTestEnv

local dummy = { dummy = "dummy" }
local sentiel = { sentiel = "sentiel" }
local other = { other = "other" }
local sentielArray = { sentiel }

local function testPromiseResolution(xFactory, test)
    asyncTest("via return from a fulfilled promise", function(done)
        local state = {}
        local promise = Promise.Resolve():Then(function()
            return xFactory(state)
        end)
    
        test(promise, done, state) 
    end)

    asyncTest("via return from a rejected promise", function(done)
        local state = {}
        local promise = Promise.Reject():Then(nil, function()
            return xFactory(state)
        end)
    
        test(promise, done, state) 
    end)
end

local function testCallingResolvePromise(yFactory, stringRep, test)
    -- `then` calls `resolvePromise` synchronously
    local function xFactory()
        return { Then = function(self, resolve) resolve(yFactory()) end }
    end

    testPromiseResolution(xFactory, test)

    -- `then` calls `resolvePromise` asynchronously
    local function xFactory()
        return { 
            Then = function(self, resolve) 
                nextTick(function()
                    resolve(yFactory())
                end)
            end 
        }
    end

    testPromiseResolution(xFactory, test)
end

local function testCallingRejectPromise(r, stringRep, test)
    -- `then` calls `rejectPromise` synchronously
    local function xFactory()
        return { Then = function(self, resolve, reject) reject(r) end }
    end

    testPromiseResolution(xFactory, test)

    -- `then` calls `rejectPromise` asynchronously
    local function xFactory()
        return { 
            Then = function(self, resolve, reject) 
                nextTick(function() reject(r) end)
            end 
        }
    end

    testPromiseResolution(xFactory, test)
end

local function testCallingResolvePromiseFulfillsWith(yFactory, stringRep, fulfillmentValue)
    local env = getTestEnv()
    testCallingResolvePromise(yFactory, stringRep, function(p, done)
        p:Then(function(value)
            env.expect(value).to.eq(fulfillmentValue)
            done()
        end)
    end)
end

local function testCallingResolvePromiseRejectsWith(yFactory, stringRep, rejectionReason)
    local env = getTestEnv()
    testCallingResolvePromise(yFactory, stringRep, function(p, done)
        p:Then(nil, function(reason)
            env.expect(reason).to.eq(rejectionReason)
            done()
        end)
    end)
end

local function testCallingRejectPromiseRejectsWith(reason, stringRep)
    local env = getTestEnv()
    testCallingRejectPromise(reason, stringRep, function(p, done)
        p:Then(nil, function(value)
            env.expect(value).to.eq(reason)
            done()
        end)
    end)
end

return {
    groupName = "2.3.3: Otherwise, if `x` is an object or function,",
    cases = {
        {
            name = "2.3.3.1: Let `then` be `x.then`",
            async = true,
            timeout = 1,
            func = function()
                -- `x` is a table with metatable
                local numberOfTimesThenWasRetrieved = 0
                local function xFactory()
                    return setmetatable({}, 
                        { 
                            __index = function(self, key)
                                if key == "Then" then
                                    numberOfTimesThenWasRetrieved = numberOfTimesThenWasRetrieved + 1
                                    return function(self, resolve) resolve() end
                                end
                            end
                        }
                    )
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function()
                        -- since testPromiseResolution tests two promises,
                        -- we expect this to be called twice
                        expect(numberOfTimesThenWasRetrieved).to.eq(2)
                        done()
                    end)
                end)
            end
        },
        {
            name = "2.3.3.2: If retrieving the property `x.then` results in a thrown exception `e`, reject `promise` with `e` as the reason.",
            async = true,
            timeout = 1,
            func = function()
                local function testRejectionViaThrowingGetter(e, stringRep)
                    local function xFactory()
                        return setmetatable({}, 
                            { 
                                __index = function(self, key)
                                    error(e)
                                end
                            }
                        )
                    end

                    testPromiseResolution(xFactory, function(p, done)
                        p:Then(nil, function(reason)
                            expect(reason).to.eq(e)
                            done()
                        end)
                    end)
                end

                for stringRep, fn in pairs(reasons) do
                    testRejectionViaThrowingGetter(fn(), stringRep)
                end
            end
        },
        {
            name = "2.3.3.3: If `then` is a function, call it with `x` as `this`, first argument `resolvePromise`, and second argument `rejectPromise`",
            async = true,
            timeout = 1,
            func = function()
                -- Calls with `x` as `this` and two function arguments
                local function xFactory()
                    local x = {}
                    x.Then = function(self, onFulfilled, onRejected)
                        expect(x).to.eq(self)
                        expect(onFulfilled).to.beA("function")
                        expect(onRejected).to.beA("function")
                        onFulfilled()
                    end
                    return x
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function()
                        done()
                    end)
                end)

                -- Uses the original value of `then`
                local function xFactory()
                    return setmetatable({ numberOfTimesThenWasRetrieved = 0 }, {
                        __index = function(self, key)
                            if key == "Then" and self.numberOfTimesThenWasRetrieved == 0 then
                                self.numberOfTimesThenWasRetrieved = 1
                                return function(self, onFulfilled, onRejected)
                                    onFulfilled()
                                end
                            end
                        end
                    })
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function()
                        done()
                    end)
                end)
            end
        },
        {
            name = "2.3.3.3.1: If/when `resolvePromise` is called with value `y`, run `[[Resolve]](promise, y)",
            async = true,
            timeout = 1,
            func = function()
                -- `y` is not a thenable
                testCallingResolvePromiseFulfillsWith(function() return nil end, '`nil`', nil)
                testCallingResolvePromiseFulfillsWith(function() return false end, '`false`', false)
                testCallingResolvePromiseFulfillsWith(function() return 5 end, '`5`', 5)
                testCallingResolvePromiseFulfillsWith(function() return sentiel end, 'an object', sentiel)
                testCallingResolvePromiseFulfillsWith(function() return sentielArray end, 'an array', sentielArray)

                -- `y` is a thenable
                for stringRep, fn in pairs(thenables.fulfilled) do
                    testCallingResolvePromiseFulfillsWith(function() return fn(sentiel) end, stringRep, sentiel)
                end

                for stringRep, fn in pairs(thenables.rejected) do
                    testCallingResolvePromiseRejectsWith(function() return fn(sentiel) end, stringRep, sentiel)
                end

                -- `y` is a thenable for a thenable
                for outerStringRep, outerFn in pairs(thenables.fulfilled) do
                    for innerStringRep, innerFn in pairs(thenables.fulfilled) do
                        local stringRep = outerStringRep .. " for " .. innerStringRep
                        local function yFactory()
                            return outerFn(innerFn(sentiel))
                        end
                        testCallingResolvePromiseFulfillsWith(yFactory, stringRep, sentiel)
                    end

                    for innerStringRep, innerFn in pairs(thenables.rejected) do
                        local stringRep = outerStringRep .. " for " .. innerStringRep
                        local function yFactory()
                            return outerFn(innerFn(sentiel))
                        end
                        testCallingResolvePromiseRejectsWith(yFactory, stringRep, sentiel)
                    end
                end
            end
        },
        {
            name = "2.3.3.3.2: If/when `rejectPromise` is called with reason `r`, reject `promise` with `r`",
            async = true,
            timeout = 1,
            func = function()
                for stringRep, fn in pairs(reasons) do
                    testCallingRejectPromiseRejectsWith(fn(), stringRep)
                end
            end
        },
        {
            name = "2.3.3.3.3: If both `resolvePromise` and `rejectPromise` are called, or multiple calls to the same argument are made, the first call takes precedence, and any further calls are ignored.",
            async = true,
            timeout = 1,
            func = function()
                -- calling `resolvePromise` then `rejectPromise`, both synchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        resolve(sentiel)
                        reject(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `resolvePromise` synchronously then `rejectPromise` asynchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        resolve(sentiel)
                        nextTick(function() reject(other) end)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `resolvePromise` then `rejectPromise`, both asynchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        nextTick(function() resolve(sentiel) end)
                        nextTick(function() reject(other) end)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `resolvePromise` with an asynchronously-fulfilled promise, then calling `rejectPromise`, both synchronously
                local function xFactory()
                    local p = Promise()
                    nextTick(function()
                        p:Resolve(sentiel)
                    end, 0.05)

                    return { Then = function(self, resolve, reject)
                        resolve(p)
                        reject(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `resolvePromise` with an asynchronously-rejected promise, then calling `rejectPromise`, both synchronously
                local function xFactory()
                    local p = Promise()
                    nextTick(function()
                        p:Reject(sentiel)
                    end, 0.1)

                    return { Then = function(self, resolve, reject)
                        resolve(p)
                        reject(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `rejectPromise` then `resolvePromise`, both synchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        reject(sentiel)
                        resolve(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `rejectPromise` synchronously then `resolvePromise` asynchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        reject(sentiel)
                        nextTick(function() resolve(other) end)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `rejectPromise` then `resolvePromise`, both asynchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        nextTick(function() reject(sentiel) end)
                        nextTick(function() resolve(other) end)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `resolvePromise` twice synchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        resolve(sentiel)
                        resolve(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `resolvePromise` twice, first synchronously then asynchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        resolve(sentiel)
                        nextTick(function() resolve(other) end)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `resolvePromise` twice, both times asynchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        nextTick(function() resolve(sentiel) end)
                        nextTick(function() resolve(other) end)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `resolvePromise` with an asynchronously-fulfilled promise, then calling it again, both times synchronously
                local function xFactory()
                    local p = Promise()
                    nextTick(function()
                        p:Resolve(sentiel)
                    end, 0.1)

                    return { Then = function(self, resolve, reject)
                        resolve(p)
                        resolve(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `resolvePromise` with an asynchronously-rejected promise, then calling it again, both times synchronously
                local function xFactory()
                    local p = Promise()
                    nextTick(function()
                        p:Reject(sentiel)
                    end, 0.1)

                    return { Then = function(self, resolve, reject)
                        resolve(p)
                        resolve(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `rejectPromise` twice synchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        reject(sentiel)
                        reject(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `rejectPromise` twice, first synchronously then asynchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        reject(sentiel)
                        nextTick(function() reject(other) end)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- calling `rejectPromise` twice, both times asynchronously
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        nextTick(function() reject(sentiel) end)
                        nextTick(function() reject(other) end)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- saving and abusing `resolvePromise` and `rejectPromise`
                local function xFactory(state)
                    return { Then = function(self, resolve, reject)
                        state.savedResolvePromise = resolve
                        state.savedRejectPromise = reject
                    end }
                end

                testPromiseResolution(xFactory, function(p, done, state)
                    local timesFulfilled = 0
                    local timesRejected = 0

                    p:Then(function() 
                        timesFulfilled = timesFulfilled + 1 
                    end, function()
                        timesRejected = timesRejected + 1
                    end)

                    if state.savedResolvePromise and state.savedRejectPromise then
                        state.savedResolvePromise(dummy)
                        state.savedResolvePromise(dummy)
                        state.savedRejectPromise(dummy)
                        state.savedRejectPromise(dummy)
                    end

                    nextTick(function()
                        state.savedResolvePromise(dummy)
                        state.savedResolvePromise(dummy)
                        state.savedRejectPromise(dummy)
                        state.savedRejectPromise(dummy)
                    end, 0.1)

                    nextTick(function()
                        expect(timesFulfilled).to.eq(1)
                        expect(timesRejected).to.eq(0)
                        done()
                    end, 0.2)
                end)
            end
        },
        {
            name = "2.3.3.3.4.1: If calling `then` throws an exception `e` and `resolvePromise` or `rejectPromise` have been called, ignore it.",
            async = true,
            timeout = 1,
            func = function()
                -- `resolvePromise` was called with a non-thenable
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        resolve(sentiel)
                        error(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- `resolvePromise` was called with an asynchronously-fulfilled promise
                local function xFactory()
                    local p = Promise()
                    nextTick(function()
                        p:Resolve(sentiel)
                    end, 0.05)

                    return { Then = function(self, resolve, reject)
                        resolve(p)
                        error(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- `resolvePromise` was called with an asynchronously-rejected promise
                local function xFactory()
                    local p = Promise()
                    nextTick(function()
                        p:Reject(sentiel)
                    end, 0)

                    return { Then = function(self, resolve, reject)
                        resolve(p)
                        error(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- `rejectPromise` was called"
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        reject(sentiel)
                        error(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- `resolvePromise` then `rejectPromise` were called
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        resolve(sentiel)
                        reject(sentiel)
                        error(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)
                
                -- `rejectPromise` then `resolvePromise` were called
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        reject(sentiel)
                        resolve(sentiel)
                        error(other)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)
            end
        },
        {
            name = "2.3.3.3.4.2: If calling `then` throws an exception, otherwise reject `promise` with `e` as the reason.",
            async = true,
            timeout = 1,
            func = function()
                -- straightforward case
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        error(sentiel)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)

                end)

                -- `resolvePromise` is called asynchronously before the `throw`
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        nextTick(function()
                            resolve(other)
                        end)
                        error(sentiel)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)

                -- `rejectPromise` is called asynchronously before the `throw`
                local function xFactory()
                    return { Then = function(self, resolve, reject)
                        nextTick(function()
                            reject(other)
                        end)
                        error(sentiel)
                    end }
                end

                testPromiseResolution(xFactory, function(p, done)
                    p:Then(nil, function(value)
                        expect(value).to.eq(sentiel)
                        done()
                    end)
                end)
            end
        },
        {
            name = "2.3.3.4: If `then` is not a function, fulfill promise with `x`",
            async = true,
            timeout = 1,
            func = function()
                local function testFulfillViaNonFunction(thenable, stringRep)
                    local x = { Then = thenable }
                    local function xFactory()
                        return x
                    end

                    testPromiseResolution(xFactory, function(p, done)
                        p:Then(function(value)
                            expect(value).to.eq(x)
                            done()
                        end)
                    end)
                end

                testFulfillViaNonFunction(nil, "`nil`")
                testFulfillViaNonFunction(false, "`false`")
                testFulfillViaNonFunction(5, "`5`")
                testFulfillViaNonFunction({}, "an object")
                testFulfillViaNonFunction({function()end}, "an array containing a function")
            end
        }
    }
}
