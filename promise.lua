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
local isfunction = isfunction -- 24
local istable = istable -- 25
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
		STATE_PENDING = 1, -- 51
		STATE_FULFILLED = 2, -- 52
		STATE_REJECTED = 3, -- 54
		IsPromise = function(obj) -- 54
			return istable(obj) and obj.__class == Promise -- 54
		end, -- 68
		__tostring = function(self) -- 68
			local ptr = string.format("%p", self) -- 69
			local _exp_0 = self.state -- 70
			if self.STATE_PENDING == _exp_0 then -- 71
				return "Promise " .. tostring(ptr) .. " { <state>: \"pending\" }" -- 72
			elseif self.STATE_FULFILLED == _exp_0 then -- 73
				return "Promise " .. tostring(ptr) .. " { <state>: \"fulfilled\", <value>: " .. tostring(self.value) .. " }" -- 74
			elseif self.STATE_REJECTED == _exp_0 then -- 75
				return "Promise " .. tostring(ptr) .. " { <state>: \"rejected\", <reason>: " .. tostring(self.reason) .. " }" -- 76
			else -- 78
				return "Promise " .. tostring(ptr) .. " { <state>: \"invalid\" }" -- 78
			end -- 78
		end, -- 80
		_FinalizePromise = function(self, p) -- 80
			return xpcall(function() -- 81
				if self.state == self.STATE_FULFILLED then -- 82
					if p.on_fulfilled then -- 83
						p:Resolve(p.on_fulfilled(self.value)) -- 83
					else -- 84
						p:Resolve(self.value) -- 84
					end -- 83
				elseif self.state == self.STATE_REJECTED then -- 85
					if p.on_rejected then -- 86
						p:Resolve(p.on_rejected(self.reason)) -- 86
					else -- 87
						p:Reject(self.reason) -- 87
					end -- 86
				end -- 82
				if p.on_finally then -- 88
					return p.on_finally() -- 88
				end -- 88
			end, function(err) -- 88
				return p:Reject(err) -- 90
			end) -- 90
		end, -- 92
		_Finalize = function(self) -- 92
			if self.state == self.STATE_PENDING then -- 93
				return -- 93
			end -- 93
			if not self.queue then -- 94
				return -- 94
			end -- 94
			return nextTick(function() -- 95
				for i, p in ipairs(self.queue) do -- 96
					self:_FinalizePromise(p) -- 97
					self.queue[i] = nil -- 98
				end -- 98
			end) -- 98
		end, -- 100
		_Fulfill = function(self, value) -- 100
			self.state = self.STATE_FULFILLED -- 101
			self.value = value -- 102
			return self:_Finalize() -- 103
		end, -- 105
		_ResolveThenable = function(self, obj, thenable) -- 105
			local once_wrapper = once() -- 106
			local onFulfill = once_wrapper(function(value) -- 107
				return self:Resolve(value) -- 107
			end) -- 107
			local onReject = once_wrapper(function(reason) -- 108
				return self:Reject(reason) -- 108
			end) -- 108
			do -- 109
				local ok, err = pcall(thenable, obj, onFulfill, onReject) -- 109
				if not ok then -- 109
					return onReject(err) -- 110
				end -- 109
			end -- 109
		end, -- 112
		Resolve = function(self, value) -- 112
			if not (self.state == self.STATE_PENDING) then -- 113
				return -- 113
			end -- 113
			if value == self then -- 114
				return self:Reject("Cannot resolve a promise with itself") -- 114
			end -- 114
			self.on_fulfilled = nil -- 115
			self.on_rejected = nil -- 116
			if self.IsPromise(value) then -- 117
				if value.state == self.STATE_PENDING then -- 118
					if not value.queue then -- 119
						value.queue = { } -- 119
					end -- 119
					do -- 120
						local _obj_0 = value.queue -- 120
						_obj_0[#_obj_0 + 1] = self -- 120
					end -- 120
				else -- 122
					return value:_FinalizePromise(self) -- 122
				end -- 118
			elseif istable(value) then -- 123
				local ok, thenable = pcall(get_thenable, value) -- 124
				if not ok then -- 125
					return self:Reject(thenable) -- 125
				end -- 125
				if thenable then -- 127
					return self:_ResolveThenable(value, thenable) -- 128
				else -- 130
					return self:_Fulfill(value) -- 130
				end -- 127
			else -- 132
				return self:_Fulfill(value) -- 132
			end -- 117
		end, -- 136
		Reject = function(self, reason) -- 136
			if not (self.state == self.STATE_PENDING) then -- 137
				return -- 137
			end -- 137
			self.state = self.STATE_REJECTED -- 138
			self.reason = reason -- 139
			return self:_Finalize() -- 140
		end, -- 144
		Then = function(self, on_fulfilled, on_rejected, on_finally) -- 144
			local p = Promise() -- 145
			if iscallable(on_fulfilled) then -- 146
				p.on_fulfilled = on_fulfilled -- 146
			end -- 146
			if iscallable(on_rejected) then -- 147
				p.on_rejected = on_rejected -- 147
			end -- 147
			if iscallable(on_finally) then -- 148
				p.on_finally = on_finally -- 148
			end -- 148
			if not self.queue then -- 149
				self.queue = { } -- 149
			end -- 149
			do -- 150
				local _obj_0 = self.queue -- 150
				_obj_0[#_obj_0 + 1] = p -- 150
			end -- 150
			self:_Finalize() -- 151
			return p -- 152
		end, -- 158
		Catch = function(self, on_rejected) -- 158
			return self:Then(nil, on_rejected) -- 158
		end, -- 159
		Finally = function(self, on_finally) -- 159
			return self:Then(nil, nil, on_finally) -- 159
		end -- 45
	} -- 45
	if _base_0.__index == nil then -- 45
		_base_0.__index = _base_0 -- 45
	end -- 235
	_class_0 = setmetatable({ -- 45
		__init = function(self, executor) -- 56
			self.state = self.STATE_PENDING -- 57
			self.value = nil -- 58
			self.reason = nil -- 59
			self.queue = nil -- 60
			if iscallable(executor) then -- 62
				return xpcall(executor, function(err) -- 64
					return self:Reject(err) -- 66
				end, (function() -- 64
					local _base_1 = self -- 64
					local _fn_0 = _base_1.Resolve -- 64
					return _fn_0 and function(...) -- 64
						return _fn_0(_base_1, ...) -- 64
					end -- 64
				end)(), (function() -- 64
					local _base_1 = self -- 64
					local _fn_0 = _base_1.Reject -- 64
					return _fn_0 and function(...) -- 64
						return _fn_0(_base_1, ...) -- 64
					end -- 64
				end)()) -- 66
			end -- 62
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
	self.VERSION = "2.0.0" -- 46
	self.AUTHOR = "Retro" -- 47
	self.URL = "https://github.com/dankmolot/gm_promise" -- 48
	self.__base.resolve = self.__base.Resolve -- 134
	self.__base.reject = self.__base.Reject -- 142
	self.__base["then"] = self.__base.Then -- 154
	self.__base.next = self.__base.Then -- 155
	self.__base.andThen = self.__base.Then -- 156
	self.__base.catch = self.__base.Catch -- 160
	self.__base.finally = self.__base.Finally -- 161
	self.Resolve = function(value) -- 163
		local _with_0 = Promise() -- 164
		_with_0:Resolve(value) -- 165
		return _with_0 -- 164
	end -- 163
	self.resolve = self.Resolve -- 167
	self.Reject = function(reason) -- 169
		local _with_0 = Promise() -- 170
		_with_0:Reject(reason) -- 171
		return _with_0 -- 170
	end -- 169
	self.reject = self.Reject -- 173
	self.All = function(promises) -- 175
		local p = Promise() -- 176
		local count = #promises -- 177
		local values = { } -- 178
		if count == 0 then -- 179
			p:Resolve(values) -- 179
		end -- 179
		for i, promise in ipairs(promises) do -- 180
			if Promise.IsPromise(promise) then -- 181
				promise:Then(function(value) -- 182
					values[i] = value -- 183
					count = count - 1 -- 184
					if count == 0 then -- 185
						return p:Resolve(values) -- 185
					end -- 185
				end, function(self, reason) -- 186
					return p:Reject(reason) -- 186
				end) -- 182
			else -- 188
				values[i] = promise -- 188
				count = count - 1 -- 189
				if count == 0 then -- 190
					p:Resolve(values) -- 190
				end -- 190
			end -- 181
		end -- 190
		return p -- 191
	end -- 175
	self.all = self.All -- 193
	self.AllSettled = function(promises) -- 195
		local p = Promise() -- 196
		local count = #promises -- 197
		local values = { } -- 198
		if count == 0 then -- 199
			p:Resolve(values) -- 199
		end -- 199
		for i, promise in ipairs(promises) do -- 200
			promise:Then(function(value) -- 201
				values[i] = { -- 202
					status = "fulfilled", -- 202
					value = value -- 202
				} -- 202
				count = count - 1 -- 203
				if count == 0 then -- 204
					return p:Resolve(values) -- 204
				end -- 204
			end, function(reason) -- 205
				values[i] = { -- 206
					status = "rejected", -- 206
					reason = reason -- 206
				} -- 206
				count = count - 1 -- 207
				if count == 0 then -- 208
					return p:Resolve(values) -- 208
				end -- 208
			end) -- 201
		end -- 208
		return p -- 209
	end -- 195
	self.allSettled = self.AllSettled -- 211
	self.Any = function(promises) -- 213
		local p = Promise() -- 214
		local count = #promises -- 215
		local reasons = { } -- 216
		if count == 0 then -- 217
			p:Reject("No promises to resolve") -- 217
		end -- 217
		for i, promise in ipairs(promises) do -- 218
			promise:Then(function(value) -- 219
				return p:Resolve(value, function(reason) -- 220
					reasons[i] = reason -- 221
					count = count - 1 -- 222
					if count == 0 then -- 223
						return p:Resolve(reasons) -- 223
					end -- 223
				end) -- 223
			end) -- 219
		end -- 223
		return p -- 224
	end -- 213
	self.any = self.Any -- 226
	self.Race = function(promises) -- 228
		local p = Promise() -- 229
		for _index_0 = 1, #promises do -- 230
			local promise = promises[_index_0] -- 230
			promise:Then(function(value) -- 231
				return p:Resolve(value, function(reason) -- 232
					return p:Reject(reason) -- 232
				end) -- 232
			end) -- 231
		end -- 232
		return p -- 233
	end -- 228
	self.race = self.Race -- 235
	Promise = _class_0 -- 45
end -- 235
_module_0 = Promise -- 237
return _module_0 -- 237
