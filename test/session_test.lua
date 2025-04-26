require('luacov')
local testcase = require('testcase')
local assert = require('assert')
local new_session = require('session').new
local parse_baked_cookie = require('cookie').parse_baked_cookie
local decode_json = require('yyjson').decode

function testcase.getid()
    local m = assert(new_session())
    local s = m:create()

    -- test that get an id
    assert.re_match(s:getid(), '^[0-9A-Z]+_[0-9a-zA-Z]+$')
end

function testcase.set_get()
    local m = assert(new_session())
    local s = m:create()

    -- test that set a value
    local ok, err = s:set('foo', {
        bar = {
            'baz',
        },
    })
    assert.is_nil(err)
    assert.is_true(ok)

    -- test that get a value
    assert.equal(s:get('foo'), {
        bar = {
            'baz',
        },
    })

    -- test that returns nil if key is not exists
    assert.is_nil(s:get('bar'))

    -- test that overwrite a value
    ok, err = s:set('foo', {
        hello = 'world',
    })
    assert.is_nil(err)
    assert.is_true(ok)
    assert.equal(s:get('foo'), {
        hello = 'world',
    })

    -- test that get() method returns a reference of the stored data
    local foo = s:get('foo')
    foo.bar = 'baz'
    assert.equal(s:get('foo'), {
        hello = 'world',
        bar = 'baz',
    })

    -- test that set a value with nil to delete it
    ok, err = s:set('foo')
    assert.is_nil(err)
    assert.is_true(ok)
    assert.is_nil(s:get('foo'))

    -- test that return error if value contains circular reference
    local data = {
        foo = {
            bar = {
                'baz',
            },
        },
    }
    data.foo.baz = {
        data = data,
    }
    ok, err = s:set('circular', data)
    assert.match(err, 'cannot clone circular reference at "foo.baz.data"')
    assert.is_false(ok)

    -- test that return error if value is not cloneable
    ok, err = s:set('hello', function()
    end)
    assert.match(err, 'cannot save "function" value into session')
    assert.is_false(ok)

    -- test that throw error if key is not valid
    err = assert.throws(s.set, s, 1, 'world')
    assert.match(err, 'key must be string with pattern "^%a[%w_]*$"')
end

function testcase.getall()
    local m = assert(new_session())
    local s = m:create()
    assert(s:set('a', 1))
    assert(s:set('b', 'test'))
    assert(s:set('c', true))

    -- test that get all values
    assert.equal(s:getall(), {
        a = 1,
        b = 'test',
        c = true,
    })

    -- test that getall() method returns a reference of the stored data
    local all = s:getall()
    all.foo = 'baz'
    assert.equal(s:get('foo'), 'baz')
end

function testcase.get_copy()
    local m = assert(new_session())
    local s = m:create()
    assert(s:set('foo', {
        bar = {
            'baz',
        },
    }))

    -- test that get a copy of the value
    local foo = s:get_copy('foo')
    foo.bar = 'qux'
    assert.equal(s:get('foo'), {
        bar = {
            'baz',
        },
    })
end

function testcase.getall_copy()
    local m = assert(new_session())
    local s = m:create()
    assert(s:set('a', 1))
    assert(s:set('b', 'test'))
    assert(s:set('c', true))

    -- test that get a copy of all values
    local all = s:getall_copy()
    all.foo = 'baz'
    assert.equal(s:getall(), {
        a = 1,
        b = 'test',
        c = true,
    })
end

function testcase.delete()
    local m = assert(new_session())
    local s = m:create()
    assert(s:set('foo', {
        bar = {
            'baz',
        },
    }))

    -- test that delete a value and return it
    assert.equal(s:delete('foo'), {
        bar = {
            'baz',
        },
    })

    -- test that returns nil if key is not exists
    assert.is_nil(s:delete('foo'))
end

function testcase.save()
    local do_err
    local do_timeout
    local store = {
        values = {},
        keys = function()
        end,
        set = function(self, sid, data)
            if do_err then
                return false, 'set error'
            elseif do_timeout then
                return false, nil, true
            end

            self.values[sid] = data
            return true
        end,
        get = function()
        end,
        delete = function()
        end,
        rename = function()
        end,
        evict = function()
        end,
    }
    local m = assert(new_session({
        store = store,
    }))
    local s = m:create()
    assert(s:set('foo', {
        bar = {
            'baz',
        },
    }))

    -- test that save session data into the store via manager object and return baked cookie
    local bcookie, err, timeout = s:save()
    assert.is_nil(err)
    assert.is_nil(timeout)
    assert.is_string(bcookie)
    -- verify session data is saved
    local sid, data = next(store.values)
    -- verify baked cookie
    local cookie = assert(parse_baked_cookie(bcookie))
    assert.contains(cookie, {
        httponly = true,
        maxage = 1800,
        name = 'sid',
        path = '/',
        samesite = 'lax',
        secure = true,
        value = sid,
    })
    assert.equal(decode_json(data), {
        foo = {
            bar = {
                'baz',
            },
        },
    })

    -- test that returns error message
    do_err = true
    bcookie, err, timeout = s:save()
    assert.match(err, 'failed to save session')
    assert.is_false(timeout)
    assert.is_nil(bcookie)
    do_err = false

    -- test that returns timeout
    do_timeout = true
    bcookie, err, timeout = s:save()
    assert.is_nil(bcookie)
    assert.is_nil(err)
    assert.is_true(timeout)
