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
local sub = string.sub
local upper = string.upper
local floor = math.floor
local is_uint = require('lauxhlib.is').uint
local is_str = require('lauxhlib.is').str

--
-- build encoding and decoding table for crockford's base32
--  https://www.crockford.com/base32.html
--
-- the symbol set of 10 digits and 22 letters.
-- omitting I, L, O and U to avoid confusion.
--
local ENC_CHARS = {
    [0] = '0',
}
local DEC_CHARS = {
    ['0'] = 0,
}
string.gsub('123456789ABCDEFGHJKMNPQRSTVWXYZ', '%w', function(c)
    ENC_CHARS[#ENC_CHARS + 1] = c
    DEC_CHARS[c] = #ENC_CHARS
end)

--- encode number to crockford's base32 string
--- @param num number
--- @return string res
--- @return any err
local function encode(num)
    if not is_uint(num) then
        return nil, 'num must be unsigned integer'
    end

    local res = ''
    repeat
        local rem = num % 32
        res = ENC_CHARS[rem] .. res
        num = floor(num / 32)
    until num == 0
    return res
end

--- decode crockford's base32 string to number
--- @param str string
--- @return number res
--- @return any err
local function decode(str)
    if not is_str(str) then
        return nil, 'str must be string'
    end

    local res = 0
    for i = 1, #str do
        local num = DEC_CHARS[upper(sub(str, i, i))]
        if not num then
            return nil, 'invalid character'
        end
        res = res * 32 + num
    end
    return res
end

return {
    encode = encode,
    decode = decode,
}
