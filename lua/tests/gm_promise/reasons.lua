local Promise = include("promise.lua")

return {
    ["`nil`"] = function() return nil end,
    ["`false`"] = function() return false end,
    -- ["`0`"] = function() return 1.23 end, -- sadly, error(...) converts number into string
    ["a table"] = function() return {} end,
    ["an userdata"] = function() return newproxy() end,
    ["an always-pending thenable"] = function() return { Then = function()end } end,
    ["a fulfilled promise"] = function() return Promise.Resolve() end,
    ["a rejected promise"] = function() return Promise.Reject() end,
}
