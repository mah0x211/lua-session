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
-- modules
local rep = string.rep
local getmsec = require('time.clock').getmsec
local randstr = require('string.random')
local errorf = require('error').format
local base32encode = require('session.base32').encode
local CLOCK_REALTIME = require('time.clock').CLOCK_REALTIME

--- idgen returns a sortable string id.
--- The id is composed of the crockford's base32 encoded current time in
--- milliseconds and a random string with 6 characters of alphanumeric.
--- @return string id
local function idgen()
    local msec, err = getmsec(CLOCK_REALTIME)
    if not msec then
        return nil, errorf('failed to get current time: %s', err)
    end

    local ts = base32encode(msec)
    local n = #ts
    return (n < 10 and rep('0', 10 - n) or '') .. ts .. '_' ..
               randstr(6, 'alnum')
end

return idgen
