require('luacov')
local testcase = require('testcase')
local sleep = require('testcase.timer').sleep
local assert = require('assert')
local getmsec = require('time.clock').getmsec
local idgen = require('session.idgen')
local base32decode = require('session.base32').decode
local CLOCK_REALTIME = require('time.clock').CLOCK_REALTIME

function testcase.idgen()
    -- test that generate session-id
    local msec = getmsec(CLOCK_REALTIME)
    local id, err = idgen()
    assert.is_nil(err)
    assert.is_string(id)
    -- prefix string is crockford's base32 encoded string
    local prefix = id:sub(1, #id - 7)
    local num = assert(base32decode(prefix))
    -- prefix is current time in msec
    assert.less_or_equal(num - msec, 1)

    -- suffix string must be 7 characters long and starts with '-'
    local suffix = id:sub(#id - 6)
    assert.re_match(suffix, '^\\_[0-9a-zA-Z]{6}$')

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
    table.sort(ids)
    -- verify that sorted in lexicographic order
    local prev
    for i = 1, #ids do
        num = assert(base32decode(ids[i]:sub(1, #id - 7)))
        if prev then
            assert.less_or_equal(prev - num, 1)
        end
        prev = num
    end
end

