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
local function sandbox( k, v )
    local co = coroutine.create(function()
        proxy[k] = v;
        return true;
    end);
    return coroutine.resume( co );
end
-- field-name: string
-- field-value: string or finite number or nil
ifTrue( sandbox() );
ifTrue( sandbox( 1, nil ) );
ifTrue( sandbox( 'field', function()end ) );
ifTrue( sandbox( 'field', 0/0 ) );
ifTrue( sandbox( 'field', 1/0 ) );
ifNotTrue( sandbox( 'field', nil ) );
ifNotTrue( sandbox( 'numval', math.random() ) );
ifNotTrue( sandbox( 'hello', 'world' ) );

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

