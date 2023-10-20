local Promise = include("promise.lua")

local function getTestEnv()
    local stackLevel = 2
    while true do
        local info = debug.getinfo(stackLevel, "f")
        if not info then break end
        
        stackLevel = stackLevel + 1
        local env = debug.getfenv(info.func)
        if env and env ~= _G then
            return env
        end
    end
end

local function nextTick(fn, time)
    timer.Simple(time or 0, fn)
end

local function asyncTest(desc, fn)
    local env = getTestEnv()
    assert(env, "Could not find test environment")
    assert(isfunction(env.done), "Test environment isn't async")
    assert(isfunction(fn), "Expected function, got " .. type(fn))

    env.__asyncTests = env.__asyncTests or 0
    env.__asyncTestsFinished = env.__asyncTestsFinished or 0

    env.__asyncTests = env.__asyncTests + 1
    
    local function done()
        env.__asyncTestsFinished = env.__asyncTestsFinished + 1
        assert(env.__asyncTestsFinished <= env.__asyncTests, "done() called too many times")
        if env.__asyncTestsFinished == env.__asyncTests then
            env.done()
        end
    end

    nextTick(function()
        fn(done)
    end)
end

return {
    getTestEnv = getTestEnv,
    nextTick = nextTick,
    asyncTest = asyncTest,

    testFulfilled = function(value, test)
        asyncTest("already-fulfilled", function(done)
            test(Promise.Resolve(value), done)
        end)

        asyncTest("immediately-fulfilled", function(done)
            local p = Promise()
            test(p, done)
            p:Resolve(value)
        end)

        asyncTest("eventually-fulfilled", function(done)
            local p = Promise()
            test(p, done)
            nextTick(function()
                p:Resolve(value)
            end, 0.05)
        end)
    end,

    testRejected = function(value, fn, done)
        asyncTest("already-rejected", function(done)
            fn(Promise.Reject(value), done)
        end)

        asyncTest("immediately-rejected", function(done)
            local p = Promise()
            fn(p, done)
            p:Reject(value)
        end)

        asyncTest("eventually-rejected", function(done)
            local p = Promise()
            fn(p, done)
            nextTick(function()
                p:Reject(value)
            end, 0.05)
        end)
    end,

    finishFunc = function(done, count)
        local callCount = 0
        return function()
            callCount = callCount + 1
            if callCount == count then done() end
        end
    end,

    wrap = function(fn, returnValue, throwValue)
        return function(...)
            if throwValue then
                fn(...)
                error(throwValue)
            elseif returnValue then
                fn(...)
                return returnValue
            else
                return fn(...)
            end
        end
    end,
}
