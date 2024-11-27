require('luacov')
local testcase = require('testcase')
local assert = require('assert')
local parse_baked_cookie = require('cookie').parse_baked_cookie
local parse_config = require('session.cookie').parse_config
local new_cookie = require('session.cookie').new

function testcase.parse_config()
    -- test that copy default configuration if config is nil
    local c = {}
    assert.not_throws(parse_config, c)
    assert.equal(c, {
        name = 'sid',
        path = '/',
        secure = true,
        httponly = true,
        samesite = 'lax',
        maxage = 1800,
    })

    -- test that copy default configuration if a field is nil
    assert.not_throws(parse_config, c, {
        name = 'my-session-id',
        secure = false,
    })
    assert.equal(c, {
        name = 'my-session-id',
        path = '/',
        secure = false,
        httponly = true,
        samesite = 'lax',
        maxage = 1800,
    })

    -- test that throw error if config is not table
    local err = assert.throws(parse_config, c, 1)
    assert.re_match(err, 'cfg must be table')
end

function testcase.new()
    -- test that create new cookie instance with default configuration
    local c = new_cookie()
    assert.contains(c, {
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
    assert.contains(c, {
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
