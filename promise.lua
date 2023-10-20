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
		end, -- 134
		Reject = function(self, reason) -- 134
			if not (self.state == self.STATE_PENDING) then -- 135
				return -- 135
			end -- 135
			self.state = self.STATE_REJECTED -- 136
			self.reason = reason -- 137
			return self:_Finalize() -- 138
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
		end, -- 150
		Catch = function(self, on_rejected) -- 150
			return self:Then(nil, on_rejected) -- 150
		end, -- 151
		Finally = function(self, on_finally) -- 151
			return self:Then(nil, nil, on_finally) -- 151
		end, -- 227
		SafeAwait = function(p) -- 227
			local co = coroutine.running() -- 228
			if not co then -- 229
				return false, "Cannot await in main thread" -- 229
			end -- 229
			local once_wrapper = once() -- 231
			local onResolve = once_wrapper(function(value) -- 232
				return coroutine.resume(co, true, value) -- 232
			end) -- 232
			local onReject = once_wrapper(function(reason) -- 233
				return coroutine.resume(co, false, reason) -- 233
			end) -- 233
			if Promise.IsPromise(p) then -- 235
				local _exp_0 = p.state -- 236
				if p.STATE_FULFILLED == _exp_0 then -- 237
					return true, p.value -- 238
				elseif p.STATE_REJECTED == _exp_0 then -- 239
					return false, p.reason -- 240
				else -- 242
					p:Then(onResolve, onReject) -- 242
					return coroutine.yield() -- 243
				end -- 243
			else -- 244
				do -- 244
					local thenable = get_thenable(p) -- 244
					if thenable then -- 244
						if iscallable(thenable) then -- 245
pcall(thenable, p, onResolve, onReject) -- 246
							return coroutine.yield() -- 247
						else -- 249
							return true, p -- 249
						end -- 245
					else -- 251
						return true, p -- 251
					end -- 244
				end -- 244
			end -- 235
		end, -- 253
		Await = function(p) -- 253
			local ok, result = Promise.SafeAwait(p) -- 254
			if ok then -- 255
				return result -- 255
			else -- 256
				return error(result) -- 256
			end -- 255
		end -- 45
	} -- 45
	if _base_0.__index == nil then -- 45
		_base_0.__index = _base_0 -- 45
	end -- 274
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
	self.Resolve = function(value) -- 153
		local _with_0 = Promise() -- 154
		_with_0:Resolve(value) -- 155
		return _with_0 -- 154
	end -- 153
	self.Reject = function(reason) -- 157
		local _with_0 = Promise() -- 158
		_with_0:Reject(reason) -- 159
		return _with_0 -- 158
	end -- 157
	self.All = function(promises) -- 161
		local p = Promise() -- 162
		local count = #promises -- 163
		local values = { } -- 164
		if count == 0 then -- 165
			p:Resolve(values) -- 165
		end -- 165
		for i, promise in ipairs(promises) do -- 166
			if Promise.IsPromise(promise) then -- 167
				promise:Then(function(value) -- 168
					values[i] = value -- 169
					count = count - 1 -- 170
					if count == 0 then -- 171
						return p:Resolve(values) -- 171
					end -- 171
				end, function(self, reason) -- 172
					return p:Reject(reason) -- 172
				end) -- 168
			else -- 174
				values[i] = promise -- 174
				count = count - 1 -- 175
				if count == 0 then -- 176
					p:Resolve(values) -- 176
				end -- 176
			end -- 167
		end -- 176
		return p -- 177
	end -- 161
	self.AllSettled = function(promises) -- 179
		local p = Promise() -- 180
		local count = #promises -- 181
		local values = { } -- 182
		if count == 0 then -- 183
			p:Resolve(values) -- 183
		end -- 183
		for i, promise in ipairs(promises) do -- 184
			promise:Then(function(value) -- 185
				values[i] = { -- 186
					status = "fulfilled", -- 186
					value = value -- 186
				} -- 186
				count = count - 1 -- 187
				if count == 0 then -- 188
					return p:Resolve(values) -- 188
				end -- 188
			end, function(reason) -- 189
				values[i] = { -- 190
					status = "rejected", -- 190
					reason = reason -- 190
				} -- 190
				count = count - 1 -- 191
				if count == 0 then -- 192
					return p:Resolve(values) -- 192
				end -- 192
			end) -- 185
		end -- 192
		return p -- 193
	end -- 179
	self.Any = function(promises) -- 195
		local p = Promise() -- 196
		local count = #promises -- 197
		local reasons = { } -- 198
		if count == 0 then -- 199
			p:Reject("No promises to resolve") -- 199
		end -- 199
		for i, promise in ipairs(promises) do -- 200
			promise:Then(function(value) -- 201
				return p:Resolve(value, function(reason) -- 202
					reasons[i] = reason -- 203
					count = count - 1 -- 204
					if count == 0 then -- 205
						return p:Resolve(reasons) -- 205
					end -- 205
				end) -- 205
			end) -- 201
		end -- 205
		return p -- 206
	end -- 195
	self.Race = function(promises) -- 208
		local p = Promise() -- 209
		for _index_0 = 1, #promises do -- 210
			local promise = promises[_index_0] -- 210
			promise:Then(function(value) -- 211
				return p:Resolve(value, function(reason) -- 212
					return p:Reject(reason) -- 212
				end) -- 212
			end) -- 211
		end -- 212
		return p -- 213
	end -- 208
	self.Async = function(fn) -- 215
		return function(...) -- 215
			local p = Promise() -- 216
			local co = coroutine.create(function(...) -- 217
				do -- 218
					local success, result = xpcall(fn, function(err) -- 218
						-- TODO save stacktrace and pass it to reject
						return p:Reject(err) -- 221
					end, ...) -- 218
					if success then -- 218
						return p:Resolve(result) -- 222
					end -- 218
				end -- 221
			end) -- 217
			coroutine.resume(co, ...) -- 224
			return p -- 225
		end -- 225
	end -- 215
	self.__base.await = self.__base.Await -- 259
	self.__base.resolve = self.__base.Resolve -- 260
	self.__base.reject = self.__base.Reject -- 261
	self.__base["then"] = self.__base.Then -- 262
	self.__base.next = self.__base.Then -- 263
	self.__base.andThen = self.__base.Then -- 264
	self.__base.catch = self.__base.Catch -- 265
	self.__base.finally = self.__base.Finally -- 266
	self.__base.saveAwait = self.__base.SafeAwait -- 267
	self.resolve = self.Resolve -- 268
	self.reject = self.Reject -- 269
	self.all = self.All -- 270
	self.allSettled = self.AllSettled -- 271
	self.any = self.Any -- 272
	self.race = self.Race -- 273
	self.async = self.Async -- 274
	Promise = _class_0 -- 45
end -- 274
_module_0 = Promise -- 276
return _module_0 -- 276
