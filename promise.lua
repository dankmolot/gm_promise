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
		end, -- 94
		__tostring = function(self) -- 94
			local ptr = string.format("%p", self) -- 95
			local _exp_0 = self.state -- 96
			if self.STATE_PENDING == _exp_0 then -- 97
				return "Promise " .. tostring(ptr) .. " { <state>: \"pending\" }" -- 98
			elseif self.STATE_FULFILLED == _exp_0 then -- 99
				return "Promise " .. tostring(ptr) .. " { <state>: \"fulfilled\", <value>: " .. tostring(self.value) .. " }" -- 100
			elseif self.STATE_REJECTED == _exp_0 then -- 101
				return "Promise " .. tostring(ptr) .. " { <state>: \"rejected\", <reason>: " .. tostring(self.reason) .. " }" -- 102
			else -- 104
				return "Promise " .. tostring(ptr) .. " { <state>: \"invalid\" }" -- 104
			end -- 104
		end, -- 106
		_FinalizePromise = function(self, p) -- 106
			return xpcall(function() -- 107
				if self.state == self.STATE_FULFILLED then -- 108
					if p.on_fulfilled then -- 109
						p:_Resolve(p.on_fulfilled(self.value)) -- 109
					else -- 110
						p:_Resolve(self.value) -- 110
					end -- 109
				elseif self.state == self.STATE_REJECTED then -- 111
					if p.on_rejected then -- 112
						p:_Resolve(p.on_rejected(self.reason)) -- 112
					else -- 113
						p:_Reject(self.reason) -- 113
					end -- 112
				end -- 108
				if p.on_finally then -- 114
					return p.on_finally() -- 114
				end -- 114
			end, function(err) -- 114
				return p:_Reject(err) -- 116
			end) -- 116
		end, -- 118
		_Finalize = function(self) -- 118
			if self.state == self.STATE_PENDING then -- 119
				return -- 119
			end -- 119
			return nextTick(function() -- 120
				if self.queue then -- 121
					for i, p in ipairs(self.queue) do -- 122
						self:_FinalizePromise(p) -- 123
						self.queue[i] = nil -- 124
					end -- 124
				elseif self.state == self.STATE_REJECTED then -- 125
				end -- 121
			end) -- 127
		end, -- 129
		_Fulfill = function(self, value) -- 129
			self.state = self.STATE_FULFILLED -- 130
			self.value = value -- 131
			return self:_Finalize() -- 132
		end, -- 134
		_ResolveThenable = function(self, obj, thenable) -- 134
			local once_wrapper = once() -- 135
			local onFulfill = once_wrapper(function(value) -- 136
				return self:_Resolve(value) -- 136
			end) -- 136
			local onReject = once_wrapper(function(reason) -- 137
				return self:_Reject(reason) -- 137
			end) -- 137
			do -- 138
				local ok, err = pcall(thenable, obj, onFulfill, onReject) -- 138
				if not ok then -- 138
					return onReject(err) -- 139
				end -- 138
			end -- 138
		end, -- 141
		_Resolve = function(self, value) -- 141
			if self.state ~= self.STATE_PENDING then -- 142
				return -- 142
			end -- 142
			if value == self then -- 143
				return self:_Reject(TypeError("Cannot resolve a promise with itself")) -- 143
			end -- 143
			self.resolving = true -- 144
			self.on_fulfilled = nil -- 145
			self.on_rejected = nil -- 146
			self.on_finally = nil -- 147
			if self.IsPromise(value) then -- 148
				if value.state == self.STATE_PENDING then -- 149
					if not value.queue then -- 150
						value.queue = { } -- 150
					end -- 150
					do -- 151
						local _obj_0 = value.queue -- 151
						_obj_0[#_obj_0 + 1] = self -- 151
					end -- 151
				else -- 153
					return value:_FinalizePromise(self) -- 153
				end -- 149
			elseif istable(value) then -- 154
				local ok, thenable = pcall(get_thenable, value) -- 155
				if not ok then -- 156
					return self:_Reject(thenable) -- 156
				end -- 156
				if thenable then -- 158
					return self:_ResolveThenable(value, thenable) -- 159
				else -- 161
					return self:_Fulfill(value) -- 161
				end -- 158
			else -- 163
				return self:_Fulfill(value) -- 163
			end -- 148
		end, -- 165
		Resolve = function(self, value) -- 165
			if self.resolving then -- 166
				return -- 166
			end -- 166
			return self:_Resolve(value) -- 167
		end, -- 169
		_Reject = function(self, reason) -- 169
			if not (self.state == self.STATE_PENDING) then -- 170
				return -- 170
			end -- 170
			self.state = self.STATE_REJECTED -- 171
			self.reason = reason -- 172
			-- @reject_stack = capture_stack 1
			-- if @stack[#@stack].currentline == @reject_stack[#@reject_stack].currentline
			--     @reject_stack = {}
			return self:_Finalize() -- 176
		end, -- 178
		Reject = function(self, reason) -- 178
			if not self.resolving then -- 179
				return self:_Reject(reason) -- 179
			end -- 179
		end, -- 181
		Then = function(self, on_fulfilled, on_rejected, on_finally) -- 181
			local p = Promise() -- 182
			if iscallable(on_fulfilled) then -- 183
				p.on_fulfilled = on_fulfilled -- 183
			end -- 183
			if iscallable(on_rejected) then -- 184
				p.on_rejected = on_rejected -- 184
			end -- 184
			if iscallable(on_finally) then -- 185
				p.on_finally = on_finally -- 185
			end -- 185
			if not self.queue then -- 186
				self.queue = { } -- 186
			end -- 186
			do -- 187
				local _obj_0 = self.queue -- 187
				_obj_0[#_obj_0 + 1] = p -- 187
			end -- 187
			self:_Finalize() -- 188
			return p -- 189
		end, -- 191
		Catch = function(self, on_rejected) -- 191
			return self:Then(nil, on_rejected) -- 191
		end, -- 192
		Finally = function(self, on_finally) -- 192
			return self:Then(nil, nil, on_finally) -- 192
		end, -- 268
		SafeAwait = function(p) -- 268
			local co = coroutine.running() -- 269
			if not co then -- 270
				return false, "Cannot await in main thread" -- 270
			end -- 270
			local once_wrapper = once() -- 272
			local onResolve = once_wrapper(function(value) -- 273
				return coroutine.resume(co, true, value) -- 273
			end) -- 273
			local onReject = once_wrapper(function(reason) -- 274
				return coroutine.resume(co, false, reason) -- 274
			end) -- 274
			if Promise.IsPromise(p) then -- 276
				local _exp_0 = p.state -- 277
				if p.STATE_FULFILLED == _exp_0 then -- 278
					return true, p.value -- 279
				elseif p.STATE_REJECTED == _exp_0 then -- 280
					return false, p.reason -- 281
				else -- 283
					p:Then(onResolve, onReject) -- 283
					return coroutine.yield() -- 284
				end -- 284
			else -- 285
				do -- 285
					local thenable = istable(p) and get_thenable(p) -- 285
					if thenable then -- 285
						if iscallable(thenable) then -- 286
pcall(thenable, p, onResolve, onReject) -- 287
							return coroutine.yield() -- 288
						else -- 290
							return true, p -- 290
						end -- 286
					else -- 292
						return true, p -- 292
					end -- 285
				end -- 285
			end -- 276
		end, -- 294
		Await = function(p) -- 294
			local awaitable = istable(p) and get_awaitable(p) -- 295
			if awaitable and not Promise.IsPromise(p) then -- 296
				return awaitable(p) -- 297
			end -- 296
			local ok, result = Promise.SafeAwait(p) -- 299
			if ok then -- 300
				return result -- 300
			else -- 301
				return error(result) -- 301
			end -- 300
		end -- 66
	} -- 66
	if _base_0.__index == nil then -- 66
		_base_0.__index = _base_0 -- 66
	end -- 337
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
				return xpcall(executor, function(err) -- 90
					return onReject(err) -- 92
				end, onFulfill, onReject) -- 92
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
	self.Resolve = function(value) -- 194
		local _with_0 = Promise() -- 195
		_with_0:Resolve(value) -- 196
		return _with_0 -- 195
	end -- 194
	self.Reject = function(reason) -- 198
		local _with_0 = Promise() -- 199
		_with_0:Reject(reason) -- 200
		return _with_0 -- 199
	end -- 198
	self.All = function(promises) -- 202
		local p = Promise() -- 203
		local count = #promises -- 204
		local values = { } -- 205
		if count == 0 then -- 206
			p:Resolve(values) -- 206
		end -- 206
		for i, promise in ipairs(promises) do -- 207
			if Promise.IsPromise(promise) then -- 208
				promise:Then(function(value) -- 209
					values[i] = value -- 210
					count = count - 1 -- 211
					if count == 0 then -- 212
						return p:Resolve(values) -- 212
					end -- 212
				end, function(self, reason) -- 213
					return p:Reject(reason) -- 213
				end) -- 209
			else -- 215
				values[i] = promise -- 215
				count = count - 1 -- 216
				if count == 0 then -- 217
					p:Resolve(values) -- 217
				end -- 217
			end -- 208
		end -- 217
		return p -- 218
	end -- 202
	self.AllSettled = function(promises) -- 220
		local p = Promise() -- 221
		local count = #promises -- 222
		local values = { } -- 223
		if count == 0 then -- 224
			p:Resolve(values) -- 224
		end -- 224
		for i, promise in ipairs(promises) do -- 225
			promise:Then(function(value) -- 226
				values[i] = { -- 227
					status = "fulfilled", -- 227
					value = value -- 227
				} -- 227
				count = count - 1 -- 228
				if count == 0 then -- 229
					return p:Resolve(values) -- 229
				end -- 229
			end, function(reason) -- 230
				values[i] = { -- 231
					status = "rejected", -- 231
					reason = reason -- 231
				} -- 231
				count = count - 1 -- 232
				if count == 0 then -- 233
					return p:Resolve(values) -- 233
				end -- 233
			end) -- 226
		end -- 233
		return p -- 234
	end -- 220
	self.Any = function(promises) -- 236
		local p = Promise() -- 237
		local count = #promises -- 238
		local reasons = { } -- 239
		if count == 0 then -- 240
			p:Reject("No promises to resolve") -- 240
		end -- 240
		for i, promise in ipairs(promises) do -- 241
			promise:Then(function(value) -- 242
				return p:Resolve(value, function(reason) -- 243
					reasons[i] = reason -- 244
					count = count - 1 -- 245
					if count == 0 then -- 246
						return p:Resolve(reasons) -- 246
					end -- 246
				end) -- 246
			end) -- 242
		end -- 246
		return p -- 247
	end -- 236
	self.Race = function(promises) -- 249
		local p = Promise() -- 250
		for _index_0 = 1, #promises do -- 251
			local promise = promises[_index_0] -- 251
			promise:Then(function(value) -- 252
				return p:Resolve(value, function(reason) -- 253
					return p:Reject(reason) -- 253
				end) -- 253
			end) -- 252
		end -- 253
		return p -- 254
	end -- 249
	self.Async = function(fn) -- 256
		return function(...) -- 256
			local p = Promise() -- 257
			local co = coroutine.create(function(...) -- 258
				do -- 259
					local success, result = xpcall(fn, function(err) -- 259
						-- TODO save stacktrace and pass it to reject
						return p:Reject(err) -- 262
					end, ...) -- 259
					if success then -- 259
						return p:Resolve(result) -- 263
					end -- 259
				end -- 262
			end) -- 258
			coroutine.resume(co, ...) -- 265
			return p -- 266
		end -- 266
	end -- 256
	self.Delay = function(time) -- 303
		local p = Promise() -- 304
		timer.Simple(time, function() -- 305
			return p:Resolve() -- 305
		end) -- 305
		return p -- 306
	end -- 303
	self.HTTP = function(options) -- 308
		local p = Promise() -- 309
		options.success = function(code, body, headers) -- 310
			return p:Resolve({ -- 311
				code = code, -- 311
				body = body, -- 311
				headers = headers -- 311
			}) -- 311
		end -- 310
		options.failed = function(err) -- 312
			p:Reject(HTTPError(err)) -- 313
			return -- 314
		end -- 312
		do -- 315
			local ok = HTTP(options) -- 315
			if not ok then -- 315
				p:Reject(HTTPError("failed to make http request")) -- 316
			end -- 315
		end -- 315
		return p -- 317
	end -- 308
	self.__base.resolve = self.__base.Resolve -- 320
	self.__base.reject = self.__base.Reject -- 321
	self.__base["then"] = self.__base.Then -- 322
	self.__base.next = self.__base.Then -- 323
	self.__base.andThen = self.__base.Then -- 324
	self.__base.catch = self.__base.Catch -- 325
	self.__base.finally = self.__base.Finally -- 326
	self.__base.saveAwait = self.__base.SafeAwait -- 327
	self.__base.await = self.__base.Await -- 328
	self.resolve = self.Resolve -- 329
	self.reject = self.Reject -- 330
	self.all = self.All -- 331
	self.allSettled = self.AllSettled -- 332
	self.any = self.Any -- 333
	self.race = self.Race -- 334
	self.async = self.Async -- 335
	self.delay = self.Delay -- 336
	self.http = self.HTTP -- 337
	Promise = _class_0 -- 66
end -- 337
Promise.HTTPError = HTTPError -- 339
_module_0 = Promise -- 340
return _module_0 -- 340
