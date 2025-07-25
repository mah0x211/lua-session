require('luacov')
local testcase = require('testcase')
local sleep = require('testcase.timer').sleep
local assert = require('assert')
local getmsec = require('time.clock').getmsec
local idgen = require('session.idgen')
local base32decode = require('base32').decode
local CLOCK_REALTIME = require('time.clock').CLOCK_REALTIME

local function decode_msec(ts)
    -- decode crockford's base32 encoded timestamp
    local bytes = assert(base32decode(ts, 'crockford'))
    -- convert 6-byte big-endian byte string to msec
    local b = {
        string.byte(bytes, 1, 6),
    }
    return b[1] * 0x10000000000 + b[2] * 0x100000000 + b[3] * 0x1000000 + b[4] *
               0x10000 + b[5] * 0x100 + b[6]
end

function testcase.idgen()
    -- test that generate session-id
    local msec = getmsec(CLOCK_REALTIME)
    local id, err = idgen()
    assert.is_nil(err)
    assert.is_string(id)

    -- confirm that first 10 characters is a 0-padded crockford base32 encoded timestamp
    local prefix = id:sub(1, 10)
    local num = decode_msec(prefix)
    assert.less_or_equal(num - msec, 1)

    -- confirm that last 16 characters is a crockford base32 encoded random string
    local suffix = id:sub(#id - 15)
    assert.re_match(suffix, '^[0-9a-zA-Z]{16}$')

    -- test that generate session-ids are unique and sortable in lexicographic order
    local ids = {}
    for _ = 1, 250 do
        id, err = idgen()
        assert.is_nil(err)
        assert.is_string(id)
        assert.is_nil(ids[id])
        ids[#ids + 1] = id
        sleep(0.0001)
    end

    -- verify that sorted in lexicographic order
    table.sort(ids)
    local prev
    for i = 1, #ids do
        id = ids[i]
        local ts = id:sub(1, 10)
        if prev then
            assert.is_true(prev <= ts)
        end
        prev = ts
    end
end

