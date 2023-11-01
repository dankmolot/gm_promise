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
local timer_Simple = timer.Simple -- 25
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
local once -- 39
once = function() -- 39
	local was_called = false -- 40
	return function(wrapped_fn) -- 41
		return function(...) -- 42
			if was_called then -- 43
				return ... -- 43
			end -- 43
			was_called = true -- 44
			return wrapped_fn(...) -- 45
		end -- 45
	end -- 45
end -- 39
local capture_stack -- 46
capture_stack = function(start_pos) -- 46
	if start_pos == nil then -- 46
		start_pos = 1 -- 46
	end -- 46
	local stack = { } -- 47
	for i = 1 + start_pos, 16 do -- 48
		local info = debug.getinfo(i, "Snl") -- 49
		if not info then -- 50
			break -- 50
		end -- 50
		stack[#stack + 1] = info -- 51
	end -- 51
	return stack -- 52
end -- 46
local error_with_custom_stack -- 54
error_with_custom_stack = function(err, stack) -- 54
	local lines = { } -- 55
	lines[#lines + 1] = "[gm_promise] Unhandled rejected promise: " .. tostring(err) -- 56
	for i, info in ipairs(stack) do -- 57
		local space = string.rep(" ", i * 2) -- 58
		lines[#lines + 1] = tostring(space) .. tostring(i) .. ". " .. tostring(info.name or "unknown") .. " - " .. tostring(info.short_src) .. ":" .. tostring(info.currentline) -- 59
	end -- 59
	lines[#lines + 1] = "\n\n" -- 60
	return table.concat(lines, "\n") -- 61
end -- 54
local HTTPError -- 63
do -- 63
	local _class_0 -- 63
	local _parent_0 = Error -- 63
	local _base_0 = { } -- 63
	for _key_0, _val_0 in pairs(_parent_0.__base) do -- 63
		if _base_0[_key_0] == nil and _key_0:match("^__") and not (_key_0 == "__index" and _val_0 == _parent_0.__base) then -- 63
			_base_0[_key_0] = _val_0 -- 63
		end -- 63
	end -- 63
	if _base_0.__index == nil then -- 63
		_base_0.__index = _base_0 -- 63
	end -- 63
	setmetatable(_base_0, _parent_0.__base) -- 63
	_class_0 = setmetatable({ -- 63
		__init = function(self, ...) -- 63
			return _class_0.__parent.__init(self, ...) -- 63
		end, -- 63
		__base = _base_0, -- 63
		__name = "HTTPError", -- 63
		__parent = _parent_0 -- 63
	}, { -- 63
		__index = function(cls, name) -- 63
			local val = rawget(_base_0, name) -- 63
			if val == nil then -- 63
				local parent = rawget(cls, "__parent") -- 63
				if parent then -- 63
					return parent[name] -- 63
				end -- 63
			else -- 63
				return val -- 63
			end -- 63
		end, -- 63
		__call = function(cls, ...) -- 63
			local _self_0 = setmetatable({ }, _base_0) -- 63
			cls.__init(_self_0, ...) -- 63
			return _self_0 -- 63
		end -- 63
	}) -- 63
	_base_0.__class = _class_0 -- 63
	if _parent_0.__inherited then -- 63
		_parent_0.__inherited(_parent_0, _class_0) -- 63
	end -- 63
	HTTPError = _class_0 -- 63
end -- 63
local Promise -- 65
do -- 65
	local _class_0 -- 65
	local _base_0 = { -- 65
		STATE_PENDING = 1, -- 71
		STATE_FULFILLED = 2, -- 72
		STATE_REJECTED = 3, -- 74
		IsPromise = function(obj) -- 74
			return istable(obj) and obj.__class == Promise -- 74
		end, -- 93
		__tostring = function(self) -- 93
			local ptr = string.format("%p", self) -- 94
			local _exp_0 = self.state -- 95
			if self.STATE_PENDING == _exp_0 then -- 96
				return "Promise " .. tostring(ptr) .. " { <state>: \"pending\" }" -- 97
			elseif self.STATE_FULFILLED == _exp_0 then -- 98
				return "Promise " .. tostring(ptr) .. " { <state>: \"fulfilled\", <value>: " .. tostring(self.value) .. " }" -- 99
			elseif self.STATE_REJECTED == _exp_0 then -- 100
				return "Promise " .. tostring(ptr) .. " { <state>: \"rejected\", <reason>: " .. tostring(self.reason) .. " }" -- 101
			else -- 103
				return "Promise " .. tostring(ptr) .. " { <state>: \"invalid\" }" -- 103
			end -- 103
		end, -- 105
		_FinalizePromise = function(self, p) -- 105
			return xpcall(function() -- 106
				if self.state == self.STATE_FULFILLED then -- 107
					if p.on_fulfilled then -- 108
						p:_Resolve(p.on_fulfilled(self.value)) -- 108
					else -- 109
						p:_Resolve(self.value) -- 109
					end -- 108
				elseif self.state == self.STATE_REJECTED then -- 110
					if p.on_rejected then -- 111
						p:_Resolve(p.on_rejected(self.reason)) -- 111
					else -- 112
						p:_Reject(self.reason) -- 112
					end -- 111
				end -- 107
				if p.on_finally then -- 113
					return p.on_finally() -- 113
				end -- 113
			end, function(err) -- 113
				return p:_Reject(err) -- 115
			end) -- 115
		end, -- 117
		_Finalize = function(self) -- 117
			if self.state == self.STATE_PENDING then -- 118
				return -- 118
			end -- 118
			return timer_Simple(0, function() -- 119
				if self.queue then -- 120
					for i, p in ipairs(self.queue) do -- 121
						self:_FinalizePromise(p) -- 122
						self.queue[i] = nil -- 123
					end -- 123
				elseif self.state == self.STATE_REJECTED then -- 124
				end -- 120
			end) -- 126
		end, -- 128
		_Fulfill = function(self, value) -- 128
			self.state = self.STATE_FULFILLED -- 129
			self.value = value -- 130
			return self:_Finalize() -- 131
		end, -- 133
		_ResolveThenable = function(self, obj, thenable) -- 133
			local once_wrapper = once() -- 134
			local onFulfill = once_wrapper(function(value) -- 135
				return self:_Resolve(value) -- 135
			end) -- 135
			local onReject = once_wrapper(function(reason) -- 136
				return self:_Reject(reason) -- 136
			end) -- 136
			do -- 137
				local ok, err = pcall(thenable, obj, onFulfill, onReject) -- 137
				if not ok then -- 137
					return onReject(err) -- 138
				end -- 137
			end -- 137
		end, -- 140
		_Resolve = function(self, value) -- 140
			if self.state ~= self.STATE_PENDING then -- 141
				return -- 141
			end -- 141
			if value == self then -- 142
				return self:_Reject(TypeError("Cannot resolve a promise with itself")) -- 142
			end -- 142
			self.resolving = true -- 143
			self.on_fulfilled = nil -- 144
			self.on_rejected = nil -- 145
			self.on_finally = nil -- 146
			if self.IsPromise(value) then -- 147
				if value.state == self.STATE_PENDING then -- 148
					if not value.queue then -- 149
						value.queue = { } -- 149
					end -- 149
					do -- 150
						local _obj_0 = value.queue -- 150
						_obj_0[#_obj_0 + 1] = self -- 150
					end -- 150
				else -- 152
					return value:_FinalizePromise(self) -- 152
				end -- 148
			elseif istable(value) then -- 153
				local ok, thenable = pcall(get_thenable, value) -- 154
				if not ok then -- 155
					return self:_Reject(thenable) -- 155
				end -- 155
				if thenable then -- 157
					return self:_ResolveThenable(value, thenable) -- 158
				else -- 160
					return self:_Fulfill(value) -- 160
				end -- 157
			else -- 162
				return self:_Fulfill(value) -- 162
			end -- 147
		end, -- 164
		Resolve = function(self, value) -- 164
			if self.resolving then -- 165
				return -- 165
			end -- 165
			return self:_Resolve(value) -- 166
		end, -- 168
		_Reject = function(self, reason) -- 168
			if not (self.state == self.STATE_PENDING) then -- 169
				return -- 169
			end -- 169
			self.state = self.STATE_REJECTED -- 170
			self.reason = reason -- 171
			-- @reject_stack = capture_stack 1
			-- if @stack[#@stack].currentline == @reject_stack[#@reject_stack].currentline
			--     @reject_stack = {}
			return self:_Finalize() -- 175
		end, -- 177
		Reject = function(self, reason) -- 177
			if not self.resolving then -- 178
				return self:_Reject(reason) -- 178
			end -- 178
		end, -- 180
		Then = function(self, on_fulfilled, on_rejected, on_finally) -- 180
			local p = Promise() -- 181
			if iscallable(on_fulfilled) then -- 182
				p.on_fulfilled = on_fulfilled -- 182
			end -- 182
			if iscallable(on_rejected) then -- 183
				p.on_rejected = on_rejected -- 183
			end -- 183
			if iscallable(on_finally) then -- 184
				p.on_finally = on_finally -- 184
			end -- 184
			if not self.queue then -- 185
				self.queue = { } -- 185
			end -- 185
			do -- 186
				local _obj_0 = self.queue -- 186
				_obj_0[#_obj_0 + 1] = p -- 186
			end -- 186
			self:_Finalize() -- 187
			return p -- 188
		end, -- 190
		Catch = function(self, on_rejected) -- 190
			return self:Then(nil, on_rejected) -- 190
		end, -- 191
		Finally = function(self, on_finally) -- 191
			return self:Then(nil, nil, on_finally) -- 191
		end, -- 267
		SafeAwait = function(p) -- 267
			local co = coroutine.running() -- 268
			if not co then -- 269
				return false, "Cannot await in main thread" -- 269
			end -- 269
			local once_wrapper = once() -- 271
			local onResolve = once_wrapper(function(value) -- 272
				return coroutine.resume(co, true, value) -- 272
			end) -- 272
			local onReject = once_wrapper(function(reason) -- 273
				return coroutine.resume(co, false, reason) -- 273
			end) -- 273
			if Promise.IsPromise(p) then -- 275
				local _exp_0 = p.state -- 276
				if p.STATE_FULFILLED == _exp_0 then -- 277
					return true, p.value -- 278
				elseif p.STATE_REJECTED == _exp_0 then -- 279
					return false, p.reason -- 280
				else -- 282
					p:Then(onResolve, onReject) -- 282
					return coroutine.yield() -- 283
				end -- 283
			else -- 284
				do -- 284
					local thenable = istable(p) and get_thenable(p) -- 284
					if thenable then -- 284
						if iscallable(thenable) then -- 285
pcall(thenable, p, onResolve, onReject) -- 286
							return coroutine.yield() -- 287
						else -- 289
							return true, p -- 289
						end -- 285
					else -- 291
						return true, p -- 291
					end -- 284
				end -- 284
			end -- 275
		end, -- 293
		Await = function(p) -- 293
			local awaitable = istable(p) and get_awaitable(p) -- 294
			if awaitable and not Promise.IsPromise(p) then -- 295
				return awaitable(p) -- 296
			end -- 295
			local ok, result = Promise.SafeAwait(p) -- 298
			if ok then -- 299
				return result -- 299
			else -- 300
				return error(result) -- 300
			end -- 299
		end -- 65
	} -- 65
	if _base_0.__index == nil then -- 65
		_base_0.__index = _base_0 -- 65
	end -- 336
	_class_0 = setmetatable({ -- 65
		__init = function(self, executor) -- 76
			self.state = self.STATE_PENDING -- 77
			self.resolving = false -- 78
			self.value = nil -- 79
			self.reason = nil -- 80
			self.queue = nil -- 81
			if iscallable(executor) then -- 84
				self.resolving = true -- 85
				local once_wrapper = once() -- 86
				local onFulfill = once_wrapper(function(value) -- 87
					return self:_Resolve(value) -- 87
				end) -- 87
				local onReject = once_wrapper(function(reason) -- 88
					return self:_Reject(reason) -- 88
				end) -- 88
				return xpcall(executor, function(err) -- 89
					return onReject(err) -- 91
				end, onFulfill, onReject) -- 91
			end -- 84
		end, -- 65
		__base = _base_0, -- 65
		__name = "Promise" -- 65
	}, { -- 65
		__index = _base_0, -- 65
		__call = function(cls, ...) -- 65
			local _self_0 = setmetatable({ }, _base_0) -- 65
			cls.__init(_self_0, ...) -- 65
			return _self_0 -- 65
		end -- 65
	}) -- 65
	_base_0.__class = _class_0 -- 65
	local self = _class_0; -- 65
	self.VERSION = "2.0.0" -- 66
	self.AUTHOR = "Retro" -- 67
	self.URL = "https://github.com/dankmolot/gm_promise" -- 68
	self.Resolve = function(value) -- 193
		local _with_0 = Promise() -- 194
		_with_0:Resolve(value) -- 195
		return _with_0 -- 194
	end -- 193
	self.Reject = function(reason) -- 197
		local _with_0 = Promise() -- 198
		_with_0:Reject(reason) -- 199
		return _with_0 -- 198
	end -- 197
	self.All = function(promises) -- 201
		local p = Promise() -- 202
		local count = #promises -- 203
		local values = { } -- 204
		if count == 0 then -- 205
			p:Resolve(values) -- 205
		end -- 205
		for i, promise in ipairs(promises) do -- 206
			if Promise.IsPromise(promise) then -- 207
				promise:Then(function(value) -- 208
					values[i] = value -- 209
					count = count - 1 -- 210
					if count == 0 then -- 211
						return p:Resolve(values) -- 211
					end -- 211
				end, function(self, reason) -- 212
					return p:Reject(reason) -- 212
				end) -- 208
			else -- 214
				values[i] = promise -- 214
				count = count - 1 -- 215
				if count == 0 then -- 216
					p:Resolve(values) -- 216
				end -- 216
			end -- 207
		end -- 216
		return p -- 217
	end -- 201
	self.AllSettled = function(promises) -- 219
		local p = Promise() -- 220
		local count = #promises -- 221
		local values = { } -- 222
		if count == 0 then -- 223
			p:Resolve(values) -- 223
		end -- 223
		for i, promise in ipairs(promises) do -- 224
			promise:Then(function(value) -- 225
				values[i] = { -- 226
					status = "fulfilled", -- 226
					value = value -- 226
				} -- 226
				count = count - 1 -- 227
				if count == 0 then -- 228
					return p:Resolve(values) -- 228
				end -- 228
			end, function(reason) -- 229
				values[i] = { -- 230
					status = "rejected", -- 230
					reason = reason -- 230
				} -- 230
				count = count - 1 -- 231
				if count == 0 then -- 232
					return p:Resolve(values) -- 232
				end -- 232
			end) -- 225
		end -- 232
		return p -- 233
	end -- 219
	self.Any = function(promises) -- 235
		local p = Promise() -- 236
		local count = #promises -- 237
		local reasons = { } -- 238
		if count == 0 then -- 239
			p:Reject("No promises to resolve") -- 239
		end -- 239
		for i, promise in ipairs(promises) do -- 240
			promise:Then(function(value) -- 241
				return p:Resolve(value, function(reason) -- 242
					reasons[i] = reason -- 243
					count = count - 1 -- 244
					if count == 0 then -- 245
						return p:Resolve(reasons) -- 245
					end -- 245
				end) -- 245
			end) -- 241
		end -- 245
		return p -- 246
	end -- 235
	self.Race = function(promises) -- 248
		local p = Promise() -- 249
		for _index_0 = 1, #promises do -- 250
			local promise = promises[_index_0] -- 250
			promise:Then(function(value) -- 251
				return p:Resolve(value, function(reason) -- 252
					return p:Reject(reason) -- 252
				end) -- 252
			end) -- 251
		end -- 252
		return p -- 253
	end -- 248
	self.Async = function(fn) -- 255
		return function(...) -- 255
			local p = Promise() -- 256
			local co = coroutine.create(function(...) -- 257
				do -- 258
					local success, result = xpcall(fn, function(err) -- 258
						-- TODO save stacktrace and pass it to reject
						return p:Reject(err) -- 261
					end, ...) -- 258
					if success then -- 258
						return p:Resolve(result) -- 262
					end -- 258
				end -- 261
			end) -- 257
			coroutine.resume(co, ...) -- 264
			return p -- 265
		end -- 265
	end -- 255
	self.Delay = function(time, value) -- 302
		local p = Promise() -- 303
		timer.Simple(time, function() -- 304
			return p:Resolve(value) -- 304
		end) -- 304
		return p -- 305
	end -- 302
	self.HTTP = function(options) -- 307
		local p = Promise() -- 308
		options.success = function(code, body, headers) -- 309
			return p:Resolve({ -- 310
				code = code, -- 310
				body = body, -- 310
				headers = headers -- 310
			}) -- 310
		end -- 309
		options.failed = function(err) -- 311
			p:Reject(HTTPError(err)) -- 312
			return -- 313
		end -- 311
		do -- 314
			local ok = HTTP(options) -- 314
			if not ok then -- 314
				p:Reject(HTTPError("failed to make http request")) -- 315
			end -- 314
		end -- 314
		return p -- 316
	end -- 307
	self.__base.resolve = self.__base.Resolve -- 319
	self.__base.reject = self.__base.Reject -- 320
	self.__base["then"] = self.__base.Then -- 321
	self.__base.next = self.__base.Then -- 322
	self.__base.andThen = self.__base.Then -- 323
	self.__base.catch = self.__base.Catch -- 324
	self.__base.finally = self.__base.Finally -- 325
	self.__base.saveAwait = self.__base.SafeAwait -- 326
	self.__base.await = self.__base.Await -- 327
	self.resolve = self.Resolve -- 328
	self.reject = self.Reject -- 329
	self.all = self.All -- 330
	self.allSettled = self.AllSettled -- 331
	self.any = self.Any -- 332
	self.race = self.Race -- 333
	self.async = self.Async -- 334
	self.delay = self.Delay -- 335
	self.http = self.HTTP -- 336
	Promise = _class_0 -- 65
end -- 336
Promise.HTTPError = HTTPError -- 338
_module_0 = Promise -- 339
return _module_0 -- 339
