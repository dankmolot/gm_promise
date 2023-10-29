# gm_promise
<a href="https://promisesaplus.com/">
    <img src="https://promisesaplus.com/assets/logo-small.png" alt="Promises/A+ logo"
         title="Promises/A+ 1.1 compliant" align="right" />
</a>

[Promise/A+](https://promisesaplus.com) compliant implementation written for Garry's Mod written in Yuescript

Promises represent the result of an operation which will complete in the future. They can be passed around, chained onto, and can help to flatten out deeply nested callback code, and simplify error handling to some degree.

This library has a lot of similarities [JS Promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise),
so checkout them.

Also there are many, and much better, introductions to promise patterns.
* https://www.promisejs.org/
* https://www.promisejs.org/patterns/

This library is dependent on [gm_error]

## Installation
Copy [`promise.lua`](/promise.lua) 
and [`error.lua`](https://github.com/dankmolot/gm_error/blob/main/error.lua) (from [gm_error])
into your project and then include it
```lua
local Promise = include("promise.lua")
```

If you want to include promises in clientside, do not forget to `AddCSLuaFile` them
```lua
AddCSLuaFile("error.lua")
AddCSLuaFile("promise.lua")
```

## Examples
```lua
local Promise = include("promise.lua")

local p = Promise()
p:Resolve(123)

p:Then(function(value)
    print("Promise was fulfilled with", value)
end, function(reason)
    print("Promise was rejected with", value)
end)
-- Will print 'Promise was fulfilled with 123'
```

```lua
local p = Promise(function(resolve, reject)
    resolve("hello world")
end)

print(p) -- Will print 'Promise 0x12345678 { <state>: "fulfilled", <value>: hello world }'
```

```lua
local p = Promise()
timer.Simple(1, function()
    p:Resolve()
end)

p:Then(function()
    print("Promise fulfilled!")
end)
-- 'Promise fulfilled' will be printed after 1 second
```

```lua
local Promise = include("promise.lua")
local Error = include("error.lua").Error

local p = Promise()
p:Reject( Error("Whoops!") )

p:Catch(function(reason)
    print(reason)
    -- Will print 'xxx/yyy/zzz.lua:123: Error: Whoops!'
end)
```

```lua
local Promise = include("promise.lua")
local Error = include("error.lua").Error

local function AsyncFetch(url)
    local p = Promise()
    http.Fetch(url,
        -- onSuccess
        function(body, length, headers, code)
            p:Resolve({
                body = body,
                length = length,
                headers = headers,
                code = code
            })
        end,

        -- onFailure
        function(message)
            p:Reject(Error(message))
        end
    )
    return p
end

local function AsyncJSONFetch(url)
    return AsyncFetch(url):Then(function(data)
        return util.JSONToTable(data.body)
    end)
end

AsyncJSONFetch("https://example.com"):Then(function(data)
    -- `data` will be a table that is parsed from json from example.com
    PrintTable(data)
end):Catch(function(err)
    print("Failed to fetch example.com:", err)
end)
```

## Usage
### Promise()
Creates a new promise that can be resolved or rejected
```lua
local p = Promise()
p:Then(callback):Catch(callback):Finally(callback)
```

### Promise(executor)
Creates a new promise that will be resolved or rejected by executor
Executor receives two functions, `resolve` and `reject`.
If executor throws and error, then the promise will be rejected.
```lua
local p = Promise(function(resolve, reject)
    resolve("Hello World")
end)

p:Then(function(value)
    print(value == "Hello World") -- true
end)
```

### promise:Then(onFulfilled, onRejected, onFinally)
Queues `onFulfilled`, `onRejected` and `onFinally` callbacks,
and `promise` will call them after promise will be resolved.

Returns *a new* promise

Alternative names: `promise:next(...)`, `promise:andThen(...)`, `promise:then(...)`

### promise:Catch(onRejected)
Same as calling [`promise:Then(nil, onRejected)`](#promisethenonfulfilled-onrejected-onfinally)

Alternative name: `promise:catch(...)`

### promise:Finally(onFinally)
Same as calling [`promise:Then(nil, nil, onFinally)`](#promisethenonfulfilled-onrejected-onfinally)

Alternative name: `promise:finally(...)`

### promise:Resolve(value)
Resolves `promise` with passed `value`.
If `promise` already resolved or rejected, does nothing.

Alternative name: `promise:resolve(...)`

### promise:Reject(reason)
Rejects `promise` with passed `reason`.
If `promise` already resolved or rejected, does nothing.

Alternative name: `promise:resolve(...)`

### Promise.Resolve(value)
Returns a new promise that is resolved with passed `value`.

Alternative name: `Promise.resolve(...)`

### Promise.Reject(reason)
Returns a new promise that is rejected with passed `reason`.

Alternative name: `Promise.reject(...)`

### Promise.All(promises)
Returns a new promise that will be resolved with fulfilled values from `promises`.
If all promises are rejected, then returned promise will be rejected.
`promises` must be a list of promises.

Alternative name: `Promise.all(...)`

### Promise.AllSettled(promises)
Returns a new promise that will be resolved with values like `{ status = "fulfilled", value = ... }` or `{ status = "rejected" , reason = ... }`.
`promises` must be a list of promises.

Alternative name: `Promise.allSettled(...)`

### Promise.Any(promises)
Returns a new promise that will be resolved with first fulfilled promise.
If all promises are rejected, then returned promise will be rejected.

Alternative name: `Promise.any(...)`

### Promise.Race(promises)
Returns a new promise that will be fulfilled/rejected with first resolved promise.

Alternative name: `Promise.race(...)`

### Promise.Delay(time, value)
Returns a new promise that will be resolved with `value` after `time` (in seconds)

Alternative name: `Promise.delay(...)`

### Promise.HTTP(parameters)
Same as [HTTP](https://wiki.facepunch.com/gmod/Global.HTTP) but will return a new Promise that will be fulfilled or rejected with response from HTTP.

Fulfill value is `{ code = ..., body = "...", headers = {...} }`
Reject value is [`HTTPError`](#promisehttperror) with a reason of error.

Alternative name: `Promise.http(...)`

### Promise.Async(func)
Wraps around given function. Returned function will call `func` in coroutine thread, will allow to [await](#promiseawait) promises and return a new promise that will be fulfilled with `func` return value, or rejected with error from `func`.

Alternative name: `Promise.async(...)`

```lua
local async = Promise.Async
local await = Promise.Await

local fn = async(function()
    await( Promise.delay(1) ) -- Waits for one second
    return "hello world"
end)

local p = fn()
-- p is a promise that will be resolved with "hello world" after 1 second
```

### promise:Await()
Asynchronously waits for promise to resolve. Returns a value if promise was fulfilled, or throws a reason.

Alternative name: `Promise:await()`

```lua
local async = Promise.async
local fn = async(function()
    local value = Promise.Delay(1, "hello world"):Await()
    print(value == "hello world") -- true
end)

fn()
```

### promise:SafeAwait()
Same as [`promise:Await()`](#promiseawait), but returns two values instead.

Returns `true` and value if promise was fulfilled. Returns `false` and reason if promise was rejected.

Alternative name: `Promise:saveAwait()`

```lua
local async = Promise.async
local fn = async(function()
    local ok, value = Promise.Delay(1, "hello world"):SafeAwait()
    print(ok) -- true
    print(value) -- hello world
end)

fn()
```

### Promise.HTTPError
Just an extended class from `Error` that is used to reject a promise in [`Promise.HTTP(...)`](#promisehttpparameters)

## Differences from the Promises/A+ Spec
* [1.2](https://promisesaplus.com/#point-7) `then` is reserved keyword in Lua. `Then`, `next` or `andThen` must be used instead.
* [1.3](https://promisesaplus.com/#point-8) Lua have only type `nil`, there is no `undefined`
* [2.2.5](https://promisesaplus.com/#point-35) Lua method calls do not have a `this` equivalent. The `self` syntactic sugar for `self` is determined by method arguments.
* [2.3.1]("https://promisesaplus.com/#point-48") `TypeError` error object is used from [gm_error], since Lua does not have own error objects.
* [2.3.3.3]("https://promisesaplus.com/#point-56") Lua method calls do not have a `this` equivalent. `Then` will be called with the first argument of x instead.

## Credits
This README is inspired by [promise.lua](https://github.com/Billiam/promise.lua). Thanks to him for writing good README :)

Related projects:
* [promise.lua](https://github.com/Billiam/promise.lua)
* [AndThen](https://github.com/ppissanetzky/AndThen)
* [lua_promise](https://github.com/friesencr/lua_promise)
* [lua-promise](https://github.com/dmccuskey/lua-promise)
* [next.lua](https://github.com/pmachowski/next-lua)
* [promise](https://github.com/Olivine-Labs/promise)

[gm_error]:https://github.com/dankmolot/gm_error
