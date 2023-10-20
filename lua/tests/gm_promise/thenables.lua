local Promise = include("promise.lua")

local other = { other = "other" }

return {
    fulfilled = {
        ["a synchronously-fulfilled custom thenable"] = function(val)
            return {
                Then = function(self, onFulfilled) onFulfilled(val) end
            }
        end,

        ["an asynchronously-fulfilled custom thenable"] = function(val)
            return {
                Then = function(self, onFulfilled) timer.Simple(0, function() onFulfilled(val) end) end
            }
        end,

        ["a synchronously-fulfilled one-time thenable"] = function(val)
            return setmetatable({ thenWasRetrieved = false }, {
                __index = function(self, key)
                    if key == "Then" and not self.thenWasRetrieved then
                        self.thenWasRetrieved = true
                        return function(self, onFulfilled, onRejected)
                            onFulfilled(val)
                        end
                    end
                end
            })
        end,

        ["a thenable that tries to fulfill twice"] = function(val)
            return {
                Then = function(self, onFulfilled) 
                    onFulfilled(val)
                    onFulfilled(val)
                end
            } 
        end,

        ["a thenable that fulfills but then throws"] = function(val)
            return {
                Then = function(self, onFulfilled)
                    onFulfilled(val)
                    error(other)
                end
            }
        end,

        ["an already-fulfilled promise"] = function(val)
            return Promise.Resolve(val)
        end,

        ["an eventually-fulfilled promise"] = function(val)
            local p = Promise()
            timer.Simple(0.05, function() p:Resolve(val) end)
            return p
        end
    },

    rejected = {
        ["a synchronously-rejected custom thenable"] = function(val)
            return {
                Then = function(self, onFulfilled, onRejected) onRejected(val) end
            }
        end,

        ["an asynchronously-rejected custom thenable"] = function(val)
            return {
                Then = function(self, onFulfilled, onRejected) timer.Simple(0, function() onRejected(val) end) end
            }
        end,

        ["a synchronously-rejected one-time thenable"] = function(val)
            return setmetatable({ thenWasRetrieved = false }, {
                __index = function(self, key)
                    if key == "Then" and not self.thenWasRetrieved then
                        self.thenWasRetrieved = true
                        return function(self, onFulfilled, onRejected)
                            onRejected(val)
                        end
                    end
                end
            })
        end,

        ["a thenable that immediately throws in `then`"] = function(val)
            return {
                Then = function() error(val) end
            }
        end,

        ["an object with a throwing `then` accessor"] = function(val)
            return setmetatable({}, {
                __index = function(self, key)
                    if key == "Then" then
                        error(val)
                    end
                end
            })
        end,

        ["an already-rejected promise"] = function(val)
            return Promise.Reject(val)
        end,

        ["an eventually-rejected promise"] = function(val)
            local p = Promise()
            timer.Simple(0.05, function() p:Reject(val) end)
            return p
        end
    }
}
