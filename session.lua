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

  session.lua
  lua-session

  Created by Masatoshi Teruya on 14/12/08.

--]] -- module
local Cookie = require('cookie')
local siphash48 = require('siphash').encode48
local gettimeofday = require('process').gettimeofday
local typeof = require('util.typeof')
local Proxy = require('session.proxy')
local Item = require('session.item')
local random = math.random
-- constants
local DEFAULT_TTL = 0
local DEFAULT_COOKIE = {
    name = 'sid',
    path = '/',
    httpOnly = true,
    secure = false
}

-- init random
math.randomseed(gettimeofday())

-- private
local function DEFAULT_IDGEN()
    return siphash48(gettimeofday(), tostring(random()):sub(1, 16))
end

-- class
local Session = require('halo').class.Session

function Session:init(cfg)
    local own = protected(self)
    local err, t, _

    if not typeof.table(cfg) then
        return nil, 'cfg must be table'
        -- check cfg.store
    elseif not typeof.table(cfg.store) or not typeof.Function(cfg.store.get) or
        not typeof.Function(cfg.store.set) or
        not typeof.Function(cfg.store.delete) then
        return nil, 'cfg.store must implements get, set and delete methods'
    end
    own.store = cfg.store

    -- check cfg.ttl
    own.ttl = cfg.ttl or DEFAULT_TTL
    if not typeof.uint(own.ttl) then return nil, 'cfg.ttl must be uint' end

    -- check id generator
    own.idgen = cfg.idgen or DEFAULT_IDGEN
    if not typeof.Function(own.idgen) then
        return nil, 'cfg.idgen must be function'
    end
    -- check generated value
    _ = own.idgen()
    if not typeof.string(_) or #_ < 1 then
        return nil, 'cfg.idgen() must return non-empty string value'
    end

    -- check cfg.cookie
    if cfg.cookie == nil then
        cfg.cookie = {}
    elseif not typeof.table(cfg.cookie) then
        return nil, 'cfg.cookie must be table'
    end
    -- copy field values
    own.cookie = {}
    for k, v in pairs(DEFAULT_COOKIE) do
        if cfg.cookie[k] then
            t = type(v)
            if t ~= type(cfg.cookie[k]) then
                return nil, ('cfg.cookie.%s must be %s'):format(k, t)
            elseif t == 'string' and #cfg.cookie[k] < 1 then
                return nil, ('cfg.cookie.%s must be non-empty string'):format(k)
            end
            own.cookie[k] = cfg.cookie[k]
        else
            own.cookie[k] = v
        end
    end
    -- set ttl to expires field
    own.cookie.expires = cfg.ttl
    -- test create
    _, err = Cookie.bake(own.cookie.name, '', own.cookie)
    if err then return nil, 'cfg.cookie.' .. err end

    return self
end

function Session:fetch(sid)
    if not typeof.string(sid) then return nil, 'sid must be string' end

    return Item.new(protected(self), sid)
end

function Session:create() return Item.new(protected(self)) end

return Session.exports
