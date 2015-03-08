--[[
  
  Copyright (C) 2014 Masatoshi Teruya

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:
 
  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.
 
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
  THE SOFTWARE.
   
  lib/dataproxy.lua
  lua-session
  
  Created by Masatoshi Teruya on 14/12/08.
  
--]]

-- module
local typeof = require('util.typeof');
local cloneSafe = require('util.table').cloneSafe;

-- class
local Proxy = require('halo').class.Proxy;


function Proxy:__index( prop )
    return protected( self ).data[prop];
end


function Proxy:__newindex( prop, val )
    if not typeof.string( prop ) then
        error( 'session field-name must be string', 2 );
    elseif val == nil then
        protected( self ).data[prop] = nil;
    else
        local cval = cloneSafe( val );
        
        if cval == nil then
            error(
                ('cannot save %s value into session'):format( type( val ) ),
                2
            );
        end
        protected( self ).data[prop] = cval;
    end
end


function Proxy:init( data )
    protected( self ).data = data;
    return self;
end


return Proxy.exports;
