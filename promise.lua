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
		end, -- 132
		Reject = function(self, reason) -- 132
			if not (self.state == self.STATE_PENDING) then -- 133
				return -- 133
			end -- 133
			self.state = self.STATE_REJECTED -- 134
			self.reason = reason -- 135
			return self:_Finalize() -- 136
		end, -- 140
		Then = function(self, on_fulfilled, on_rejected, on_finally) -- 140
			local p = Promise() -- 141
			if iscallable(on_fulfilled) then -- 142
				p.on_fulfilled = on_fulfilled -- 142
			end -- 142
			if iscallable(on_rejected) then -- 143
				p.on_rejected = on_rejected -- 143
			end -- 143
			if iscallable(on_finally) then -- 144
				p.on_finally = on_finally -- 144
			end -- 144
			if not self.queue then -- 145
				self.queue = { } -- 145
			end -- 145
			do -- 146
				local _obj_0 = self.queue -- 146
				_obj_0[#_obj_0 + 1] = p -- 146
			end -- 146
			self:_Finalize() -- 147
			return p -- 148
		end, -- 154
		Catch = function(self, on_rejected) -- 154
			return self:Then(nil, on_rejected) -- 154
		end, -- 155
		Finally = function(self, on_finally) -- 155
			return self:Then(nil, nil, on_finally) -- 155
		end -- 45
	} -- 45
	if _base_0.__index == nil then -- 45
		_base_0.__index = _base_0 -- 45
	end -- 231
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
	self.__base.resolve = self.__base.Resolve -- 130
	self.__base.reject = self.__base.Reject -- 138
	self.__base["then"] = self.__base.Then -- 150
	self.__base.next = self.__base.Then -- 151
	self.__base.andThen = self.__base.Then -- 152
	self.__base.catch = self.__base.Catch -- 156
	self.__base.finally = self.__base.Finally -- 157
	self.Resolve = function(value) -- 159
		local _with_0 = Promise() -- 160
		_with_0:Resolve(value) -- 161
		return _with_0 -- 160
	end -- 159
	self.resolve = self.Resolve -- 163
	self.Reject = function(reason) -- 165
		local _with_0 = Promise() -- 166
		_with_0:Reject(reason) -- 167
		return _with_0 -- 166
	end -- 165
	self.reject = self.Reject -- 169
	self.All = function(promises) -- 171
		local p = Promise() -- 172
		local count = #promises -- 173
		local values = { } -- 174
		if count == 0 then -- 175
			p:Resolve(values) -- 175
		end -- 175
		for i, promise in ipairs(promises) do -- 176
			if Promise.IsPromise(promise) then -- 177
				promise:Then(function(value) -- 178
					values[i] = value -- 179
					count = count - 1 -- 180
					if count == 0 then -- 181
						return p:Resolve(values) -- 181
					end -- 181
				end, function(self, reason) -- 182
					return p:Reject(reason) -- 182
				end) -- 178
			else -- 184
				values[i] = promise -- 184
				count = count - 1 -- 185
				if count == 0 then -- 186
					p:Resolve(values) -- 186
				end -- 186
			end -- 177
		end -- 186
		return p -- 187
	end -- 171
	self.all = self.All -- 189
	self.AllSettled = function(promises) -- 191
		local p = Promise() -- 192
		local count = #promises -- 193
		local values = { } -- 194
		if count == 0 then -- 195
			p:Resolve(values) -- 195
		end -- 195
		for i, promise in ipairs(promises) do -- 196
			promise:Then(function(value) -- 197
				values[i] = { -- 198
					status = "fulfilled", -- 198
					value = value -- 198
				} -- 198
				count = count - 1 -- 199
				if count == 0 then -- 200
					return p:Resolve(values) -- 200
				end -- 200
			end, function(reason) -- 201
				values[i] = { -- 202
					status = "rejected", -- 202
					reason = reason -- 202
				} -- 202
				count = count - 1 -- 203
				if count == 0 then -- 204
					return p:Resolve(values) -- 204
				end -- 204
			end) -- 197
		end -- 204
		return p -- 205
	end -- 191
	self.allSettled = self.AllSettled -- 207
	self.Any = function(promises) -- 209
		local p = Promise() -- 210
		local count = #promises -- 211
		local reasons = { } -- 212
		if count == 0 then -- 213
			p:Reject("No promises to resolve") -- 213
		end -- 213
		for i, promise in ipairs(promises) do -- 214
			promise:Then(function(value) -- 215
				return p:Resolve(value, function(reason) -- 216
					reasons[i] = reason -- 217
					count = count - 1 -- 218
					if count == 0 then -- 219
						return p:Resolve(reasons) -- 219
					end -- 219
				end) -- 219
			end) -- 215
		end -- 219
		return p -- 220
	end -- 209
	self.any = self.Any -- 222
	self.Race = function(promises) -- 224
		local p = Promise() -- 225
		for _index_0 = 1, #promises do -- 226
			local promise = promises[_index_0] -- 226
			promise:Then(function(value) -- 227
				return p:Resolve(value, function(reason) -- 228
					return p:Reject(reason) -- 228
				end) -- 228
			end) -- 227
		end -- 228
		return p -- 229
	end -- 224
	self.race = self.Race -- 231
	Promise = _class_0 -- 45
end -- 231
_module_0 = Promise -- 233
return _module_0 -- 233
