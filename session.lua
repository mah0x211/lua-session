--
-- Copyright (C) 2024 Masatoshi Fukunaga
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- module
local find = string.find
local pairs = pairs
local pcall = pcall
local select = select
local type = type
local unpack = unpack or table.unpack
local concat = table.concat
local is_str = require('lauxhlib.is').str
local is_table = require('lauxhlib.is').table
local is_uint = require('lauxhlib.is').uint
local is_func = require('lauxhlib.is').func
local errorf = require('error').format
local fatalf = require('error').fatalf
local default_idgen = require('session.idgen')
local new_session_cookie = require('session.cookie').new

--- ret_error_result returns a result with an error.
--- @param res any result
--- @param err any
--- @param timeout boolean?
--- @param errfmt string error message format string
--- @param ... any arguments for the error message format string
local function ret_error_result(res, err, timeout, errfmt, ...)
    if err then
        local args = {
            ...,
        }
        local narg = select('#', ...) + 1
        args[narg] = err
        err = errorf(errfmt, unpack(args, 1, narg))
    end
    return res, err, timeout == true
end

--- @class session.Session
--- @field cookie session.cookie
--- @field private id string
--- @field private data table<string, any>
--- @field private falsh table<string, any>
--- @field private manager session.Manager
local Session = {}

