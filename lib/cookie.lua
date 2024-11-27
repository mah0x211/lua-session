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
local pairs = pairs
local pcall = pcall
local is_str = require('lauxhlib.is').str
local is_table = require('lauxhlib.is').table
local fatalf = require('error').fatalf
local new_cookie = require('cookie').new
local bake_cookie = require('cookie').bake

--- @class session.cookie.config
--- @field name string session-cookie name.
--- @field path string session-cookie path.
--- @field secure boolean session-cookie secure.
--- @field httponly boolean session-cookie http-only.
--- @field samesite string session-cookie same-site.
--- @field maxage integer session-cookie max-age.

-- constants
--- session-cookie attributes
local DEFAULT_COOKIE_ATTR = {
    name = 'sid',
    path = '/',
    maxage = 60 * 30,
    secure = true,
    httponly = true,
    samesite = 'lax',
}

--- parse_config parse cookie configuration and copy to dest
--- @param dest table
--- @param cfg session.cookie.config
local function parse_config(dest, cfg)
    cfg = cfg == nil and {} or cfg
    if not is_table(cfg) then
        fatalf(2, 'cfg must be table')
    end

    -- verify config
    for k, defval in pairs(DEFAULT_COOKIE_ATTR) do
        if cfg[k] == nil then
            cfg[k] = defval
        end
        dest[k] = cfg[k]
    end
    local ok, err = pcall(new_cookie, cfg.name, cfg)
    if not ok then
        fatalf(2, 'invalid cookie configuration: %s', err)
    end
end

--- @class session.cookie
--- @field name string
--- @field path string
--- @field maxage integer default 1800 sec (30 min)
--- @field secure boolean
--- @field httponly boolean
--- @field samesite string 'none' | 'lax' | 'strict', default 'lax'
local Cookie = {}

--- init
--- @param cfg session.cookie.config a cache field will be ignored.
--- @return session.cookie
function Cookie:init(cfg)
    parse_config(self, cfg)
    return self
end

--- bake bake a cookie
--- @param val string
--- @return string cookie
function Cookie:bake(val)
    if not is_str(val) then
        fatalf(2, 'val must be string')
    end
    return bake_cookie(self.name, val, self)
end

--- bake_void bake a expired cookie
--- @return string cookie
function Cookie:bake_void()
    return bake_cookie(self.name, 'void', {
        path = self.path,
        secure = self.secure,
        httponly = self.httponly,
        samesite = self.samesite,
        maxage = -self.maxage,
    })
end

return {
    new = require('metamodule').new(Cookie),
    parse_cookies = require('cookie').parse_cookies,
    parse_baked_cookie = require('cookie').parse_baked_cookie,
    parse_config = parse_config,
}

