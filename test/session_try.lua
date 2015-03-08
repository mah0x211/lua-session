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

-- field-name: string
-- field-value: string or finite number or nil
ifTrue(isolate(function()
    proxy[nil] = nil;
end));
ifTrue(isolate(function()
    proxy[1] = nil;
end));
ifTrue(isolate(function()
    proxy[function()end] = nil;
end));
ifTrue(isolate(function()
    proxy[coroutine.create(function()end)] = nil;
end));
ifTrue(isolate(function()
    proxy[{}] = nil;
end));
ifTrue(isolate(function()
    proxy['field'] = function()end;
end));
ifTrue(isolate(function()
    proxy['field'] = coroutine.create(function()end);
end));
ifNotTrue(isolate(function()
    proxy['field'] = { a = 'b' };
end));
ifNotTrue(isolate(function()
    proxy['field'] = 0/0;
end));
ifNotTrue(isolate(function()
    proxy['field'] = 1/0;
end));
ifNotTrue(isolate(function()
    proxy['field'] = nil;
end));
ifNotTrue(isolate(function()
    proxy['numval'] = math.random();
end));
ifNotTrue(isolate(function()
    proxy['hello'] = 'world';
end));

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

-- save item and gen cookie
cookie = ifNil( item:save() );
-- extract session id
sid = cookie:match('sid=([^; ]+)');
-- fetch item 
savedItem = ifNil( s:fetch( sid ) );
-- destroy feched item
cookie = ifNil( savedItem:destroy() );
-- session value must be empty
ifNotNil( cookie:match('sid=([^; ]+)') );

