require('luacov')
local testcase = require('testcase')
local assert = require('assert')
local parse_baked_cookie = require('cookie').parse_baked_cookie
local new_cookie = require('session.cookie').new

function testcase.new()
    -- test that create new cookie instance with default configuration
    local c = new_cookie()
    assert.re_match(c, '^session.cookie: ')
    assert.contains(c.cfg, {
        name = 'sid',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'lax',
        maxage = 1800,
    })

    -- test that create new cookie instance with custom configuration
    c = new_cookie({
        name = 'test',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'strict',
        maxage = 3600,
    })
    assert.contains(c.cfg, {
        name = 'test',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'strict',
        maxage = 3600,
    })

    -- test that throw error if name is invalid
    local err = assert.throws(new_cookie, {
        name = 'foo bar', -- invalid name with space
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'invalid',
        maxage = 3600,
    })
    assert.re_match(err, 'name must be valid cookie-name')

    -- test that throw error if samesite is invalid
    err = assert.throws(new_cookie, {
        name = 'test',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'invalid',
        maxage = 3600,
    })
    assert.re_match(err, 'samesite must be "strict", "lax" or "none"')
end

function testcase.get_config()
    -- test that get cookie default configuration
    local c = new_cookie()
    assert.equal(c:get_config('name'), 'sid')
    assert.equal(c:get_config('path'), '/')
    assert.equal(c:get_config('secure'), true)
    assert.equal(c:get_config('httponly'), true)
    assert.equal(c:get_config('samesite'), 'lax')
    assert.equal(c:get_config('maxage'), 1800)

    -- test that get cookie configuration
    c = new_cookie({
        name = 'test',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'strict',
        maxage = 3600,
    })
    assert.equal(c:get_config('name'), 'test')
    assert.equal(c:get_config('path'), '/')
    assert.equal(c:get_config('secure'), true)
    assert.equal(c:get_config('httponly'), true)
    assert.equal(c:get_config('samesite'), 'strict')
    assert.equal(c:get_config('maxage'), 3600)

    -- test that return all cookie attributes
    local cfg = c:get_config()
    assert.equal(cfg, {
        name = 'test',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'strict',
        maxage = 3600,
    })

    -- test that return nil if key is not valid
    assert.is_nil(c:get_config('invalid'))
end

function testcase.set_config()
    -- test that set cookie configuration
    local c = new_cookie()
    for k, v in pairs({
        name = 'test',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'strict',
        maxage = 3600,
    }) do
        c:set_config(k, v)
        assert.equal(c.cfg[k], v)
    end

    -- test that set default configuration
    c:set_config('name')
    assert.equal(c.cfg.name, 'sid')

    -- test that set configuration with table value
    c:set_config({
        name = 'test2',
        domain = 'example.com',
        path = '/foo',
        secure = false,
        httponly = false,
        maxage = 36,
    })
    assert.equal(c:get_config(), {
        name = 'test2',
        domain = 'example.com',
        path = '/foo',
        secure = false,
        httponly = false,
        samesite = 'lax',
        maxage = 36,
    })

    -- test that remove domain event it is empty string
    c:set_config('domain', '  \t \t  \n')
    assert.is_nil(c:get_config('domain'))

    -- test that throw error if key is unsupported
    local err = assert.throws(c.set_config, c, 'invalid', 'test')
    assert.re_match(err, 'unsupported cookie attribute: "invalid"')

    -- test that throw error if key is nil
    err = assert.throws(c.set_config, c)
    assert.re_match(err, 'attr must be string or table')

    -- test that throw error if key is neither string nor table
    err = assert.throws(c.set_config, c, 1)
    assert.re_match(err, 'attr must be table')

    -- test that throw error if key is table but value is not nil
    err = assert.throws(c.set_config, c, {
        name = 'test',
    }, 1)
    assert.re_match(err, 'val must be nil')

    -- test that throw error if value type is invalid
    for k, a in pairs({
        name = {
            val = 1,
            expect = 'name must be valid cookie-name',
        },
        path = {
            val = 1,
            expect = 'path must be string',
        },
        secure = {
            val = 1,
            expect = 'secure must be boolean',
        },
        httponly = {
            val = 1,
            expect = 'httponly must be boolean',
        },
        samesite = {
            val = 'foo',
            expect = 'samesite must be "strict", "lax" or "none"',
        },
        maxage = {
            val = 'foo',
            expect = 'maxage must be integer',
        },
    }) do
        err = assert.throws(c.set_config, c, k, a.val)
        assert.re_match(err, a.expect)
    end
end

function testcase.bake()
    -- test that bake cookie with default configuration
    local c = new_cookie()
    local cookie = c:bake('test')
    local act = assert(parse_baked_cookie(cookie))
    assert.contains(act, {
        name = 'sid',
        value = 'test',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'lax',
        maxage = 1800,
    })

    -- test that bake cookie with custom configuration
    c = new_cookie({
        name = 'test',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'strict',
        maxage = 3600,
    })
    cookie = c:bake('test')
    act = assert(parse_baked_cookie(cookie))
    assert.contains(act, {
        name = 'test',
        value = 'test',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'strict',
        maxage = 3600,
    })

    -- test that throw error if sid is not string
    local err = assert.throws(c.bake, c, 1)
    assert.re_match(err, 'val must be string')

    -- test that throw error if sid is invalid cookie string
    err = assert.throws(c.bake, c, 'foo bar')
    assert.re_match(err, 'val must be valid cookie-value')
end

function testcase.bake_void()
    -- test that bake a expired cookie
    local c = new_cookie()
    local cookie = c:bake_void()
    local act = assert(parse_baked_cookie(cookie))
    assert.contains(act, {
        name = 'sid',
        value = 'void',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'lax',
        maxage = -1800,
    })
end
