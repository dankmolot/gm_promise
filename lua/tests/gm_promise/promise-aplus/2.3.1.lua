local Promise = include("../promise.lua")

return {
    groupName = "2.3.1: If `promise` and `x` refer to the same object, reject `promise` with a `TypeError' as the reason.",
    cases = {
        {
            name = "via return from a fulfilled promise",
            async = true,
            timeout = 1,
            func = function()
                local promise = Promise.Resolve()
                promise = promise:Then(function()
                    return promise
                end)
                
                promise:Then(nil, function(reason)
                    -- FIXME expect reason to be a TypeError
                    expect(reason).to.exist()
                    done()
                end)
            end
        },
        {
            name = "via return from a rejected promise",
            async = true,
            timeout = 1,
            func = function()
                local promise = Promise.Reject()
                promise = promise:Then(nil, function()
                    return promise
                end)

                promise:Then(nil, function(reason)
                    -- FIXME expect reason to be a TypeError
                    expect(reason).to.exist()
                    done()
                end)
            end
        }
    }
}
