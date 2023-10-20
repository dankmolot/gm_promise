-- [yue]: promise.yue
local _module_0 = nil -- 1
--[[
    MIT License

    Copyright (c) 2023 Retro

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
--]]
local isfunction -- 24
isfunction = function(obj) -- 24
	return type(obj) == "function" -- 24
end -- 24
local istable -- 25
istable = function(obj) -- 25
	return type(obj) == "table" -- 25
end -- 25
local iscallable -- 26
iscallable = function(obj) -- 26
	if isfunction(obj) then -- 27
		return true -- 27
	end -- 27
	if istable(obj) then -- 28
		local meta = getmetatable(obj) -- 29
		return istable(meta) and isfunction(meta.__call) -- 30
	end -- 28
end -- 26
local get_thenable -- 31
get_thenable = function(obj) -- 31
	local then_fn = obj.Then -- 32
	return iscallable(then_fn) and then_fn -- 33
end -- 31
local nextTick -- 35
nextTick = function(fn) -- 35
	return timer.Simple(0, fn) -- 35
end -- 35
local once -- 37
once = function() -- 37
	local was_called = false -- 38
	return function(wrapped_fn) -- 39
		return function(...) -- 40
			if was_called then -- 41
				return ... -- 41
			end -- 41
			was_called = true -- 42
			return wrapped_fn(...) -- 43
		end -- 43
	end -- 43