end

function testcase.rename()
    local do_err
    local do_timeout
    local store = {
        values = {},
        keys = function()
        end,
        set = function(self, sid, data)
            self.values[sid] = data
            return true
        end,
        get = function(self, sid)
            return self.values[sid]
        end,
        delete = function()
        end,
        rename = function(self, oldsid, newsid)
            if do_err then
                return false, 'rename error'
            elseif do_timeout then
                return false, nil, true
            end

            local v = self.values[oldsid]
            if not v then
                return false
            end
            self.values[newsid], self.values[oldsid] = v, nil
            return true
        end,
        evict = function()
        end,
    }
    local m = new_session({
        store = store,
    })
    local s = m:create()
    assert(s:set('foo', {
        bar = {
            'baz',
        },
    }))
    assert(s:save())

    -- test that rename session-id and returns baked cookie with new session-id
    local oldid = s:getid()
    local bcookie, err, timeout = s:rename()
    assert.is_nil(err)
    assert.is_nil(timeout)
    -- verify backed cookie
    assert.is_string(bcookie)
    local cookie = assert(parse_baked_cookie(bcookie))
    assert.contains(cookie, {
        httponly = true,
        maxage = 1800,
        name = 'sid',
        path = '/',
        samesite = 'lax',
        secure = true,
        value = s:getid(),
    })
    -- verify session data is renamed
    assert.is_nil(store.values[oldid])
    assert.equal(decode_json(store.values[s:getid()]), {
        foo = {
            bar = {
                'baz',
            },
        },
    })

    -- test that returns error message
    do_err = true
    bcookie, err, timeout = s:rename()
    assert.match(err, 'failed to rename session-id')
    assert.is_false(timeout)
    assert.is_nil(bcookie)
    do_err = false

    -- test that returns timeout
    do_timeout = true
    bcookie, err, timeout = s:rename()
    assert.is_nil(bcookie)
    assert.is_nil(err)
    assert.is_true(timeout)
end

function testcase.destroy()
    local do_err
    local do_timeout
    local store = {
        values = {},
        keys = function()
        end,
        set = function(self, sid, data)
            self.values[sid] = data
            return true
        end,
        get = function(self, sid)
            return self.values[sid]
        end,
        delete = function(self, sid)
            if do_err then
                return false, 'delete error'
            elseif do_timeout then
                return false, nil, true
            end

            self.values[sid] = nil
            return true
        end,
        rename = function()
        end,
        evict = function()
        end,
    }
    local m = new_session({
        store = store,
    })
    local s = m:create()
    assert(s:set('foo', {
        bar = {
            'baz',
        },
    }))
    assert(s:save())
    local sid = s:getid()
    s = m:fetch(sid)
    assert.re_match(s, '^session[.]Session:')
    assert.equal(s:getall(), {
        foo = {
            bar = {
                'baz',
            },
        },
    })

    -- test that destroy session data and returns baked cookie
    local bcookie, err, timeout = s:destroy()
    assert.is_nil(err)
    assert.is_nil(timeout)
    -- verify backed cookie
    assert.is_string(bcookie)
    local cookie = assert(parse_baked_cookie(bcookie))
    assert.contains(cookie, {
        httponly = true,
        maxage = -1800,
        name = 'sid',
        path = '/',
        samesite = 'lax',
        secure = true,
        value = 'void',
    })
    -- verify session data is destroyed
    assert.is_nil(m:fetch(sid))
    assert.is_nil(next(store.values))

    -- test that returns error message
    do_err = true
    bcookie, err, timeout = s:destroy()
    assert.re_match(err, 'failed to destroy session')
    assert.is_false(timeout)
    assert.is_nil(bcookie)
    do_err = false

    -- test that returns timeout
    do_timeout = true
    bcookie, err, timeout = s:destroy()
    assert.is_nil(bcookie)
    assert.is_nil(err)
    assert.is_true(timeout)
end

