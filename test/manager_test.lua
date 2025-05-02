require('luacov')
local testcase = require('testcase')
local assert = require('assert')
local decode_json = require('yyjson').decode
local new_session = require('session').new

function testcase.new()
    -- test that create new session manager
    local m = new_session()
    assert.re_match(m, '^session\\.Manager: ')

    -- test that create new session.store with config options
    local idgen = function()
        return 'test'
    end
    local ncall = 0
    local storefn = function()
        ncall = ncall + 1
        return true
    end
    local store = {
        set = storefn,
        get = storefn,
        delete = storefn,
        rename = storefn,
        keys = storefn,
        evict = storefn,
    }
    m = assert.not_throws(new_session, {
        store = store,
        idgen = idgen,
        cookie = {
            name = 'test',
            path = '/',
            secure = true,
            httpOnly = true,
            samesite = 'lax',
        },
    })
    assert.re_match(m, '^session\\.Manager: ')

    -- test that throw error if cfg is not a table
    local err = assert.throws(new_session, 1)
    assert.re_match(err, 'cfg .+ must be table')

    -- test that throw error if cookie_cfg is not table
    err = assert.throws(new_session, {
        cookie = 'test',
    })
    assert.re_match(err, 'invalid cfg.cookie')

    -- test that throw error if invalid cookie_cfg
    err = assert.throws(new_session, {
        cookie = {
            maxage = 'invalid',
        },
    })
    assert.re_match(err, 'maxage must be integer')

    -- test that throw error if a store has not required methods
    err = assert.throws(new_session, {
        store = {},
    })
    assert.re_match(err, 'invalid cfg.store')

    -- test that throw error if idgen is not a function
    err = assert.throws(new_session, {
        idgen = 1,
    })
    assert.re_match(err, 'cfg.idgen .+ must be function')

    -- test that throw error if idgen does not return a non-empty string
    err = assert.throws(new_session, {
        idgen = function()
            return ''
        end,
    })
    assert.match(err, 'idgen() did not return a non-empty string')
end

function testcase.create()
    local m = assert(new_session({
        idgen = function()
            return 'test-id'
        end,
    }))

    -- test that create new session object
    local s = m:create()
    assert.re_match(s, '^session.Session: ')
    assert.equal(s.id, 'test-id')

    -- test that throw error if idgen() returns nil
    m.idgen = function()
        return nil, 'test error'
    end
    local err = assert.throws(function()
        m:create()
    end)
    assert.match(err, 'idgen() did not return a non-empty string')
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

    -- test that save data into store
    local a = math.random()
    local b = math.random()
    local ok, err, timeout = m:save('test', {
        a = a,
        b = b,
    })
    assert.is_nil(err)
    assert.is_nil(timeout)
    assert.is_true(ok)
    assert.equal(decode_json(store.values['test']), {
        a = a,
        b = b,
    })

    -- test that throw error if session-id is not a string
    err = assert.throws(m.save, m, {})
    assert.re_match(err, 'sid must be string')

    -- test that throw error if data is not a table
    err = assert.throws(m.save, m, 'test', 'invalid')
    assert.re_match(err, 'data must be table')

    -- test that return store error
    do_err = true
    ok, err, timeout = m:save('test', {
        a = a,
        b = b,
    })
    assert.is_false(timeout)
    assert.re_match(err, 'set error')
    assert.is_false(ok)
    do_err = false

    -- test that return store timeout
    do_timeout = true
    ok, err, timeout = m:save('test', {
        a = a,
        b = b,
    })
    assert.is_true(timeout)
    assert.is_nil(err)
    assert.is_false(ok)
end

