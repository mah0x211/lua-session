--[[

  Copyright (C) 2014 Masatoshi Teruya

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.

  lib/item.lua
  lua-session

  Created by Masatoshi Teruya on 14/12/08.

--]] -- module
local typeof = require('util.typeof')
local Cookie = require('cookie')
local Proxy = require('session.proxy')
-- class
local Item = require('halo').class.Item

function Item:init(cfg, sid)
    local own = protected(self)
    local data, err

    if sid == nil then
        data = {}
    else
        data, err = cfg.store:get(sid)
        if err then
            return nil, err
        elseif data == nil then
            return nil
            -- data must be table
        elseif not typeof.table(data) then
            return nil, 'acquired data is corrupted: data type is not table.'
        end
    end

    own.store = cfg.store
    own.idgen = cfg.idgen
    own.cookie = cfg.cookie
    own.ttl = cfg.ttl
    own.sid = sid
    own.data = data

    return self
end

function Item:proxy() return Proxy.new(protected(self).data) end

function Item:save(genCookie, regenId)
    local own = protected(self)
    local oldsid, sid, ok, err

    -- regenerate session id: default true
    if regenId ~= false then
        oldsid = own.sid
        own.sid = own.idgen()
        -- generate session id if nil
    elseif own.sid == nil then
        own.sid = own.idgen()
    end

    -- generate cookie: default true
    if genCookie ~= false then
        sid, err = Cookie.bake(own.cookie.name, own.sid, own.cookie)
        if err then return nil, err end
    else
        sid = own.sid
    end

    -- save data
    ok, err = own.store:set(own.sid, own.data, own.ttl)
    if err then
        own.sid = oldsid or own.sid
        return nil, err
        -- delete old session
    elseif oldsid then
        ok, err = own.store:delete(oldsid)
        if err then
            own.sid = oldsid
            return nil, err
        end
    end

    return sid
end

function Item:destroy(genCookie)
    local own = protected(self)
    local sid, ok, err

    -- generate null data cookie: default true
    if genCookie ~= false then
        sid = Cookie.bake(own.cookie.name, '', own.cookie)
        if err then return nil, err end
    else
        sid = own.sid
    end

    -- delete data
    if own.sid then
        ok, err = own.store:delete(own.sid)
        if err then return nil, err end
    end

    return sid
end

return Item.exports

