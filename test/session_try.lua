local Session = require('session');
local Cache = require('cache.inmem');
local ttl = 2;
local c = ifNil( Cache.new() );
local s = ifNil( Session.new({
    store = c,
    ttl = ttl
}));
local item, proxy, cookie, sid, savedItem, savedItemProxy;

-- create session item
item = ifNil( s:create() );
-- create data proxy
proxy = ifNil( item:proxy() );
-- set data
proxy.numval = math.random();
proxy.hello = 'world';
-- save item and gen cookie
cookie = ifNil( item:save() );

-- extract session id
sid = cookie:match('sid=([^; ]+)');

-- fetch item 
savedItem = ifNil( s:fetch( sid ) );
savedItemProxy = ifNil( savedItem:proxy() );

-- compare
ifNotEqual( proxy.numval, savedItemProxy.numval );
ifNotEqual( proxy.hello, savedItemProxy.hello );

-- fetch item after ttl seconds
sleep( ttl + 1 );
ifNotNil( s:fetch( sid ) );

