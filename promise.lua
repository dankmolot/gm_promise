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
local Error, TypeError -- 24
do -- 24
	local _obj_0 = include("error.lua") -- 24
	Error, TypeError = _obj_0.Error, _obj_0.TypeError -- 24
end -- 24
local isfunction = isfunction -- 26
local istable = istable -- 27
local iscallable -- 28
iscallable = function(obj) -- 28
	if isfunction(obj) then -- 29
		return true -- 29
	end -- 29
	if istable(obj) then -- 30
		local meta = getmetatable(obj) -- 31
		return istable(meta) and isfunction(meta.__call) -- 32
	end -- 30
end -- 28
local get_thenable -- 33
get_thenable = function(obj) -- 33
	local then_fn = obj.Then or obj.next -- 34
	return iscallable(then_fn) and then_fn -- 35
end -- 33
local get_awaitable -- 36
get_awaitable = function(obj) -- 36
	local awaitable = obj.Await or obj.await -- 37
	return iscallable(awaitable) and awaitable -- 38
end -- 36
local nextTick -- 39
nextTick = function(fn) -- 39
	return timer.Simple(0, fn) -- 39
end -- 39
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
local capture_stack -- 47
capture_stack = function(start_pos) -- 47
	if start_pos == nil then -- 47
		start_pos = 1 -- 47
	end -- 47
	local stack = { } -- 48
	for i = 1 + start_pos, 16 do -- 49
		local info = debug.getinfo(i, "Snl") -- 50
		if not info then -- 51
			break -- 51
		end -- 51
		stack[#stack + 1] = info -- 52
	end -- 52
	return stack -- 53
end -- 47
local error_with_custom_stack -- 55
error_with_custom_stack = function(err, stack) -- 55
	local lines = { } -- 56
	lines[#lines + 1] = "[gm_promise] Unhandled rejected promise: " .. tostring(err) -- 57
	for i, info in ipairs(stack) do -- 58
		local space = string.rep(" ", i * 2) -- 59
		lines[#lines + 1] = tostring(space) .. tostring(i) .. ". " .. tostring(info.name or "unknown") .. " - " .. tostring(info.short_src) .. ":" .. tostring(info.currentline) -- 60
	end -- 60
	lines[#lines + 1] = "\n\n" -- 61
	return table.concat(lines, "\n") -- 62
end -- 55
local HTTPError -- 64
do -- 64
	local _class_0 -- 64
	local _parent_0 = Error -- 64
	local _base_0 = { } -- 64
	for _key_0, _val_0 in pairs(_parent_0.__base) do -- 64
		if _base_0[_key_0] == nil and _key_0:match("^__") and not (_key_0 == "__index" and _val_0 == _parent_0.__base) then -- 64
			_base_0[_key_0] = _val_0 -- 64
		end -- 64
	end -- 64
	if _base_0.__index == nil then -- 64
		_base_0.__index = _base_0 -- 64
	end -- 64
	setmetatable(_base_0, _parent_0.__base) -- 64
	_class_0 = setmetatable({ -- 64
		__init = function(self, ...) -- 64
			return _class_0.__parent.__init(self, ...) -- 64
		end, -- 64
		__base = _base_0, -- 64
		__name = "HTTPError", -- 64
		__parent = _parent_0 -- 64
	}, { -- 64
		__index = function(cls, name) -- 64
			local val = rawget(_base_0, name) -- 64
			if val == nil then -- 64
				local parent = rawget(cls, "__parent") -- 64
				if parent then -- 64
					return parent[name] -- 64
				end -- 64
			else -- 64
				return val -- 64
			end -- 64
		end, -- 64
		__call = function(cls, ...) -- 64
			local _self_0 = setmetatable({ }, _base_0) -- 64
			cls.__init(_self_0, ...) -- 64
			return _self_0 -- 64
		end -- 64
	}) -- 64
	_base_0.__class = _class_0 -- 64
	if _parent_0.__inherited then -- 64
		_parent_0.__inherited(_parent_0, _class_0) -- 64
	end -- 64
	HTTPError = _class_0 -- 64
end -- 64
local Promise -- 66
do -- 66
	local _class_0 -- 66
	local _base_0 = { -- 66
		STATE_PENDING = 1, -- 72
		STATE_FULFILLED = 2, -- 73
		STATE_REJECTED = 3, -- 75
		IsPromise = function(obj) -- 75
			return istable(obj) and obj.__class == Promise -- 75
		end, -- 95
		__tostring = function(self) -- 95
			local ptr = string.format("%p", self) -- 96
			local _exp_0 = self.state -- 97
			if self.STATE_PENDING == _exp_0 then -- 98
				return "Promise " .. tostring(ptr) .. " { <state>: \"pending\" }" -- 99
			elseif self.STATE_FULFILLED == _exp_0 then -- 100
				return "Promise " .. tostring(ptr) .. " { <state>: \"fulfilled\", <value>: " .. tostring(self.value) .. " }" -- 101
			elseif self.STATE_REJECTED == _exp_0 then -- 102
				return "Promise " .. tostring(ptr) .. " { <state>: \"rejected\", <reason>: " .. tostring(self.reason) .. " }" -- 103
			else -- 105
				return "Promise " .. tostring(ptr) .. " { <state>: \"invalid\" }" -- 105
			end -- 105
		end, -- 107
		_FinalizePromise = function(self, p) -- 107
			return xpcall(function() -- 108
				if self.state == self.STATE_FULFILLED then -- 109
					if p.on_fulfilled then -- 110
						p:_Resolve(p.on_fulfilled(self.value)) -- 110
					else -- 111
						p:_Resolve(self.value) -- 111
					end -- 110
				elseif self.state == self.STATE_REJECTED then -- 112
					if p.on_rejected then -- 113
						p:_Resolve(p.on_rejected(self.reason)) -- 113
					else -- 114
						p:_Reject(self.reason) -- 114
					end -- 113
				end -- 109
				if p.on_finally then -- 115
					return p.on_finally() -- 115
				end -- 115
			end, function(err) -- 115
				return p:_Reject(err) -- 117
			end) -- 117
		end, -- 119
		_Finalize = function(self) -- 119
			if self.state == self.STATE_PENDING then -- 120
				return -- 120
			end -- 120
			return nextTick(function() -- 121
				if self.queue then -- 122
					for i, p in ipairs(self.queue) do -- 123
						self:_FinalizePromise(p) -- 124
						self.queue[i] = nil -- 125
					end -- 125
				elseif self.state == self.STATE_REJECTED then -- 126
				end -- 122
			end) -- 128
		end, -- 130
		_Fulfill = function(self, value) -- 130
			self.state = self.STATE_FULFILLED -- 131
			self.value = value -- 132
			return self:_Finalize() -- 133
		end, -- 135
		_ResolveThenable = function(self, obj, thenable) -- 135
			local once_wrapper = once() -- 136
			local onFulfill = once_wrapper(function(value) -- 137
				return self:_Resolve(value) -- 137
			end) -- 137
			local onReject = once_wrapper(function(reason) -- 138
				return self:_Reject(reason) -- 138
			end) -- 138
			do -- 139
				local ok, err = pcall(thenable, obj, onFulfill, onReject) -- 139
				if not ok then -- 139
					return onReject(err) -- 140
				end -- 139
			end -- 139
		end, -- 142
		_Resolve = function(self, value) -- 142
			if self.state ~= self.STATE_PENDING then -- 143
				return -- 143
			end -- 143
			if value == self then -- 144
				return self:_Reject(TypeError("Cannot resolve a promise with itself")) -- 144
			end -- 144
			self.resolving = true -- 145
			self.on_fulfilled = nil -- 146
			self.on_rejected = nil -- 147
			self.on_finally = nil -- 148
			if self.IsPromise(value) then -- 149
				if value.state == self.STATE_PENDING then -- 150
					if not value.queue then -- 151
						value.queue = { } -- 151
					end -- 151
					do -- 152
						local _obj_0 = value.queue -- 152
						_obj_0[#_obj_0 + 1] = self -- 152
					end -- 152
				else -- 154
					return value:_FinalizePromise(self) -- 154
				end -- 150
			elseif istable(value) then -- 155
				local ok, thenable = pcall(get_thenable, value) -- 156
				if not ok then -- 157
					return self:_Reject(thenable) -- 157
				end -- 157
				if thenable then -- 159
					return self:_ResolveThenable(value, thenable) -- 160
				else -- 162
					return self:_Fulfill(value) -- 162
				end -- 159
			else -- 164
				return self:_Fulfill(value) -- 164
			end -- 149
		end, -- 166
		Resolve = function(self, value) -- 166
			if self.resolving then -- 167
				return -- 167
			end -- 167
			return self:_Resolve(value) -- 168
		end, -- 170
		_Reject = function(self, reason) -- 170
			if not (self.state == self.STATE_PENDING) then -- 171
				return -- 171
			end -- 171
			self.state = self.STATE_REJECTED -- 172
			self.reason = reason -- 173
			-- @reject_stack = capture_stack 1
			-- if @stack[#@stack].currentline == @reject_stack[#@reject_stack].currentline
			--     @reject_stack = {}
			return self:_Finalize() -- 177
		end, -- 179
		Reject = function(self, reason) -- 179
			if not self.resolving then -- 180
				return self:_Reject(reason) -- 180
			end -- 180
		end, -- 182
		Then = function(self, on_fulfilled, on_rejected, on_finally) -- 182
			local p = Promise() -- 183
			if iscallable(on_fulfilled) then -- 184
				p.on_fulfilled = on_fulfilled -- 184
			end -- 184
			if iscallable(on_rejected) then -- 185
				p.on_rejected = on_rejected -- 185
			end -- 185
			if iscallable(on_finally) then -- 186
				p.on_finally = on_finally -- 186
			end -- 186
			if not self.queue then -- 187
				self.queue = { } -- 187
			end -- 187
			do -- 188
				local _obj_0 = self.queue -- 188
				_obj_0[#_obj_0 + 1] = p -- 188
			end -- 188
			self:_Finalize() -- 189
			return p -- 190
		end, -- 192
		Catch = function(self, on_rejected) -- 192
			return self:Then(nil, on_rejected) -- 192
		end, -- 193
		Finally = function(self, on_finally) -- 193
			return self:Then(nil, nil, on_finally) -- 193
		end, -- 269
		SafeAwait = function(p) -- 269
			local co = coroutine.running() -- 270
			if not co then -- 271
				return false, "Cannot await in main thread" -- 271
			end -- 271
			local once_wrapper = once() -- 273
			local onResolve = once_wrapper(function(value) -- 274
				return coroutine.resume(co, true, value) -- 274
			end) -- 274
			local onReject = once_wrapper(function(reason) -- 275
				return coroutine.resume(co, false, reason) -- 275
			end) -- 275
			if Promise.IsPromise(p) then -- 277
				local _exp_0 = p.state -- 278
				if p.STATE_FULFILLED == _exp_0 then -- 279
					return true, p.value -- 280
				elseif p.STATE_REJECTED == _exp_0 then -- 281
					return false, p.reason -- 282
				else -- 284
					p:Then(onResolve, onReject) -- 284
					return coroutine.yield() -- 285
				end -- 285
			else -- 286
				do -- 286
					local thenable = istable(p) and get_thenable(p) -- 286
					if thenable then -- 286
						if iscallable(thenable) then -- 287
pcall(thenable, p, onResolve, onReject) -- 288
							return coroutine.yield() -- 289
						else -- 291
							return true, p -- 291
						end -- 287
					else -- 293
						return true, p -- 293
					end -- 286
				end -- 286
			end -- 277
		end, -- 295
		Await = function(p) -- 295
			local awaitable = istable(p) and get_awaitable(p) -- 296
			if awaitable and not Promise.IsPromise(p) then -- 297
				return awaitable(p) -- 298
			end -- 297
			local ok, result = Promise.SafeAwait(p) -- 300
			if ok then -- 301
				return result -- 301
			else -- 302
				return error(result) -- 302
			end -- 301
		end -- 66
	} -- 66
	if _base_0.__index == nil then -- 66
		_base_0.__index = _base_0 -- 66
	end -- 338
	_class_0 = setmetatable({ -- 66
		__init = function(self, executor) -- 77
			self.state = self.STATE_PENDING -- 78
			self.resolving = false -- 79
			self.value = nil -- 80
			self.reason = nil -- 81
			self.queue = nil -- 82
			if iscallable(executor) then -- 85
				self.resolving = true -- 86
				local once_wrapper = once() -- 87
				local onFulfill = once_wrapper(function(value) -- 88
					return self:_Resolve(value) -- 88
				end) -- 88
				local onReject = once_wrapper(function(reason) -- 89
					return self:_Reject(reason) -- 89
				end) -- 89
				return xpcall(executor, function(err) -- 91
					return onReject(err) -- 93
				end, onFulfill, onReject) -- 93
			end -- 85
		end, -- 66
		__base = _base_0, -- 66
		__name = "Promise" -- 66
	}, { -- 66
		__index = _base_0, -- 66
		__call = function(cls, ...) -- 66
			local _self_0 = setmetatable({ }, _base_0) -- 66
			cls.__init(_self_0, ...) -- 66
			return _self_0 -- 66
		end -- 66
	}) -- 66
	_base_0.__class = _class_0 -- 66
	local self = _class_0; -- 66
	self.VERSION = "2.0.0" -- 67
	self.AUTHOR = "Retro" -- 68
	self.URL = "https://github.com/dankmolot/gm_promise" -- 69
	self.Resolve = function(value) -- 195
		local _with_0 = Promise() -- 196
		_with_0:Resolve(value) -- 197
		return _with_0 -- 196
	end -- 195
	self.Reject = function(reason) -- 199
		local _with_0 = Promise() -- 200
		_with_0:Reject(reason) -- 201
		return _with_0 -- 200
	end -- 199
	self.All = function(promises) -- 203
		local p = Promise() -- 204
		local count = #promises -- 205
		local values = { } -- 206
		if count == 0 then -- 207
			p:Resolve(values) -- 207
		end -- 207
		for i, promise in ipairs(promises) do -- 208
			if Promise.IsPromise(promise) then -- 209
				promise:Then(function(value) -- 210
					values[i] = value -- 211
					count = count - 1 -- 212
					if count == 0 then -- 213
						return p:Resolve(values) -- 213
					end -- 213
				end, function(self, reason) -- 214
					return p:Reject(reason) -- 214
				end) -- 210
			else -- 216
				values[i] = promise -- 216
				count = count - 1 -- 217
				if count == 0 then -- 218
					p:Resolve(values) -- 218
				end -- 218
			end -- 209
		end -- 218
		return p -- 219
	end -- 203
	self.AllSettled = function(promises) -- 221
		local p = Promise() -- 222
		local count = #promises -- 223
		local values = { } -- 224
		if count == 0 then -- 225
			p:Resolve(values) -- 225
		end -- 225
		for i, promise in ipairs(promises) do -- 226
			promise:Then(function(value) -- 227
				values[i] = { -- 228
					status = "fulfilled", -- 228
					value = value -- 228
				} -- 228
				count = count - 1 -- 229
				if count == 0 then -- 230
					return p:Resolve(values) -- 230
				end -- 230
			end, function(reason) -- 231
				values[i] = { -- 232
					status = "rejected", -- 232
					reason = reason -- 232
				} -- 232
				count = count - 1 -- 233
				if count == 0 then -- 234
					return p:Resolve(values) -- 234
				end -- 234
			end) -- 227
		end -- 234
		return p -- 235
	end -- 221
	self.Any = function(promises) -- 237
		local p = Promise() -- 238
		local count = #promises -- 239
		local reasons = { } -- 240
		if count == 0 then -- 241
			p:Reject("No promises to resolve") -- 241
		end -- 241
		for i, promise in ipairs(promises) do -- 242
			promise:Then(function(value) -- 243
				return p:Resolve(value, function(reason) -- 244
					reasons[i] = reason -- 245
					count = count - 1 -- 246
					if count == 0 then -- 247
						return p:Resolve(reasons) -- 247
					end -- 247
				end) -- 247
			end) -- 243
		end -- 247
		return p -- 248
	end -- 237
	self.Race = function(promises) -- 250
		local p = Promise() -- 251
		for _index_0 = 1, #promises do -- 252
			local promise = promises[_index_0] -- 252
			promise:Then(function(value) -- 253
				return p:Resolve(value, function(reason) -- 254
					return p:Reject(reason) -- 254
				end) -- 254
			end) -- 253
		end -- 254
		return p -- 255
	end -- 250
	self.Async = function(fn) -- 257
		return function(...) -- 257
			local p = Promise() -- 258
			local co = coroutine.create(function(...) -- 259
				do -- 260
					local success, result = xpcall(fn, function(err) -- 260
						-- TODO save stacktrace and pass it to reject
						return p:Reject(err) -- 263
					end, ...) -- 260
					if success then -- 260
						return p:Resolve(result) -- 264
					end -- 260
				end -- 263
			end) -- 259
			coroutine.resume(co, ...) -- 266
			return p -- 267
		end -- 267
	end -- 257
	self.Delay = function(time) -- 304
		local p = Promise() -- 305
		timer.Simple(time, function() -- 306
			return p:Resolve() -- 306
		end) -- 306
		return p -- 307
	end -- 304
	self.HTTP = function(options) -- 309
		local p = Promise() -- 310
		options.success = function(code, body, headers) -- 311
			return p:Resolve({ -- 312
				code = code, -- 312
				body = body, -- 312
				headers = headers -- 312
			}) -- 312
		end -- 311
		options.failed = function(err) -- 313
			p:Reject(HTTPError(err)) -- 314
			return -- 315
		end -- 313
		do -- 316
			local ok = HTTP(options) -- 316
			if not ok then -- 316
				p:Reject(HTTPError("failed to make http request")) -- 317
			end -- 316
		end -- 316
		return p -- 318
	end -- 309
	self.__base.resolve = self.__base.Resolve -- 321
	self.__base.reject = self.__base.Reject -- 322
	self.__base["then"] = self.__base.Then -- 323
	self.__base.next = self.__base.Then -- 324
	self.__base.andThen = self.__base.Then -- 325
	self.__base.catch = self.__base.Catch -- 326
	self.__base.finally = self.__base.Finally -- 327
	self.__base.saveAwait = self.__base.SafeAwait -- 328
	self.__base.await = self.__base.Await -- 329
	self.resolve = self.Resolve -- 330
	self.reject = self.Reject -- 331
	self.all = self.All -- 332
	self.allSettled = self.AllSettled -- 333
	self.any = self.Any -- 334
	self.race = self.Race -- 335
	self.async = self.Async -- 336
	self.delay = self.Delay -- 337
	self.http = self.HTTP -- 338
	Promise = _class_0 -- 66
end -- 338
Promise.HTTPError = HTTPError -- 340
_module_0 = Promise -- 341
return _module_0 -- 341
