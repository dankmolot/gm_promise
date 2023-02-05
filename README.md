# gm_promise
A library that mostly implements Promise/A+ specification for GLua.
If you are familiar with promises from JS, then this library will be easy to learn & use for you.

## Differences with [JS Promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
* Promises can be resolved immediately instead of being resolved in next tick (see [Promise/A+ 3.1](https://promisesaplus.com/#notes))
* All functions are converted to PascalCase (JS -> Lua)
    * `new Promise((resolve, reject) => {...})` -> `promise.New(function(resolve, reject) ... end)`
    * `Promise.all(array)` -> `promise.All(array)`
    * `Promise.resolve(value)` -> `promise.Resolve(value)`
    * `Promise.reject(reason)` -> `promise.Reject(reason)`
    * `Promise.prototype.then(onFulfilled?, onRejected?)` -> `PromiseObject:Then(onFulfilled?, onRejected?)`
    * `Promise.prototype.catch(onRejected?)` -> `PromiseObject:Catch(onRejected?)`
* There currently no `promise.AllSettled`, `promise.Any`, `promise.Race` and `PromiseObject:Finally(...)` methods
* Errors inside async will have error line prepended, see [Notes](#notes) for more information.
* Errors doesn't have stacktrace
* Since in lua we don't have syntax `async function`, async functions created using function `promise.Async(function() ... end)`
* `PromiseObject:Await()` isn't safe to use, and throws errors. To handle errors and use await use `PromiseObject:SafeAwait()`


## API
This library can be included by calling `require("promise")`
### Global variables
```lua
promise._VERSION = "1.2.3" -- Version of the promise library - major.minor.patch
promise._VERSION_NUM = 010203 -- Version in number format: 1.2.3 -> 010203 | 99.56.13 -> 995613
promise.PROMISE = {...} -- Metatable for PromiseObject
```

### Global methods
```lua
-- Creates new promise object
-- If function passed, then calls it with arguments (resolve, reject)
-- Example:
--          promise.new(function(resolve, reject)
--              local ok, result = pcall(doWork)
--              if ok then
--                  resolve(result)
--              else
--                  reject(result)
--              end
--          end)
PromiseObject promise.New(func: function)

-- Creates a new async function that return promise
-- Example:
--          local makeHttpRequest = promise.Async(function(url, headers))
--              local ok, res = promise.HTTP({ url = url, headers = headers })
--              if not ok then return promise.Reject(res) end
--              
--              print(res.body)
--          end)
--
--          print( makeHttpRequest("https://httpbin.org/get") ) -- Promise 0x2b59872ab90 {<pending>}
AsyncFunction promise.Async(func: function)

-- Returns a promise that resolved with passed value
-- If promise passed, then it waits until promise is resolved or rejected
PromiseObject promise.Resolve(value: any)

-- Returns a promise that is rejected with passed value
-- This function accepts any value, but it is always better to use string
-- Also if promise passed as value, then it won't wait until given promise is resolved
PromiseObject promise.Reject(reason: any)

-- Returns a promise with array of resolved values from promises
-- If some promise is rejected, then rejects returned promise
-- Example:
--          local promises = { promise.Resolve("Hello"), promise.Resolve("World") }
--
--          promise.All(promises)
--              :Then(util.TableToJSON)
--              :Then(print) -- ["Hello","World"]
PromiseObject promise.All(promises: table)

-- Returns a promise that resolves after specified time in seconds
-- Same as: promise.New(function(resolve) timer.Simple(time, resolve) end)
PromiseObject promise.Delay(seconds: number)

-- Returns a promise which is resolved with result table
-- If HTTP request wasn't successful, then promise will be rejected
-- Uses https://wiki.facepunch.com/gmod/Global.HTTP
-- 
-- Example of result table:
--  {
--      code = 200,
--      headers = { ... },
--      body = "..."
--  }
PromiseObject promise.HTTP(parameters: HTTPRequest)

-- Returns true if object have .Then function
bool promise.IsThenable(obj: any)

-- Returns true if object have .Await function
bool promise.IsAwaitable(obj: any)

-- Returns true if object is PromiseObject
bool promise.IsPromise(obj: any)

-- Same as coroutine.running()
thread promise.RunningInAsync()

-- Alias to PromiseObject:Await()
promise.Await(promise: PromiseObject)

-- Alias to PromiseObject:SafeAwait()
promise.SafeAwait(promise: PromiseObject)
```

### PromiseObject method
```lua
-- Returns current promise state ("pending", "fulfilled", "rejected")
string PromiseObject:GetState()

-- I think these functions are self-explanatory
bool PromiseObject:IsPending()
bool PromiseObject:IsFulfilled()
bool PromiseObject:IsRejected()

-- :Then(...) function takes two function: onFulfilled and onRejected callbacks
-- It will call onFulfilled callback if promise resolved, or onRejected callback if rejected
-- It immediately returns a new PromiseObject that will be resolved with returned value from onFulfilled callback, 
-- or rejected with returned value from onRejected callback
PromiseObject PromiseObject:Then(onFulfilled?: function, onRejected?: function)

-- Same as PromiseObject:Then(nil, onRejected)
PromiseObject PromiseObject:Catch(onRejected?: function)

-- Waits until promise become resolved and returns its value
-- If promise becomes rejected, then :Await() throws an error
-- It is better to catch error with :SafeAwait(), see notes for more information
--
-- NB! Can only be used in async function or coroutine
any PromiseObject:Await()

-- Waits until promise become resolved and returns true and its value
-- If promise becomes rejected, then returns false and error message (rejected value)
-- Useful for handling and forwarding errors
--
-- NB! Can only be used in async function or coroutine
bool, any PromiseObject:SafeAwait()

-- Returns internal result if promise is fulfilled or rejected
any PromiseObject:GetResult()

-- Fulfills promise with the given value
-- If promise given, when it is waits until promise gets fulfilled or rejected
PromiseObject:Resolve(value: any)

-- Rejects promise with the given reason
-- It accepts any value, but it's better to use strings as reason
PromiseObject:Reject(reason: any)

-- Just a metamethod that converts promise to string
-- table 0x01234abcdef -> Promise 0x01234abcdef {<state>: value}
-- Example: Promise 0x2b59872ab90 {<fulfilled>: 123}
string PromiseObject:__tostring()
```

## Notes
1. Promises only can return one value, but async functions can receive many arguments
```lua
-- Wrong
promise.New(function(resolve)
    resolve("hello", "world") -- Promise will only return "hello"
end)

promise.Async(function(firstName, lastName)
    return "Hello", firstName, lastName -- Async function will only return "Hello"
end)

-- Good
promise.New(function(resolve)
    resolve("hello world") -- Promise will return "hello world"
end)

promise.Async(function(firstName, lastName)
    return "Hello " .. firstName .. " " .. lastName -- Promise will return "Hello Steven Universe"
end)
```

2. If error happened in async function, then it will have `addons/aaa/lua/bbb/ccc.lua:xyz:` string prepended. To avoid this behavior use `PromiseObject:SafeAwait()` and return `promise.Reject("my error")`
```lua
local function throwError(err)
    return promise.Reject(err)
end

local properlyHandledError = promise.Async(function()
    local ok, result = throwError("Error string!"):SafeAwait()
    if not ok then return promise.Reject(result) end

    -- ...
end)
```
