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
local find = string.find
local is_str = require('lauxhlib.is').str
local is_table = require('lauxhlib.is').table
local fatalf = require('error').fatalf
local new_cookie = require('cookie').new
local bake_cookie = require('cookie').bake

--- @class session.cookie.config
--- @field name string session-cookie name.
--- @field domain string session-cookie domain.
--- @field path string session-cookie path.
--- @field secure boolean session-cookie secure.
--- @field httponly boolean session-cookie http-only.
--- @field samesite string session-cookie same-site.
--- @field maxage integer session-cookie max-age.

-- constants
--- session-cookie attributes
local DEFAULT_COOKIE_ATTR = {
    name = 'sid',
    domain = '',
    path = '/',
    maxage = 60 * 30,
    secure = true,
    httponly = true,
    samesite = 'lax',
}

--- parse_config parse cookie configuration
--- @param newcfg table<string, any>?
--- @return session.cookie.config
local function parse_config(newcfg)
    newcfg = newcfg == nil and {} or newcfg
    assert(is_table(newcfg), 'newcfg must be table')

    -- verify config
    local cfg = {}
    for k, defval in pairs(DEFAULT_COOKIE_ATTR) do
        if newcfg[k] ~= nil then
            cfg[k] = newcfg[k]
        else
            cfg[k] = defval
        end
    end

    -- remove empty domain
    if cfg.domain and find(cfg.domain, '^%s*$') then
        cfg.domain = nil
    end

    local ok, err = pcall(new_cookie, cfg.name, cfg)
    if not ok then
        fatalf(2, 'invalid cookie configuration: %s', err)
    end
    return cfg
end

--- @class session.cookie
--- @field cfg session.cookie.config
local Cookie = {}

--- init
--- @param cfg session.cookie.config a cache field will be ignored.
--- @return session.cookie
function Cookie:init(cfg)
    cfg = cfg == nil and {} or cfg
    assert(is_table(cfg), 'cfg must be table')
    self.cfg = parse_config(cfg)
    return self
end

--- get_config get cookie configuration
--- @param attr string?
--- @return any
function Cookie:get_config(attr)
    if attr ~= nil then
        return DEFAULT_COOKIE_ATTR[attr] and self.cfg[attr] or nil
    end

    -- return all cookie attributes
    return {
        name = self.cfg.name,
        domain = self.cfg.domain,
        path = self.cfg.path,
        maxage = self.cfg.maxage,
        secure = self.cfg.secure,
        httponly = self.cfg.httponly,
        samesite = self.cfg.samesite,
    }
end

--- set_config set cookie configuration
--- @param attr string|table
--- @param val any
function Cookie:set_config(attr, val)
    if attr == nil then
        fatalf(2, 'attr must be string or table')
    elseif is_str(attr) then
        local defval = DEFAULT_COOKIE_ATTR[attr]
        if not defval then
            fatalf(2, 'unsupported cookie attribute: %q', attr)
        end

        val = {
            [attr] = val or defval,
        }
    elseif not is_table(attr) then
        fatalf(2, 'attr must be table<string, any>')
    elseif val ~= nil then
        fatalf(2, 'val must be nil if attr is table')
    else
        val = attr
    end
    self.cfg = parse_config(val)
end

--- bake bake a cookie
--- @param val string
--- @return string cookie
function Cookie:bake(val)
    if not is_str(val) then
        fatalf(2, 'val must be string')
    end
    return bake_cookie(self.cfg.name, val, self.cfg)
end

--- bake_void bake a expired cookie
--- @return string cookie
function Cookie:bake_void()
    local cfg = self:get_config()
    cfg.maxage = -cfg.maxage
    return bake_cookie(self.cfg.name, 'void', cfg)
end

return {
    new = require('metamodule').new(Cookie),
    parse_cookies = require('cookie').parse_cookies,
    parse_baked_cookie = require('cookie').parse_baked_cookie,
}

