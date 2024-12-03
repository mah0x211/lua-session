require('luacov')
local testcase = require('testcase')
local assert = require('assert')
local base32encode = require('session.base32').encode
local base32decode = require('session.base32').decode

function testcase.encode()
    -- test that encode a number to crockford's base32 string
    local n = math.random(12345, 56789)
    local res, err = base32encode(n)
    assert.is_nil(err)
    assert.is_string(res)

    -- test that returns an error if argument is not a number
    for _, v in ipairs({
        -1,
        true,
        false,
        'string',
        {},
    }) do
        res, err = base32encode(v)
        assert.is_nil(res)
        assert.match(err, 'num must be unsigned integer')
    end
end

function testcase.decode()
    local n = math.random(12345, 56789)
    local res, err = base32encode(n)
    assert.is_nil(err)
    assert.is_string(res)

    -- test that decode a crockford's base32 string to number
    res, err = base32decode(res)
    assert.is_nil(err)
    assert.equal(res, n)

    -- test that returns an error if argument is not a string
    for _, v in ipairs({
        -1,
        true,
        false,
        {},
    }) do
        res, err = base32decode(v)
        assert.is_nil(res)
        assert.match(err, 'str must be string')
    end

    -- test that returns an error if argument is not a valid base32 string
    for _, v in ipairs({
        '12I',
        '34O',
        '56U',
    }) do
        res, err = base32decode(v)
        assert.is_nil(res)
        assert.match(err, 'invalid character')
    end
end

