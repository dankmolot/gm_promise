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
	local then_fn = obj.Then or obj.next -- 32
	return iscallable(then_fn) and then_fn -- 33
end -- 31
local get_awaitable -- 34
get_awaitable = function(obj) -- 34
	local awaitable = obj.Await or obj.await -- 35
	return iscallable(awaitable) and awaitable -- 36
end -- 34
local nextTick -- 38
nextTick = function(fn) -- 38
	return timer.Simple(0, fn) -- 38
end -- 38
local once -- 40
once = function() -- 40
	local was_called = false -- 41
	return function(wrapped_fn) -- 42
		return function(...) -- 43
			if was_called then -- 44
				return ... -- 44
			end -- 44
			was_called = true -- 45
			return wrapped_fn(...) -- 46
		end -- 46
	end -- 46
end -- 40
local Promise -- 48
do -- 48
	local _class_0 -- 48
	local _base_0 = { -- 48
		STATE_PENDING = 1, -- 54
		STATE_FULFILLED = 2, -- 55
		STATE_REJECTED = 3, -- 57
		IsPromise = function(obj) -- 57
			return istable(obj) and obj.__class == Promise -- 57
		end, -- 76
		__tostring = function(self) -- 76
			local ptr = string.format("%p", self) -- 77
			local _exp_0 = self.state -- 78
			if self.STATE_PENDING == _exp_0 then -- 79
				return "Promise " .. tostring(ptr) .. " { <state>: \"pending\" }" -- 80
			elseif self.STATE_FULFILLED == _exp_0 then -- 81
				return "Promise " .. tostring(ptr) .. " { <state>: \"fulfilled\", <value>: " .. tostring(self.value) .. " }" -- 82
			elseif self.STATE_REJECTED == _exp_0 then -- 83
				return "Promise " .. tostring(ptr) .. " { <state>: \"rejected\", <reason>: " .. tostring(self.reason) .. " }" -- 84
			else -- 86
				return "Promise " .. tostring(ptr) .. " { <state>: \"invalid\" }" -- 86
			end -- 86
		end, -- 88
		_FinalizePromise = function(self, p) -- 88
			return xpcall(function() -- 89
				if self.state == self.STATE_FULFILLED then -- 90
					if p.on_fulfilled then -- 91
						p:_Resolve(p.on_fulfilled(self.value)) -- 91
					else -- 92
						p:_Resolve(self.value) -- 92
					end -- 91
				elseif self.state == self.STATE_REJECTED then -- 93
					if p.on_rejected then -- 94
						p:_Resolve(p.on_rejected(self.reason)) -- 94
					else -- 95
						p:_Reject(self.reason) -- 95
					end -- 94
				end -- 90
				if p.on_finally then -- 96
					return p.on_finally() -- 96
				end -- 96
			end, function(err) -- 96
				return p:_Reject(err) -- 98
			end) -- 98
		end, -- 100
		_Finalize = function(self) -- 100
			if self.state == self.STATE_PENDING then -- 101
				return -- 101
			end -- 101
			if not self.queue then -- 102
				return -- 102
			end -- 102
			return nextTick(function() -- 103
				for i, p in ipairs(self.queue) do -- 104
					self:_FinalizePromise(p) -- 105
					self.queue[i] = nil -- 106
				end -- 106
			end) -- 106
		end, -- 108
		_Fulfill = function(self, value) -- 108
			self.state = self.STATE_FULFILLED -- 109
			self.value = value -- 110
			return self:_Finalize() -- 111
		end, -- 113
		_ResolveThenable = function(self, obj, thenable) -- 113
			local once_wrapper = once() -- 114
			local onFulfill = once_wrapper(function(value) -- 115
				return self:_Resolve(value) -- 115
			end) -- 115
			local onReject = once_wrapper(function(reason) -- 116
				return self:_Reject(reason) -- 116
			end) -- 116
			do -- 117
				local ok, err = pcall(thenable, obj, onFulfill, onReject) -- 117
				if not ok then -- 117
					return onReject(err) -- 118
				end -- 117
			end -- 117
		end, -- 120
		_Resolve = function(self, value) -- 120
			if self.state ~= self.STATE_PENDING then -- 121
				return -- 121
			end -- 121
			if value == self then -- 122
				return self:_Reject("Cannot resolve a promise with itself") -- 122
			end -- 122
			self.resolving = true -- 123
			self.on_fulfilled = nil -- 124
			self.on_rejected = nil -- 125
			self.on_finally = nil -- 126
			if self.IsPromise(value) then -- 127
				if value.state == self.STATE_PENDING then -- 128
					if not value.queue then -- 129
						value.queue = { } -- 129
					end -- 129
					do -- 130
						local _obj_0 = value.queue -- 130
						_obj_0[#_obj_0 + 1] = self -- 130
					end -- 130
				else -- 132
					return value:_FinalizePromise(self) -- 132
				end -- 128
			elseif istable(value) then -- 133
				local ok, thenable = pcall(get_thenable, value) -- 134
				if not ok then -- 135
					return self:_Reject(thenable) -- 135
				end -- 135
				if thenable then -- 137
					return self:_ResolveThenable(value, thenable) -- 138
				else -- 140
					return self:_Fulfill(value) -- 140
				end -- 137
			else -- 142
				return self:_Fulfill(value) -- 142
			end -- 127
		end, -- 144
		Resolve = function(self, value) -- 144
			if self.resolving then -- 145
				return -- 145
			end -- 145
			return self:_Resolve(value) -- 146
		end, -- 148
		_Reject = function(self, reason) -- 148
			if not (self.state == self.STATE_PENDING) then -- 149
				return -- 149
			end -- 149
			self.state = self.STATE_REJECTED -- 150
			self.reason = reason -- 151
			return self:_Finalize() -- 152
		end, -- 154
		Reject = function(self, reason) -- 154
			if not self.resolving then -- 155
				return self:_Reject(reason) -- 155
			end -- 155
		end, -- 157
		Then = function(self, on_fulfilled, on_rejected, on_finally) -- 157
			local p = Promise() -- 158
			if iscallable(on_fulfilled) then -- 159
				p.on_fulfilled = on_fulfilled -- 159
			end -- 159
			if iscallable(on_rejected) then -- 160
				p.on_rejected = on_rejected -- 160
			end -- 160
			if iscallable(on_finally) then -- 161
				p.on_finally = on_finally -- 161
			end -- 161
			if not self.queue then -- 162
				self.queue = { } -- 162
			end -- 162
			do -- 163
				local _obj_0 = self.queue -- 163
				_obj_0[#_obj_0 + 1] = p -- 163
			end -- 163
			self:_Finalize() -- 164
			return p -- 165
		end, -- 167
		Catch = function(self, on_rejected) -- 167
			return self:Then(nil, on_rejected) -- 167
		end, -- 168
		Finally = function(self, on_finally) -- 168
			return self:Then(nil, nil, on_finally) -- 168
		end, -- 244
		SafeAwait = function(p) -- 244
			local co = coroutine.running() -- 245
			if not co then -- 246
				return false, "Cannot await in main thread" -- 246
			end -- 246
			local once_wrapper = once() -- 248
			local onResolve = once_wrapper(function(value) -- 249
				return coroutine.resume(co, true, value) -- 249
			end) -- 249
			local onReject = once_wrapper(function(reason) -- 250
				return coroutine.resume(co, false, reason) -- 250
			end) -- 250
			if Promise.IsPromise(p) then -- 252
				local _exp_0 = p.state -- 253
				if p.STATE_FULFILLED == _exp_0 then -- 254
					return true, p.value -- 255
				elseif p.STATE_REJECTED == _exp_0 then -- 256
					return false, p.reason -- 257
				else -- 259
					p:Then(onResolve, onReject) -- 259
					return coroutine.yield() -- 260
				end -- 260
			else -- 261
				do -- 261
					local thenable = istable(p) and get_thenable(p) -- 261
					if thenable then -- 261
						if iscallable(thenable) then -- 262
pcall(thenable, p, onResolve, onReject) -- 263
							return coroutine.yield() -- 264
						else -- 266
							return true, p -- 266
						end -- 262
					else -- 268
						return true, p -- 268
					end -- 261
				end -- 261
			end -- 252
		end, -- 270
		Await = function(p) -- 270
			local awaitable = istable(p) and get_awaitable(p) -- 271
			if awaitable and not Promise.IsPromise(p) then -- 272
				return awaitable(p) -- 273
			end -- 272
			local ok, result = Promise.SafeAwait(p) -- 275
			if ok then -- 276
				return result -- 276
			else -- 277
				return error(result) -- 277
			end -- 276
		end -- 48
	} -- 48
	if _base_0.__index == nil then -- 48
		_base_0.__index = _base_0 -- 48
	end -- 295
	_class_0 = setmetatable({ -- 48
		__init = function(self, executor) -- 59
			self.state = self.STATE_PENDING -- 60
			self.resolving = false -- 61
			self.value = nil -- 62
			self.reason = nil -- 63
			self.queue = nil -- 64
			if iscallable(executor) then -- 66
				self.resolving = true -- 67
				local once_wrapper = once() -- 68
				local onFulfill = once_wrapper(function(value) -- 69
					return self:_Resolve(value) -- 69
				end) -- 69
				local onReject = once_wrapper(function(reason) -- 70
					return self:_Reject(reason) -- 70
				end) -- 70
				return xpcall(executor, function(err) -- 72
					return onReject(err) -- 74
				end, onFulfill, onReject) -- 74
			end -- 66
		end, -- 48
		__base = _base_0, -- 48
		__name = "Promise" -- 48
	}, { -- 48
		__index = _base_0, -- 48
		__call = function(cls, ...) -- 48
			local _self_0 = setmetatable({ }, _base_0) -- 48
			cls.__init(_self_0, ...) -- 48
			return _self_0 -- 48
		end -- 48
	}) -- 48
	_base_0.__class = _class_0 -- 48
	local self = _class_0; -- 48
	self.VERSION = "2.0.0" -- 49
	self.AUTHOR = "Retro" -- 50
	self.URL = "https://github.com/dankmolot/gm_promise" -- 51
	self.Resolve = function(value) -- 170
		local _with_0 = Promise() -- 171
		_with_0:Resolve(value) -- 172
		return _with_0 -- 171
	end -- 170
	self.Reject = function(reason) -- 174
		local _with_0 = Promise() -- 175
		_with_0:Reject(reason) -- 176
		return _with_0 -- 175
	end -- 174
	self.All = function(promises) -- 178
		local p = Promise() -- 179
		local count = #promises -- 180
		local values = { } -- 181
		if count == 0 then -- 182
			p:Resolve(values) -- 182
		end -- 182
		for i, promise in ipairs(promises) do -- 183
			if Promise.IsPromise(promise) then -- 184
				promise:Then(function(value) -- 185
					values[i] = value -- 186
					count = count - 1 -- 187
					if count == 0 then -- 188
						return p:Resolve(values) -- 188
					end -- 188
				end, function(self, reason) -- 189
					return p:Reject(reason) -- 189
				end) -- 185
			else -- 191
				values[i] = promise -- 191
				count = count - 1 -- 192
				if count == 0 then -- 193
					p:Resolve(values) -- 193
				end -- 193
			end -- 184
		end -- 193
		return p -- 194
	end -- 178
	self.AllSettled = function(promises) -- 196
		local p = Promise() -- 197
		local count = #promises -- 198
		local values = { } -- 199
		if count == 0 then -- 200
			p:Resolve(values) -- 200
		end -- 200
		for i, promise in ipairs(promises) do -- 201
			promise:Then(function(value) -- 202
				values[i] = { -- 203
					status = "fulfilled", -- 203
					value = value -- 203
				} -- 203
				count = count - 1 -- 204
				if count == 0 then -- 205
					return p:Resolve(values) -- 205
				end -- 205
			end, function(reason) -- 206
				values[i] = { -- 207
					status = "rejected", -- 207
					reason = reason -- 207
				} -- 207
				count = count - 1 -- 208
				if count == 0 then -- 209
					return p:Resolve(values) -- 209
				end -- 209
			end) -- 202
		end -- 209
		return p -- 210
	end -- 196
	self.Any = function(promises) -- 212
		local p = Promise() -- 213
		local count = #promises -- 214
		local reasons = { } -- 215
		if count == 0 then -- 216
			p:Reject("No promises to resolve") -- 216
		end -- 216
		for i, promise in ipairs(promises) do -- 217
			promise:Then(function(value) -- 218
				return p:Resolve(value, function(reason) -- 219
					reasons[i] = reason -- 220
					count = count - 1 -- 221
					if count == 0 then -- 222
						return p:Resolve(reasons) -- 222
					end -- 222
				end) -- 222
			end) -- 218
		end -- 222
		return p -- 223
	end -- 212
	self.Race = function(promises) -- 225
		local p = Promise() -- 226
		for _index_0 = 1, #promises do -- 227
			local promise = promises[_index_0] -- 227
			promise:Then(function(value) -- 228
				return p:Resolve(value, function(reason) -- 229
					return p:Reject(reason) -- 229
				end) -- 229
			end) -- 228
		end -- 229
		return p -- 230
	end -- 225
	self.Async = function(fn) -- 232
		return function(...) -- 232
			local p = Promise() -- 233
			local co = coroutine.create(function(...) -- 234
				do -- 235
					local success, result = xpcall(fn, function(err) -- 235
						-- TODO save stacktrace and pass it to reject
						return p:Reject(err) -- 238
					end, ...) -- 235
					if success then -- 235
						return p:Resolve(result) -- 239
					end -- 235
				end -- 238
			end) -- 234
			coroutine.resume(co, ...) -- 241
			return p -- 242
		end -- 242
	end -- 232
	self.__base.resolve = self.__base.Resolve -- 280
	self.__base.reject = self.__base.Reject -- 281
	self.__base["then"] = self.__base.Then -- 282
	self.__base.next = self.__base.Then -- 283
	self.__base.andThen = self.__base.Then -- 284
	self.__base.catch = self.__base.Catch -- 285
	self.__base.finally = self.__base.Finally -- 286
	self.__base.saveAwait = self.__base.SafeAwait -- 287
	self.__base.await = self.__base.Await -- 288
	self.resolve = self.Resolve -- 289
	self.reject = self.Reject -- 290
	self.all = self.All -- 291
	self.allSettled = self.AllSettled -- 292
	self.any = self.Any -- 293
	self.race = self.Race -- 294
	self.async = self.Async -- 295
	Promise = _class_0 -- 48
end -- 295
_module_0 = Promise -- 297
return _module_0 -- 297