end -- 37
local Promise -- 45
do -- 45
	local _class_0 -- 45
	local _base_0 = { -- 45
		STATE_PENDING = 1, -- 47
		STATE_FULFILLED = 2, -- 48
		STATE_REJECTED = 3, -- 50
		IsPromise = function(obj) -- 50
			return istable(obj) and obj.__class == Promise -- 50
		end, -- 64
		__tostring = function(self) -- 64
			local ptr = string.format("%p", self) -- 65
			local _exp_0 = self.state -- 66
			if self.STATE_PENDING == _exp_0 then -- 67
				return "Promise " .. tostring(ptr) .. " { <state>: \"pending\" }" -- 68
			elseif self.STATE_FULFILLED == _exp_0 then -- 69
				return "Promise " .. tostring(ptr) .. " { <state>: \"fulfilled\", <value>: " .. tostring(self.value) .. " }" -- 70
			elseif self.STATE_REJECTED == _exp_0 then -- 71
				return "Promise " .. tostring(ptr) .. " { <state>: \"rejected\", <reason>: " .. tostring(self.reason) .. " }" -- 72
			else -- 74
				return "Promise " .. tostring(ptr) .. " { <state>: \"invalid\" }" -- 74
			end -- 74
		end, -- 76
		_FinalizePromise = function(self, p) -- 76
			return xpcall(function() -- 77
				if self.state == self.STATE_FULFILLED then -- 78
					if p.on_fulfilled then -- 79
						p:Resolve(p.on_fulfilled(self.value)) -- 79
					else -- 80
						p:Resolve(self.value) -- 80
					end -- 79
				elseif self.state == self.STATE_REJECTED then -- 81
					if p.on_rejected then -- 82
						p:Resolve(p.on_rejected(self.reason)) -- 82
					else -- 83
						p:Reject(self.reason) -- 83
					end -- 82
				end -- 78
				if p.on_finally then -- 84
					return p.on_finally() -- 84
				end -- 84
			end, function(err) -- 84
				return p:Reject(err) -- 86
			end) -- 86
		end, -- 88
		_Finalize = function(self) -- 88
			if self.state == self.STATE_PENDING then -- 89
				return -- 89
			end -- 89
			if not self.queue then -- 90
				return -- 90
			end -- 90
			return nextTick(function() -- 91
				for i, p in ipairs(self.queue) do -- 92
					self:_FinalizePromise(p) -- 93
					self.queue[i] = nil -- 94
				end -- 94
			end) -- 94
		end, -- 96
		_Fulfill = function(self, value) -- 96
			self.state = self.STATE_FULFILLED -- 97
			self.value = value -- 98
			return self:_Finalize() -- 99
		end, -- 101
		_ResolveThenable = function(self, obj, thenable) -- 101
			local once_wrapper = once() -- 102
			local onFulfill = once_wrapper(function(value) -- 103
				return self:Resolve(value) -- 103
			end) -- 103
			local onReject = once_wrapper(function(reason) -- 104
				return self:Reject(reason) -- 104
			end) -- 104
			do -- 105
				local ok, err = pcall(thenable, obj, onFulfill, onReject) -- 105
				if not ok then -- 105
					return onReject(err) -- 106
				end -- 105
			end -- 105
		end, -- 108
		Resolve = function(self, value) -- 108
			if not (self.state == self.STATE_PENDING) then -- 109
				return -- 109
			end -- 109
			if value == self then -- 110
				return self:Reject("Cannot resolve a promise with itself") -- 110
			end -- 110
			self.on_fulfilled = nil -- 111
			self.on_rejected = nil -- 112
			if self.IsPromise(value) then -- 113
				if value.state == self.STATE_PENDING then -- 114
					if not value.queue then -- 115
						value.queue = { } -- 115
					end -- 115
					do -- 116
						local _obj_0 = value.queue -- 116
						_obj_0[#_obj_0 + 1] = self -- 116
					end -- 116
				else -- 118
					return value:_FinalizePromise(self) -- 118
				end -- 114
			elseif istable(value) then -- 119
				local ok, thenable = pcall(get_thenable, value) -- 120
				if not ok then -- 121
					return self:Reject(thenable) -- 121
				end -- 121
				if thenable then -- 123
					return self:_ResolveThenable(value, thenable) -- 124
				else -- 126
					return self:_Fulfill(value) -- 126
				end -- 123
			else -- 128
				return self:_Fulfill(value) -- 128
			end -- 113
		end, -- 130
		Reject = function(self, reason) -- 130
			if not (self.state == self.STATE_PENDING) then -- 131
				return -- 131
			end -- 131
			self.state = self.STATE_REJECTED -- 132
			self.reason = reason -- 133
			return self:_Finalize() -- 134
		end, -- 136
		Then = function(self, on_fulfilled, on_rejected, on_finally) -- 136
			local p = Promise() -- 137
			if iscallable(on_fulfilled) then -- 138
				p.on_fulfilled = on_fulfilled -- 138
			end -- 138
			if iscallable(on_rejected) then -- 139
				p.on_rejected = on_rejected -- 139
			end -- 139
			if iscallable(on_finally) then -- 140
				p.on_finally = on_finally -- 140
			end -- 140
			if not self.queue then -- 141
				self.queue = { } -- 141
			end -- 141
			do -- 142
				local _obj_0 = self.queue -- 142
				_obj_0[#_obj_0 + 1] = p -- 142
			end -- 142
			self:_Finalize() -- 143
			return p -- 144
		end, -- 146
		Catch = function(self, on_rejected) -- 146
			return self:Then(nil, on_rejected) -- 146
		end, -- 147
		Finally = function(self, on_finally) -- 147
			return self:Then(nil, nil, on_finally) -- 147
		end -- 45
	} -- 45
	if _base_0.__index == nil then -- 45
		_base_0.__index = _base_0 -- 45
	end -- 209
	_class_0 = setmetatable({ -- 45
		__init = function(self, executor) -- 52
			self.state = self.STATE_PENDING -- 53
			self.value = nil -- 54
			self.reason = nil -- 55
			self.queue = nil -- 56
			if iscallable(executor) then -- 58
				return xpcall(executor, function(err) -- 60
					return self:Reject(err) -- 62
				end, (function() -- 60
					local _base_1 = self -- 60
					local _fn_0 = _base_1.Resolve -- 60
					return _fn_0 and function(...) -- 60
						return _fn_0(_base_1, ...) -- 60
					end -- 60
				end)(), (function() -- 60
					local _base_1 = self -- 60
					local _fn_0 = _base_1.Reject -- 60
					return _fn_0 and function(...) -- 60
						return _fn_0(_base_1, ...) -- 60
					end -- 60
				end)()) -- 62
			end -- 58
		end, -- 45
		__base = _base_0, -- 45
		__name = "Promise" -- 45
	}, { -- 45
		__index = _base_0, -- 45
		__call = function(cls, ...) -- 45
			local _self_0 = setmetatable({ }, _base_0) -- 45
			cls.__init(_self_0, ...) -- 45
			return _self_0 -- 45
		end -- 45
	}) -- 45
	_base_0.__class = _class_0 -- 45
	local self = _class_0; -- 45
	self.Resolve = function(value) -- 149
		local _with_0 = Promise() -- 150
		_with_0:Resolve(value) -- 151
		return _with_0 -- 150
	end -- 149
	self.Reject = function(reason) -- 153
		local _with_0 = Promise() -- 154
		_with_0:Reject(reason) -- 155
		return _with_0 -- 154
	end -- 153
	self.All = function(promises) -- 157
		local p = Promise() -- 158
		local count = #promises -- 159
		local values = { } -- 160
		if count == 0 then -- 161
			p:Resolve(values) -- 161
		end -- 161
		for i, promise in ipairs(promises) do -- 162
			if Promise.IsPromise(promise) then -- 163
				promise:Then(function(value) -- 164
					values[i] = value -- 165
					count = count - 1 -- 166
					if count == 0 then -- 167
						return p:Resolve(values) -- 167
					end -- 167
				end, function(self, reason) -- 168
					return p:Reject(reason) -- 168
				end) -- 164
			else -- 170
				values[i] = promise -- 170
				count = count - 1 -- 171
				if count == 0 then -- 172
					p:Resolve(values) -- 172
				end -- 172
			end -- 163
		end -- 172
		return p -- 173
	end -- 157
	self.AllSettled = function(promises) -- 175
		local p = Promise() -- 176
		local count = #promises -- 177
		local values = { } -- 178
		if count == 0 then -- 179
			p:Resolve(values) -- 179
		end -- 179
		for i, promise in ipairs(promises) do -- 180
			promise:Then(function(value) -- 181
				values[i] = { -- 182
					status = "fulfilled", -- 182
					value = value -- 182
				} -- 182
				count = count - 1 -- 183
				if count == 0 then -- 184
					return p:Resolve(values) -- 184
				end -- 184
			end, function(reason) -- 185
				values[i] = { -- 186
					status = "rejected", -- 186
					reason = reason -- 186
				} -- 186
				count = count - 1 -- 187
				if count == 0 then -- 188
					return p:Resolve(values) -- 188
				end -- 188
			end) -- 181
		end -- 188
		return p -- 189
	end -- 175
	self.Any = function(promises) -- 191
		local p = Promise() -- 192
		local count = #promises -- 193
		local reasons = { } -- 194
		if count == 0 then -- 195
			p:Reject("No promises to resolve") -- 195
		end -- 195
		for i, promise in ipairs(promises) do -- 196
			promise:Then(function(value) -- 197
				return p:Resolve(value, function(reason) -- 198
					reasons[i] = reason -- 199
					count = count - 1 -- 200
					if count == 0 then -- 201
						return p:Resolve(reasons) -- 201
					end -- 201
				end) -- 201
			end) -- 197
		end -- 201
		return p -- 202
	end -- 191
	self.Race = function(promises) -- 204
		local p = Promise() -- 205
		for _index_0 = 1, #promises do -- 206
			local promise = promises[_index_0] -- 206
			promise:Then(function(value) -- 207
				return p:Resolve(value, function(reason) -- 208
					return p:Reject(reason) -- 208
				end) -- 208
			end) -- 207
		end -- 208
		return p -- 209
	end -- 204
	Promise = _class_0 -- 45
end -- 209
_module_0 = Promise -- 211
return _module_0 -- 211
