local _module_0 = nil
--[[
    MIT License

    Copyright (c) 2023-2024 Retro

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
local Error, TypeError, RuntimeError
do
	local _obj_0 = include("error.lua")
	Error, TypeError, RuntimeError = _obj_0.Error, _obj_0.TypeError, _obj_0.RuntimeError
end
local isfunction, istable, isstring, getmetatable, pcall, xpcall, error, ipairs = _G.isfunction, _G.istable, _G.isstring, _G.getmetatable, _G.pcall, _G.xpcall, _G.error, _G.ipairs
local format, match = string.format, string.match
local create, resume, yield, running = coroutine.create, coroutine.resume, coroutine.yield, coroutine.running
local setTimeout = timer.Simple
local iscallable
iscallable = function(obj)
	if isfunction(obj) then
		return true
	end
	local meta = getmetatable(obj)
	return meta and meta.__call and true or false
end
local getThenable
getThenable = function(obj)
	local thenFn = obj.Then or obj.next
	return iscallable(thenFn) and thenFn
end
local getAwaitable
getAwaitable = function(obj)
	local awaitable = obj.Await or obj.await
	return iscallable(awaitable) and awaitable
end
local once
once = function()
	local wasCalled = false
	return function(wrappedFn)
		return function(...)
			if wasCalled then
				return ...
			end
			wasCalled = true
			return wrappedFn(...)
		end
	end
end
local HTTPError
do
	local _class_0
	local _parent_0 = Error
	local _base_0 = { }
	for _key_0, _val_0 in pairs(_parent_0.__base) do
		if _base_0[_key_0] == nil and _key_0:match("^__") and not (_key_0 == "__index" and _val_0 == _parent_0.__base) then
			_base_0[_key_0] = _val_0
		end
	end
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	setmetatable(_base_0, _parent_0.__base)
	_class_0 = setmetatable({
		__init = function(self, ...)
			return _class_0.__parent.__init(self, ...)
		end,
		__base = _base_0,
		__name = "HTTPError",
		__parent = _parent_0
	}, {
		__index = function(cls, name)
			local val = rawget(_base_0, name)
			if val == nil then
				local parent = rawget(cls, "__parent")
				if parent then
					return parent[name]
				end
			else
				return val
			end
		end,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	if _parent_0.__inherited then
		_parent_0.__inherited(_parent_0, _class_0)
	end
	HTTPError = _class_0
end
local PromiseError
do
	local _class_0
	local _parent_0 = Error
	local _base_0 = { }
	for _key_0, _val_0 in pairs(_parent_0.__base) do
		if _base_0[_key_0] == nil and _key_0:match("^__") and not (_key_0 == "__index" and _val_0 == _parent_0.__base) then
			_base_0[_key_0] = _val_0
		end
	end
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	setmetatable(_base_0, _parent_0.__base)
	_class_0 = setmetatable({
		__init = function(self, ...)
			return _class_0.__parent.__init(self, ...)
		end,
		__base = _base_0,
		__name = "PromiseError",
		__parent = _parent_0
	}, {
		__index = function(cls, name)
			local val = rawget(_base_0, name)
			if val == nil then
				local parent = rawget(cls, "__parent")
				if parent then
					return parent[name]
				end
			else
				return val
			end
		end,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	if _parent_0.__inherited then
		_parent_0.__inherited(_parent_0, _class_0)
	end
	PromiseError = _class_0
end
local Promise
do
	local _class_0
	local STATE_PENDING, STATE_FULFILLED, STATE_REJECTED, IsPromise, finalizePromiseUnsafe, finalizePromise, finalize, fulfill, resolveThenable, resolve, reject, Resolve, Reject, Then, Catch, Finally, transformError, SafeAwait, Await
	local _base_0 = {
		__tostring = function(self)
			local _exp_0 = self.state
			if STATE_PENDING == _exp_0 then
				return format("Promise %p { <state>: \"pending\" }", self)
			elseif STATE_FULFILLED == _exp_0 then
				return format("Promise %p { <state>: \"fulfilled\", <value>: %s }", self, self.value)
			elseif STATE_REJECTED == _exp_0 then
				return format("Promise %p { <state>: \"rejected\", <reason>: %s }", self, self.reason)
			else
				return format("Promise %p { <state>: \"invalid\" }", self)
			end
		end
	}
	if _base_0.__index == nil then
		_base_0.__index = _base_0
	end
	_class_0 = setmetatable({
		__init = function(self, executor)
			self.state = STATE_PENDING
			self.resolving = false
			if iscallable(executor) then
				self.resolving = true
				local once_wrapper = once()
				local onFulfill = once_wrapper(function(value)
					return resolve(self, value)
				end)
				local onReject = once_wrapper(function(reason)
					return reject(self, reason)
				end)
				return xpcall(executor, function(err)
					return onReject(err)
				end, onFulfill, onReject)
			end
		end,
		__base = _base_0,
		__name = "Promise"
	}, {
		__index = _base_0,
		__call = function(cls, ...)
			local _self_0 = setmetatable({ }, _base_0)
			cls.__init(_self_0, ...)
			return _self_0
		end
	})
	_base_0.__class = _class_0
	local self = _class_0;
	self.VERSION = "2.1.0"
	self.AUTHOR = "Retro"
	self.URL = "https://github.com/dankmolot/gm_promise"
	STATE_PENDING = 1
	STATE_FULFILLED = 2
	STATE_REJECTED = 3
	IsPromise = function(obj)
		return istable(obj) and obj.__class == Promise
	end
	finalizePromiseUnsafe = function(self, p)
		local onFulfilled, onRejected, onFinally = p.onFulfilled, p.onRejected, p.onFinally
		do
			local _exp_0 = self.state
			if STATE_FULFILLED == _exp_0 then
				if onFulfilled then
					resolve(p, onFulfilled(self.value))
				else
					resolve(p, self.value)
				end
			elseif STATE_REJECTED == _exp_0 then
				if onRejected then
					resolve(self, onRejected(self.reason))
				else
					reject(p, self.reason)
				end
			end
		end
		if onFinally then
			onFinally()
		end
		return
	end
	finalizePromise = function(self, p)
		local success, err = pcall(finalizePromiseUnsafe, self, p)
		if not success then
			return reject(p, err)
		end
	end
	finalize = function(self)
		if self.state == STATE_PENDING then
			return
		end
		return setTimeout(0, function()
			local queue = self.queue
			local index = 1
			while queue and queue[index] do
				finalizePromise(self, queue[index])
				queue[index] = nil
				index = index + 1
			end
		end)
	end
	fulfill = function(self, value)
		self.state = STATE_FULFILLED
		self.value = value
		return finalize(self)
	end
	resolveThenable = function(self, obj, thenable)
		local once_wrapper = once()
		local onFulfill = once_wrapper(function(value)
			return resolve(self, value)
		end)
		local onReject = once_wrapper(function(reason)
			return reject(self, reason)
		end)
		local ok, err = pcall(thenable, obj, onFulfill, onReject)
		if not ok then
			return onReject(err)
		end
	end
	resolve = function(self, value)
		if self.state ~= STATE_PENDING then
			return
		end
		if value == self then
			return reject(self, TypeError("Cannot resolve a promise with itself"))
		end
		self.resolving = true
		self.onFulfilled = nil
		self.onRejected = nil
		self.onFinally = nil
		if IsPromise(value) then
			if value.state == STATE_PENDING then
				if not value.queue then
					value.queue = { }
				end
				local _obj_0 = value.queue
				_obj_0[#_obj_0 + 1] = self
			else
				return finalizePromise(value, self)
			end
		elseif istable(value) then
			local ok, thenable = pcall(getThenable, value)
			if not ok then
				return self:_Reject(thenable)
			end
			if thenable then
				return resolveThenable(self, value, thenable)
			else
				return fulfill(self, value)
			end
		else
			return fulfill(self, value)
		end
	end
	reject = function(self, reason)
		if self.state ~= STATE_PENDING then
			return
		end
		self.state = STATE_REJECTED
		self.reason = reason
		return finalize(self)
	end
	Resolve = function(self, value)
		if not self.resolving then
			return resolve(self, value)
		end
	end
	Reject = function(self, reason)
		if not self.resolving then
			return reject(self, reason)
		end
	end
	self.Resolve = function(value)
		local p = Promise()
		Resolve(p, value)
		return p
	end
	self.Reject = function(reason)
		local p = Promise()
		Reject(p, reason)
		return p
	end
	Then = function(self, onFulfilled, onRejected, onFinally)
		local p = Promise()
		if iscallable(onFulfilled) then
			p.onFulfilled = onFulfilled
		end
		if iscallable(onRejected) then
			p.onRejected = onRejected
		end
		if iscallable(onFinally) then
			p.onFinally = onFinally
		end
		if not self.queue then
			self.queue = { }
		end
		do
			local _obj_0 = self.queue
			_obj_0[#_obj_0 + 1] = p
		end
		finalize(self)
		return p
	end
	Catch = function(self, onRejected)
		return Then(self, nil, onRejected)
	end
	Finally = function(self, onFinally)
		return Then(self, nil, nil, onFinally)
	end
	transformError = function(err)
		if isstring(err) then
			local file, line, message = match(err, "^([A-Za-z0-9%-_/.]+):(%d+): (.*)")
			if file and line then
				err = RuntimeError(message, file, line, 5)
			end
		end
		return err
	end
	self.Async = function(fn)
		return function(...)
			local p = Promise()
			local co = create(function(...)
				-- TODO: save stacktrace and pass it to reject
				local success, result = xpcall(fn, transformError, ...)
				if success then
					return Resolve(p, result)
				else
					return Reject(p, result)
				end
			end)
			resume(co, ...)
			return p
		end
	end
	SafeAwait = function(p)
		local co = running()
		if not co then
			return false, PromiseError("Cannot await in main thread")
		end
		local once_wrapper = once()
		local onResolve = once_wrapper(function(value)
			return resume(co, true, value)
		end)
		local onReject = once_wrapper(function(reason)
			return resume(co, false, reason)
		end)
		if IsPromise(p) then
			local _exp_0 = p.state
			if STATE_FULFILLED == _exp_0 then
				return true, p.value
			elseif STATE_REJECTED == _exp_0 then
				return false, p.reason
			else
				Then(p, onResolve, onReject)
				return yield()
			end
		end
		local thenable = istable(p) and getThenable(p)
		if iscallable(thenable) then
			pcall(thenable, p, onResolve, onReject)
			return yield()
		end
		return true, p
	end
	Await = function(p)
		local awaitable = istable(p) and getAwaitable(p)
		if awaitable and not IsPromise(p) then
			return awaitable(p)
		end
		local ok, result = SafeAwait(p)
		if ok then
			return result
		else
			return error(result)
		end
	end
	self.All = function(promises)
		local p = Promise()
		local count = #promises
		local values = { }
		if count == 0 then
			Resolve(p, values)
		end
		for i, promise in ipairs(promises) do
			if IsPromise(promise) then
				promise:Then(function(value)
					values[i] = value
					count = count - 1
					if count == 0 then
						return Resolve(p, values)
					end
				end, function(reason)
					return Reject(p, reason)
				end)
			else
				values[i] = promise
				count = count - 1
				if count == 0 then
					Resolve(p, values)
				end
			end
		end
		return p
	end
	self.AllSettled = function(promises)
		local p = Promise()
		local count = #promises
		local values = { }
		if count == 0 then
			Resolve(p, values)
		end
		for i, promise in ipairs(promises) do
			promise:Then(function(value)
				values[i] = {
					status = "fulfilled",
					value = value
				}
				count = count - 1
				if count == 0 then
					return Resolve(p, values)
				end
			end, function(reason)
				values[i] = {
					status = "rejected",
					reason = reason
				}
				if count == 0 then
					return Resolve(p, values)
				end
			end)
		end
		return p
	end
	self.Any = function(promises)
		local p = Promise()
		local count = #promises
		local reasons = { }
		if count == 0 then
			Reject(p, PromiseError("No promises to resolve"))
		end
		for i, promise in ipairs(promises) do
			promise:Then(function(value)
				return Resolve(p, value)
			end, function(reason)
				reasons[i] = reason
				count = count - 1
				if count == 0 then
					return Resolve(p, values)
				end
			end)
		end
		return p
	end
	self.Race = function(promises)
		local p = Promise()
		for _index_0 = 1, #promises do
			local promise = promises[_index_0]
			promise:Then(function(value)
				return Resolve(p, value)
			end, function(reason)
				return Reject(p, reason)
			end)
		end
		return p
	end
	self.Delay = function(time, value)
		local p = Promise()
		setTimeout(time, function()
			return Resolve(p, value)
		end)
		return p
	end
	self.HTTP = function(options)
		local p = Promise()
		options.success = function(code, body, headers)
			Resolve(p, {
				code = code,
				body = body,
				headers = headers
			})
			return
		end
		options.failed = function(err)
			Reject(p, HTTPError(err))
			return
		end
		do
			local ok = HTTP(options)
			if not ok then
				Reject(p, HTTPError("failed to make http request"))
			end
		end
		return p
	end
	self.__base.STATE_PENDING = STATE_PENDING
	self.__base.STATE_FULFILLED = STATE_FULFILLED
	self.__base.STATE_REJECTED = STATE_REJECTED
	self.__base.IsPromise = IsPromise
	self.__base.Resolve = Resolve
	self.__base.resolve = Resolve
	self.__base.Reject = Reject
	self.__base.reject = Reject
	self.__base.Then = Then
	self.__base["then"] = Then
	self.__base.next = Then
	self.__base.andThen = Then
	self.__base.Catch = Catch
	self.__base.catch = Catch
	self.__base.Finally = Finally
	self.__base.finally = Finally
	self.__base.SafeAwait = SafeAwait
	self.__base.safeAwait = SafeAwait
	self.__base.Await = Await
	self.__base.await = Await
	self.resolve = self.Resolve
	self.reject = self.Reject
	self.async = self.Async
	self.all = self.All
	self.allSettled = self.AllSettled
	self.any = self.Any
	self.race = self.Race
	self.delay = self.Delay
	self.http = self.HTTP
	self.PromiseError = PromiseError
	self.HTTPError = HTTPError
	Promise = _class_0
end
_module_0 = Promise
return _module_0
