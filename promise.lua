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
local nextTick -- 37
nextTick = function(fn) -- 37
	return timer.Simple(0, fn) -- 37
end -- 37
local once -- 38
once = function() -- 38
	local was_called = false -- 39
	return function(wrapped_fn) -- 40
		return function(...) -- 41
			if was_called then -- 42
				return ... -- 42
			end -- 42
			was_called = true -- 43
			return wrapped_fn(...) -- 44
		end -- 44
	end -- 44
end -- 38
local capture_stack -- 45
capture_stack = function(start_pos) -- 45
	if start_pos == nil then -- 45
		start_pos = 1 -- 45
	end -- 45
	local stack = { } -- 46
	for i = 1 + start_pos, 16 do -- 47
		local info = debug.getinfo(i, "Snl") -- 48
		if not info then -- 49
			break -- 49
		end -- 49
		stack[#stack + 1] = info -- 50
	end -- 50
	return stack -- 51
end -- 45
local error_with_custom_stack -- 53
error_with_custom_stack = function(err, stack) -- 53
	local lines = { } -- 54
	lines[#lines + 1] = "[gm_promise] Unhandled rejected promise: " .. tostring(err) -- 55
	for i, info in ipairs(stack) do -- 56
		local space = string.rep(" ", i * 2) -- 57
		lines[#lines + 1] = tostring(space) .. tostring(i) .. ". " .. tostring(info.name or "unknown") .. " - " .. tostring(info.short_src) .. ":" .. tostring(info.currentline) -- 58
	end -- 58
	lines[#lines + 1] = "\n\n" -- 59
	return table.concat(lines, "\n") -- 60
end -- 53
local Promise -- 62
do -- 62
	local _class_0 -- 62
	local _base_0 = { -- 62
		STATE_PENDING = 1, -- 68
		STATE_FULFILLED = 2, -- 69
		STATE_REJECTED = 3, -- 71
		IsPromise = function(obj) -- 71
			return istable(obj) and obj.__class == Promise -- 71
		end, -- 91
		__tostring = function(self) -- 91
			local ptr = string.format("%p", self) -- 92
			local _exp_0 = self.state -- 93
			if self.STATE_PENDING == _exp_0 then -- 94
				return "Promise " .. tostring(ptr) .. " { <state>: \"pending\" }" -- 95
			elseif self.STATE_FULFILLED == _exp_0 then -- 96
				return "Promise " .. tostring(ptr) .. " { <state>: \"fulfilled\", <value>: " .. tostring(self.value) .. " }" -- 97
			elseif self.STATE_REJECTED == _exp_0 then -- 98
				return "Promise " .. tostring(ptr) .. " { <state>: \"rejected\", <reason>: " .. tostring(self.reason) .. " }" -- 99
			else -- 101
				return "Promise " .. tostring(ptr) .. " { <state>: \"invalid\" }" -- 101
			end -- 101
		end, -- 103
		_FinalizePromise = function(self, p) -- 103
			return xpcall(function() -- 104
				if self.state == self.STATE_FULFILLED then -- 105
					if p.on_fulfilled then -- 106
						p:_Resolve(p.on_fulfilled(self.value)) -- 106
					else -- 107
						p:_Resolve(self.value) -- 107
					end -- 106
				elseif self.state == self.STATE_REJECTED then -- 108
					if p.on_rejected then -- 109
						p:_Resolve(p.on_rejected(self.reason)) -- 109
					else -- 110
						p:_Reject(self.reason) -- 110
					end -- 109
				end -- 105
				if p.on_finally then -- 111
					return p.on_finally() -- 111
				end -- 111
			end, function(err) -- 111
				return p:_Reject(err) -- 113
			end) -- 113
		end, -- 115
		_Finalize = function(self) -- 115
			if self.state == self.STATE_PENDING then -- 116
				return -- 116
			end -- 116
			return nextTick(function() -- 117
				if self.queue then -- 118
					for i, p in ipairs(self.queue) do -- 119
						self:_FinalizePromise(p) -- 120
						self.queue[i] = nil -- 121
					end -- 121
				elseif self.state == self.STATE_REJECTED then -- 122
					local final_stack = table.Add({ }, self.reject_stack) -- 123
					return ErrorNoHalt(error_with_custom_stack(self.reason, table.Add(final_stack, self.stack))) -- 124
				end -- 118
			end) -- 124
		end, -- 126
		_Fulfill = function(self, value) -- 126
			self.state = self.STATE_FULFILLED -- 127
			self.value = value -- 128
			return self:_Finalize() -- 129
		end, -- 131
		_ResolveThenable = function(self, obj, thenable) -- 131
			local once_wrapper = once() -- 132
			local onFulfill = once_wrapper(function(value) -- 133
				return self:_Resolve(value) -- 133
			end) -- 133
			local onReject = once_wrapper(function(reason) -- 134
				return self:_Reject(reason) -- 134
			end) -- 134
			do -- 135
				local ok, err = pcall(thenable, obj, onFulfill, onReject) -- 135
				if not ok then -- 135
					return onReject(err) -- 136
				end -- 135
			end -- 135
		end, -- 138
		_Resolve = function(self, value) -- 138
			if self.state ~= self.STATE_PENDING then -- 139
				return -- 139
			end -- 139
			if value == self then -- 140
				return self:_Reject("Cannot resolve a promise with itself") -- 140
			end -- 140
			self.resolving = true -- 141
			self.on_fulfilled = nil -- 142
			self.on_rejected = nil -- 143
			self.on_finally = nil -- 144
			if self.IsPromise(value) then -- 145
				if value.state == self.STATE_PENDING then -- 146
					if not value.queue then -- 147
						value.queue = { } -- 147
					end -- 147
					do -- 148
						local _obj_0 = value.queue -- 148
						_obj_0[#_obj_0 + 1] = self -- 148
					end -- 148
				else -- 150
					return value:_FinalizePromise(self) -- 150
				end -- 146
			elseif istable(value) then -- 151
				local ok, thenable = pcall(get_thenable, value) -- 152
				if not ok then -- 153
					return self:_Reject(thenable) -- 153
				end -- 153
				if thenable then -- 155
					return self:_ResolveThenable(value, thenable) -- 156
				else -- 158
					return self:_Fulfill(value) -- 158
				end -- 155
			else -- 160
				return self:_Fulfill(value) -- 160
			end -- 145
		end, -- 162
		Resolve = function(self, value) -- 162
			if self.resolving then -- 163
				return -- 163
			end -- 163
			return self:_Resolve(value) -- 164
		end, -- 166
		_Reject = function(self, reason) -- 166
			if not (self.state == self.STATE_PENDING) then -- 167
				return -- 167
			end -- 167
			self.state = self.STATE_REJECTED -- 168
			self.reason = reason -- 169
			self.reject_stack = capture_stack(1) -- 170
			if self.stack[#self.stack].currentline == self.reject_stack[#self.reject_stack].currentline then -- 171
				self.reject_stack = { } -- 172
			end -- 171
			return self:_Finalize() -- 173
		end, -- 175
		Reject = function(self, reason) -- 175
			if not self.resolving then -- 176
				return self:_Reject(reason) -- 176
			end -- 176
		end, -- 178
		Then = function(self, on_fulfilled, on_rejected, on_finally) -- 178
			local p = Promise() -- 179
			if iscallable(on_fulfilled) then -- 180
				p.on_fulfilled = on_fulfilled -- 180
			end -- 180
			if iscallable(on_rejected) then -- 181
				p.on_rejected = on_rejected -- 181
			end -- 181
			if iscallable(on_finally) then -- 182
				p.on_finally = on_finally -- 182
			end -- 182
			if not self.queue then -- 183
				self.queue = { } -- 183
			end -- 183
			do -- 184
				local _obj_0 = self.queue -- 184
				_obj_0[#_obj_0 + 1] = p -- 184
			end -- 184
			self:_Finalize() -- 185
			return p -- 186
		end, -- 188
		Catch = function(self, on_rejected) -- 188
			return self:Then(nil, on_rejected) -- 188
		end, -- 189
		Finally = function(self, on_finally) -- 189
			return self:Then(nil, nil, on_finally) -- 189
		end, -- 265
		SafeAwait = function(p) -- 265
			local co = coroutine.running() -- 266
			if not co then -- 267
				return false, "Cannot await in main thread" -- 267
			end -- 267
			local once_wrapper = once() -- 269
			local onResolve = once_wrapper(function(value) -- 270
				return coroutine.resume(co, true, value) -- 270
			end) -- 270
			local onReject = once_wrapper(function(reason) -- 271
				return coroutine.resume(co, false, reason) -- 271
			end) -- 271
			if Promise.IsPromise(p) then -- 273
				local _exp_0 = p.state -- 274
				if p.STATE_FULFILLED == _exp_0 then -- 275
					return true, p.value -- 276
				elseif p.STATE_REJECTED == _exp_0 then -- 277
					return false, p.reason -- 278
				else -- 280
					p:Then(onResolve, onReject) -- 280
					return coroutine.yield() -- 281
				end -- 281
			else -- 282
				do -- 282
					local thenable = istable(p) and get_thenable(p) -- 282
					if thenable then -- 282
						if iscallable(thenable) then -- 283
pcall(thenable, p, onResolve, onReject) -- 284
							return coroutine.yield() -- 285
						else -- 287
							return true, p -- 287
						end -- 283
					else -- 289
						return true, p -- 289
					end -- 282
				end -- 282
			end -- 273
		end, -- 291
		Await = function(p) -- 291
			local awaitable = istable(p) and get_awaitable(p) -- 292
			if awaitable and not Promise.IsPromise(p) then -- 293
				return awaitable(p) -- 294
			end -- 293
			local ok, result = Promise.SafeAwait(p) -- 296
			if ok then -- 297
				return result -- 297
			else -- 298
				return error(result) -- 298
			end -- 297
		end -- 62
	} -- 62
	if _base_0.__index == nil then -- 62
		_base_0.__index = _base_0 -- 62
	end -- 334
	_class_0 = setmetatable({ -- 62
		__init = function(self, executor) -- 73
			self.state = self.STATE_PENDING -- 74
			self.resolving = false -- 75
			self.value = nil -- 76
			self.reason = nil -- 77
			self.queue = nil -- 78
			self.stack = capture_stack(3) -- 79
			if iscallable(executor) then -- 81
				self.resolving = true -- 82
				local once_wrapper = once() -- 83
				local onFulfill = once_wrapper(function(value) -- 84
					return self:_Resolve(value) -- 84
				end) -- 84
				local onReject = once_wrapper(function(reason) -- 85
					return self:_Reject(reason) -- 85
				end) -- 85
				return xpcall(executor, function(err) -- 87
					return onReject(err) -- 89
				end, onFulfill, onReject) -- 89
			end -- 81
		end, -- 62
		__base = _base_0, -- 62
		__name = "Promise" -- 62
	}, { -- 62
		__index = _base_0, -- 62
		__call = function(cls, ...) -- 62
			local _self_0 = setmetatable({ }, _base_0) -- 62
			cls.__init(_self_0, ...) -- 62
			return _self_0 -- 62
		end -- 62
	}) -- 62
	_base_0.__class = _class_0 -- 62
	local self = _class_0; -- 62
	self.VERSION = "2.0.0" -- 63
	self.AUTHOR = "Retro" -- 64
	self.URL = "https://github.com/dankmolot/gm_promise" -- 65
	self.Resolve = function(value) -- 191
		local _with_0 = Promise() -- 192
		_with_0:Resolve(value) -- 193
		return _with_0 -- 192
	end -- 191
	self.Reject = function(reason) -- 195
		local _with_0 = Promise() -- 196
		_with_0:Reject(reason) -- 197
		return _with_0 -- 196
	end -- 195
	self.All = function(promises) -- 199
		local p = Promise() -- 200
		local count = #promises -- 201
		local values = { } -- 202
		if count == 0 then -- 203
			p:Resolve(values) -- 203
		end -- 203
		for i, promise in ipairs(promises) do -- 204
			if Promise.IsPromise(promise) then -- 205
				promise:Then(function(value) -- 206
					values[i] = value -- 207
					count = count - 1 -- 208
					if count == 0 then -- 209
						return p:Resolve(values) -- 209
					end -- 209
				end, function(self, reason) -- 210
					return p:Reject(reason) -- 210
				end) -- 206
			else -- 212
				values[i] = promise -- 212
				count = count - 1 -- 213
				if count == 0 then -- 214
					p:Resolve(values) -- 214
				end -- 214
			end -- 205
		end -- 214
		return p -- 215
	end -- 199
	self.AllSettled = function(promises) -- 217
		local p = Promise() -- 218
		local count = #promises -- 219
		local values = { } -- 220
		if count == 0 then -- 221
			p:Resolve(values) -- 221
		end -- 221
		for i, promise in ipairs(promises) do -- 222
			promise:Then(function(value) -- 223
				values[i] = { -- 224
					status = "fulfilled", -- 224
					value = value -- 224
				} -- 224
				count = count - 1 -- 225
				if count == 0 then -- 226
					return p:Resolve(values) -- 226
				end -- 226
			end, function(reason) -- 227
				values[i] = { -- 228
					status = "rejected", -- 228
					reason = reason -- 228
				} -- 228
				count = count - 1 -- 229
				if count == 0 then -- 230
					return p:Resolve(values) -- 230
				end -- 230
			end) -- 223
		end -- 230
		return p -- 231
	end -- 217
	self.Any = function(promises) -- 233
		local p = Promise() -- 234
		local count = #promises -- 235
		local reasons = { } -- 236
		if count == 0 then -- 237
			p:Reject("No promises to resolve") -- 237
		end -- 237
		for i, promise in ipairs(promises) do -- 238
			promise:Then(function(value) -- 239
				return p:Resolve(value, function(reason) -- 240
					reasons[i] = reason -- 241
					count = count - 1 -- 242
					if count == 0 then -- 243
						return p:Resolve(reasons) -- 243
					end -- 243
				end) -- 243
			end) -- 239
		end -- 243
		return p -- 244
	end -- 233
	self.Race = function(promises) -- 246
		local p = Promise() -- 247
		for _index_0 = 1, #promises do -- 248
			local promise = promises[_index_0] -- 248
			promise:Then(function(value) -- 249
				return p:Resolve(value, function(reason) -- 250
					return p:Reject(reason) -- 250
				end) -- 250
			end) -- 249
		end -- 250
		return p -- 251
	end -- 246
	self.Async = function(fn) -- 253
		return function(...) -- 253
			local p = Promise() -- 254
			local co = coroutine.create(function(...) -- 255
				do -- 256
					local success, result = xpcall(fn, function(err) -- 256
						-- TODO save stacktrace and pass it to reject
						return p:Reject(err) -- 259
					end, ...) -- 256
					if success then -- 256
						return p:Resolve(result) -- 260
					end -- 256
				end -- 259
			end) -- 255
			coroutine.resume(co, ...) -- 262
			return p -- 263
		end -- 263
	end -- 253
	self.Delay = function(time) -- 300
		local p = Promise() -- 301
		timer.Simple(time, function() -- 302
			return p:Resolve() -- 302
		end) -- 302
		return p -- 303
	end -- 300
	self.HTTP = function(options) -- 305
		local p = Promise() -- 306
		options.success = function(code, body, headers) -- 307
			return p:Resolve({ -- 308
				code = code, -- 308
				body = body, -- 308
				headers = headers -- 308
			}) -- 308
		end -- 307
		options.failed = function(err) -- 309
			p:Reject(err) -- 310
			return -- 311
		end -- 309
		do -- 312
			local ok = HTTP(options) -- 312
			if not ok then -- 312
				p:Reject("failed to make http request") -- 313
			end -- 312
		end -- 312
		return p -- 314
	end -- 305
	self.__base.resolve = self.__base.Resolve -- 317
	self.__base.reject = self.__base.Reject -- 318
	self.__base["then"] = self.__base.Then -- 319
	self.__base.next = self.__base.Then -- 320
	self.__base.andThen = self.__base.Then -- 321
	self.__base.catch = self.__base.Catch -- 322
	self.__base.finally = self.__base.Finally -- 323
	self.__base.saveAwait = self.__base.SafeAwait -- 324
	self.__base.await = self.__base.Await -- 325
	self.resolve = self.Resolve -- 326
	self.reject = self.Reject -- 327
	self.all = self.All -- 328
	self.allSettled = self.AllSettled -- 329
	self.any = self.Any -- 330
	self.race = self.Race -- 331
	self.async = self.Async -- 332
	self.delay = self.Delay -- 333
	self.http = self.HTTP -- 334
	Promise = _class_0 -- 62
end -- 334
Promise.reject() -- 336
_module_0 = Promise -- 338
return _module_0 -- 338