--- init
--- @param manager session.Manager
--- @param id string
--- @param payload table<string, any>?
--- @param cookie_cfg session.cookie.config?
--- @return session.Session
function Session:init(manager, id, payload, cookie_cfg)
    self.manager = manager
    assert(is_str(id) and #id > 0, 'id must be a non-empty string')
    self.id = id
    self.cookie = new_session_cookie(cookie_cfg)
    self.data = {}
    self.flash = {}
    if payload ~= nil then
        assert(is_table(payload), 'payload must be nil or table')
        self.data = is_table(payload.data) and payload.data or {}
        self.flash = is_table(payload.flash) and payload.flash or {}
    end

    return self
end

--- getid returns the session id.
--- @return string
function Session:getid()
    return self.id
end

-- clone() allows only this type of values to be cloned.
local VALID_VALUE_TYPES = {
    ['string'] = true,
    ['number'] = true,
    ['boolean'] = true,
}

--- clone_table returns a new table that contains only safe values.
--- @param tbl table
--- @return table copies
--- @return any err
local function clone_table(tbl, ref)
    if type(ref) ~= 'table' then
        ref = {}
    end

    local ctbl = {}
    for k, v in pairs(tbl) do
        -- ignore non-string and non-unsigned integer keys
        if is_str(k) or is_uint(k) then
            local t = type(v)
            if t == 'table' then
                if ref[v] then
                    return nil, errorf('cannot clone circular reference at %q',
                                       concat(ref, '.'))
                end
                local tail = #ref + 1
                local err

                -- keep reference and key
                ref[v] = true
                ref[tail] = k
                ctbl[k], err = clone_table(v, ref)
                -- release reference and key
                ref[v] = nil
                ref[tail] = nil

                if err then
                    return nil, err
                end
            elseif VALID_VALUE_TYPES[t] then
                ctbl[k] = v
            end
        end
    end
    return ctbl
end

--- clone returns a cloned value if the argument is a safe value.
--- @param v table
--- @return any cloned_value
--- @return any err
local function clone(v)
    local t = type(v)
    if t == 'table' then
        return clone_table(v)
    end
    return VALID_VALUE_TYPES[t] and v or nil
end

-- VALID_KEY_PATTERN allows only this pattern of string to be used as a key.
local VALID_KEY_PATTERN = '^%a[%w_]*$'

--- set_value sets a cloned value associated with the key into the table.
--- @param tbl table
--- @param key string
--- @param val any
--- @return boolean ok
--- @return any err
local function set_value(tbl, key, val)
    if not is_str(key) or not find(key, VALID_KEY_PATTERN) then
        fatalf(2, 'key must be string with pattern %q', VALID_KEY_PATTERN)
    end

    if val == nil then
        tbl[key] = nil
        return true
    end

    local cval, err = clone(val)
    if cval == nil then
        return false,
               errorf('cannot save %q value into session', type(val), err)
    end
    tbl[key] = cval
    return true
end

--- set set a cloned value associated with the key into the session.
--- @param key string
--- @param val any
--- @return boolean ok
--- @return any err
function Session:set(key, val)
    return set_value(self.data, key, val)
end

--- set_flash set a cloned value associated with the key into the session.
--- @param key string
--- @param val any
--- @return boolean ok
--- @return any err
function Session:set_flash(key, val)
    return set_value(self.flash, key, val)
end

--- get returns a value associated with the key from the session.
--- @param key string
--- @return any
function Session:get(key)
    return self.data[key]
end

--- get_flash deletes a value associated with the key from the flash data
--- @param key string
--- @return any
function Session:get_flash(key)
    local val = self.flash[key]
    if val then
        -- delete value after get it
        self.flash[key] = nil
    end
    return val
end

--- getall returns all values associated with the session.
--- @return table<string, any>
function Session:getall()
    return self.data
end

function Session:getall_flash()
    local flash = self.flash
    -- delete flash data after get it
    self.flash = {}
    return flash
end

--- get_copy returns a cloned value associated with the key from the session.
--- @param key string
--- @return any
function Session:get_copy(key)
    local v = self.data[key]
    return v ~= nil and clone(v) or v
end

--- getall_copy returns all cloned values associated with the session.
--- @return table<string, any>
function Session:getall_copy()
    return clone_table(self.data)
end

--- delete deletes a value associated with the key from the session and returns it.
--- @param key string
--- @return any val
function Session:delete(key)
    local val = self.data[key]
    if val then
        -- delete value after get it
        self.data[key] = nil
    end
    return val
end

--- save saves the session data into the store and returns a cookie.
--- @return string? cookie
--- @return any err
--- @return boolean? timeout
function Session:save()
    local ok, err, timeout = self.manager:save(self.id, {
        data = self.data,
        flash = self.flash,
    }, self.cookie.maxage)
    if ok then
        return self.cookie:bake(self.id)
    end
    return ret_error_result(nil, err, timeout, 'failed to save session')
end

--- rename renames the session id.
--- @return string? cookie
--- @return any err
--- @return boolean? timeout
function Session:rename()
    local newid, err, timeout = self.manager:rename(self.id)
    if newid ~= nil then
        assert(is_str(newid), 'store:rename() must return string')
        self.id = newid
        return self.cookie:bake(self.id)
    end
    return ret_error_result(nil, err, timeout, 'failed to rename session-id')
end

--- destroy destroys the session data from the store and returns a avoid-cookie.
--- @return string? cookie
--- @return any err
--- @return boolean? timeout
function Session:destroy()
    local ok, err, timeout = self.manager:destroy(self.id)
    if ok then
        self.data = {}
        return self.cookie:bake_void()
    end
    return ret_error_result(nil, err, timeout, 'failed to destroy session')
end

Session = require('metamodule').new.Session(Session)

-- module
local new_cache = require('cache').new --- @type fun(store: cache.store, ttl: integer):(cache)
local new_cache_inmem = require('cache.inmem').new --- @type fun(ttl: integer):(cache)

--- @class cache.store
--- @field set fun(self, key: string, val: any, ttl: integer?):(ok: boolean, err: any, timeout: boolean?)
--- @field get fun(self, key: string, ttl: integer?):(val: any, err: any, timeout: boolean?)
--- @field delete fun(self, key: string):(ok: boolean, err: any, timeout: boolean?)
--- @field rename fun(self, oldkey: string, newkey: string):(ok: boolean, err: any, timeout: boolean?)
--- @field keys fun(self, callback: fun(key: string):(ok: boolean, err: any), ...):(ok: boolean, err: any, timeout: boolean?)
--- @field evict fun(self, callback: fun(key: string):(ok: boolean, err: any), n: integer?, ...):(n: integer, err: any, timeout: boolean?)

--- @class cache
--- @field get fun(self, key: string, ttl: integer?):(ok: boolean, err: any, timeout: boolean?)
--- @field set fun(self, key: string, val: any, ttl: integer?):(ok: boolean, err: any)
--- @field delete fun(self, key: string):(ok: boolean, err: any)
--- @field rename fun(self, key: string, newkey: string):(ok: boolean, err: any)
--- @field keys fun(self, callback: fun(key: string):(ok: boolean, err: any), ...):(ok: boolean, err: any)
--- @field evict fun(self, callback: fun(key: string):(ok: boolean, err: any), n: integer?, ...):(n: integer, err: any)

--- new creates a new session backend with the specified time-to-live.
--- @param store cache.store? cache.store instance.
--- @param ttl integer default session time-to-live.
--- @return cache cache
local function new_store(store, ttl)
    -- create a cache instance
    if store == nil then
        -- use cache.inmem module as default session store
        return new_cache_inmem(ttl)
    end
    -- create a cache instance with the specified store
    return new_cache(store, ttl)
end

--- @class session.config
--- @field cookie session.cookie.config?
--- @field store cache.store
--- @field idgen fun():(string)

--- @class session.Manager
--- @field protected cookie session.cookie
--- @field private idgen fun():(id: string)
--- @field private cache cache
local Manager = {}

--- init initializes the new session.store instance.
--- @param cfg session.config a cache field will be ignored.
--- @return session.Manager
function Manager:init(cfg)
    if cfg ~= nil and not is_table(cfg) then
        fatalf(2, 'cfg %q must be table', type(cfg))
    end
    cfg = cfg or {}

    -- verify cookie_cfg
    local ok
    ok, self.cookie = pcall(new_session_cookie, cfg.cookie)
    if not ok then
        fatalf(2, 'invalid cfg.cookie', self.cookie)
    end

    -- create a cache store
    ok, self.cache = pcall(new_store, cfg.store, self.cookie.maxage)
    if not ok then
        fatalf(2, 'invalid cfg.store', self.cache)
    end

    -- verify idgen function
    self.idgen = default_idgen
    if cfg.idgen ~= nil then
        if not is_func(cfg.idgen) then
            -- it must be a function and returns a non-empty string-id
            fatalf(2, 'cfg.idgen %q must be function', type(cfg.idgen))
        end
        -- confirm idgen function returns a non-empty string-id
        local id, err = cfg.idgen()
        if not is_str(id) or #id == 0 then
            err = errorf('cfg.idgen() did not return a non-empty string %q', id,
                         err)
            fatalf(2, err)
        end
        self.idgen = cfg.idgen
    end

    return self
end

--- genid generates a new session id.
--- this function will throw an error if the idgen function does not return a
--- non-empty string-id.
--- @private
--- @return string id
function Manager:genid()
    local id, err = self.idgen()
    if not is_str(id) or #id == 0 then
        err = errorf('idgen() did not return a non-empty string %q', id, err)
        fatalf(2, err)
    end
    return id
end

--- create creates a new session.
--- @return session.Session
function Manager:create()
    local id = self:genid()
    return Session(self, id, {}, self.cookie:get_config())
end

--- save saves the session data into the store.
--- @param sid string session id.
--- @param data any session data.
--- @param ttl integer? session time-to-live.
--- @return boolean ok
--- @return any err
--- @return boolean? timeout
function Manager:save(sid, data, ttl)
    if not is_str(sid) then
        fatalf(2, 'sid must be string')
    elseif not is_table(data) then
        fatalf(2, 'data must be table')
    end

    local ok, err, timeout = self.cache:set(sid, data, ttl)
    if ok then
        return true
    end
    return ret_error_result(false, err, timeout, 'failed to save a data')
end

--- fetch returns a session associated with the sid.
--- @param sid string
--- @return session.Session? session
--- @return any err
--- @return boolean timeout
function Manager:fetch(sid)
    if not is_str(sid) then
        fatalf(2, 'sid %q must be string', type(sid))
    end

    local data, err, timeout = self.cache:get(sid)
    if data ~= nil then
        if not is_table(data) then
            fatalf(2, 'acquired data is corrupted: data type is not table')
        end
        return Session(self, sid, data, self.cookie:get_config())
    end
    return ret_error_result(nil, err, timeout, 'failed to fetch a data')
end

--- rename
---@param sid string
---@return string? newsid
---@return any err
---@return boolean? timeout
function Manager:rename(sid)
    if not is_str(sid) then
        fatalf(2, 'sid %q must be string', type(sid))
    end

    local newsid = self:genid()
    local ok, err, timeout = self.cache:rename(sid, newsid)
    if ok then
        return newsid
    end
    return ret_error_result(nil, err, timeout, 'failed to rename %q', sid)
end

--- destroy destroys the session data associated with the sid. and returns a avoid-cookie.
--- @param sid string session id.
--- @return boolean ok
--- @return any err
--- @return boolean? timeout
function Manager:destroy(sid)
    if not is_str(sid) then
        fatalf(2, 'sid %q must be string', type(sid))
    end

    local ok, err, timeout = self.cache:delete(sid)
    if ok then
        return true
    end
    return ret_error_result(false, err, timeout, 'failed to destroy a data')
end

--- evict_callback is a callback function that always returns true.
--- @return boolean ok
local function evict_callback()
    return true
end

--- evict evicts the expired sessions.
--- @param n integer? number of sessions to evict.
--- @return integer nevict
--- @return any err
--- @return boolean? timeout
function Manager:evict(n, ...)
    local nev, err, timeout = self.cache:evict(evict_callback, n, ...)
    assert(nev >= 0, 'nevict must be a non-negative integer')
    return ret_error_result(nev, err, timeout, 'failed to evict expired data')
end

return {
    new = require('metamodule').new.Manager(Manager),
}
