local Session = require('session');
local Cache = require('cache.inmem');
local c = ifNil( Cache.new() );
local s;

-- cfg must be table
ifNotNil( Session.new() );
ifNotNil( Session.new(1) );
-- cfg.store must implements get, set and delete method
ifNotNil( Session.new({
    store = {}
}));
ifNil( Session.new({
    store = c
}));

-- ttl must be uint: default 0
ifNotNil( Session.new({
    store = c,
    ttl = ''
}));
ifNotNil( Session.new({
    store = c,
    ttl = function()end
}));
ifNil( Session.new({
    store = c,
    ttl = 0
}));

-- idgen must be function and that must return non-empty string value
-- default blake2b
ifNotNil( Session.new({
    store = c,
    idgen = ''
}));
ifNotNil( Session.new({
    store = c,
    idgen = 1
}));
ifNotNil( Session.new({
    store = c,
    idgen = function()end
}));
ifNotNil( Session.new({
    store = c,
    idgen = function()
        return math.random()
    end
}));
ifNotNil( Session.new({
    store = c,
    idgen = function()
        return '';
    end
}));
ifNil( Session.new({
    store = c,
    idgen = function()
        return tostring( math.random() )
    end
}));

-- cookie.name must be non-empty string: default 'sid'
ifNotNil( Session.new({
    store = c,
    cookie = {
        name = 1
    }
}));
ifNotNil( Session.new({
    store = c,
    cookie = {
        name = ''
    }
}));
ifNil( Session.new({
    store = c,
    cookie = {
        name = 'sid'
    }
}));

-- other cookie attributes: 
-- domain, path expires, secure and httpOnly fields are tested by test code of 
-- lua-cookie module