function testcase.fetch()
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
            if do_err then
                return nil, 'get error'
            elseif do_timeout then
                return nil, nil, true
            end

            return self.values[sid]
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
    local a = math.random()
    local b = math.random()
    assert(m:save('test', {
        data = {
            a = a,
            b = b,
        },
    }))

    -- test that fetch session
    local s, err, timeout = m:fetch('test')
    assert.is_nil(err)
    assert.is_nil(timeout)
    assert.re_match(s, '^session.Session: ')
    assert.equal(s.data, {
        a = a,
        b = b,
    })

    -- test that cannot fetch session with invalid session-id
    s, err, timeout = m:fetch('invalid')
    assert.is_nil(s)
    assert.is_nil(err)
    assert.is_false(timeout)

    -- test that return store error
    do_err = true
    s, err, timeout = m:fetch('test')
    assert.is_nil(s)
    assert.is_false(timeout)
    assert.re_match(err, 'get error')
    do_err = false

    -- test that return store timeout
    do_timeout = true
    s, err, timeout = m:fetch('test')
    assert.is_nil(s)
    assert.is_true(timeout)
    assert.is_nil(err)

    -- test that throw error if session-id is not a string
    err = assert.throws(m.fetch, m, {})
    assert.re_match(err, 'sid .+ must be string')
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
    local m = assert(new_session({
        store = store,
    }))
    local a = math.random()
    local b = math.random()
    assert(m:save('test', {
        data = {
            a = a,
            b = b,
        },
    }))

    -- test that rename session-id
    local newsid, err, timeout = m:rename('test')
    assert.is_nil(err)
    assert.is_nil(timeout)
    assert.is_string(newsid)
    assert.not_equal(newsid, 'test')
    -- verify that old session-id is removed
    local s
    s, err, timeout = m:fetch('test')
    assert.is_nil(err)
    assert.is_false(timeout)
    assert.is_nil(s)
    -- verify that a value associated with new session-id
    s, err, timeout = m:fetch(newsid)
    assert.is_nil(err)
    assert.is_nil(timeout)
    assert.re_match(s, '^session.Session: ')
    assert.equal(s.data, {
        a = a,
        b = b,
    })

    -- test that returns nothing if specified session-id is not found
    local noval
    noval, err, timeout = m:rename('unknown-id')
    assert.is_nil(err)
    assert.is_false(timeout)
    assert.is_nil(noval)

    -- test that return error if invalid session-id is specified
    noval, err, timeout = m:rename('unknown id')
    assert.match(err, 'failed to rename')
    assert.is_false(timeout)
    assert.is_nil(noval)

    -- test that return store error
    do_err = true
    noval, err, timeout = m:rename('test')
    assert.is_false(timeout)
    assert.re_match(err, 'rename error')
    assert.is_nil(noval)
    do_err = false

    -- test that return store timeout
    do_timeout = true
    noval, err, timeout = m:rename('test')
    assert.is_true(timeout)
    assert.is_nil(err)
    assert.is_nil(noval)

    -- test that throw error if session-id is not a string
    err = assert.throws(m.rename, m, {})
    assert.re_match(err, 'sid .+ must be string')
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
    local m = assert(new_session({
        store = store,
    }))
    local a = math.random()
    local b = math.random()
    assert(m:save('test', {
        a = a,
        b = b,
    }))

    -- test that destroy a value associated with session-id
    local ok, err, timeout = m:destroy('test')
    assert.is_nil(err)
    assert.is_nil(timeout)
    assert.is_true(ok)
    -- verify that a value associated with session-id is removed
    local s
    s, err, timeout = m:fetch('test')
    assert.is_nil(err)
    assert.is_false(timeout)
    assert.is_nil(s)

    -- test that return store error
    do_err = true
    ok, err, timeout = m:destroy('test')
    assert.is_false(timeout)
    assert.re_match(err, 'delete error')
    assert.is_false(ok)
    do_err = false

    -- test that return store timeout
    do_timeout = true
    ok, err, timeout = m:destroy('test')
    assert.is_true(timeout)
    assert.is_nil(err)
    assert.is_false(ok)

    -- test that throw error if session-id is not a string
    err = assert.throws(m.destroy, m, {})
    assert.re_match(err, 'sid .+ must be string')
end

function testcase.evict()
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
        get = function()
        end,
        delete = function()
        end,
        rename = function()
        end,
        evict = function(self, callback, n)
            if do_err then
                return 0, 'evict error'
            elseif do_timeout then
                return 0, nil, true
            end

            local nevict = 0
            while next(self.values) and n ~= 0 do
                for sid in pairs(self.values) do
                    local ok, err = callback(sid)
                    if not ok or err then
                        return nevict, err
                    end
                    self.values[sid] = nil
                    nevict = nevict + 1
                    n = n - 1
                end
            end
            return nevict
        end,
    }
    local m = assert(new_session({
        store = store,
    }))
    assert(m:save('test', {
        foo = 'bar',
    }))
    assert(m:save('hello', {
        'world',
    }))

    -- test that evict values
    local n, err, timeout = m:evict()
    assert.is_nil(err)
    assert.is_false(timeout)
    assert.equal(n, 2)
    assert.is_nil(next(store.values))

    -- test that return store error
    do_err = true
    n, err, timeout = m:evict()
    assert.is_false(timeout)
    assert.re_match(err, 'evict error')
    assert.equal(n, 0)
    do_err = false

    -- test that return backend timeout
    do_timeout = true
    n, err, timeout = m:evict()
    assert.is_true(timeout)
    assert.is_nil(err)
    assert.equal(n, 0)
end

