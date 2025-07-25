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
local floor = math.floor
local rep = string.rep
local char = string.char
local pack = string.pack
local errorf = require('error').format
local base32encode = require('base32').encode
local getmsec = require('time.clock').getmsec
local CLOCK_REALTIME = require('time.clock').CLOCK_REALTIME

--- Generate 0-padded crockford base32 encoded timestamp.
local function get_timestamp()
    local msec, err = getmsec(CLOCK_REALTIME)
    if not msec then
        return nil, errorf('failed to get current time: %s', err)
    end

    -- convert msec to 6-byte big-endian byte string manually
    local bytes = pack and pack('>I6', msec) or
                      char(floor(msec / 0x10000000000) % 256,
                           floor(msec / 0x100000000) % 256,
                           floor(msec / 0x1000000) % 256,
                           floor(msec / 0x10000) % 256,
                           floor(msec / 0x100) % 256, msec % 256)

    -- create 0 padded crockford base32 encoded timestamp
    local ts = base32encode(bytes, 'crockford')
    local n = #ts
    ts = (n < 10 and rep('0', 10 - n) or '') .. ts
    return ts
end

-- random string generator
local randstr = require('string.random')

--- generates a ULID-compatible ID
--- @return string? id
--- @return any err
local function idgen()
    local ts, err = get_timestamp()
    if not ts then
        return nil, errorf('failed to get current time: %s', err)
    end

    -- create crockford base32 encoded 16 characters random string
    local s, _
    s, _, err = randstr(16, 'base32crockford')
    if not s then
        return nil, errorf('failed to generate random bytes: %s', err)
    end

    return ts .. s
end

return idgen
