lua-session
=========

session module.

---

## Dependencies

- blake2: https://github.com/mah0x211/lua-blake2
- cookie: https://github.com/mah0x211/lua-cookie
- halo: https://github.com/mah0x211/lua-halo
- process: https://github.com/mah0x211/lua-process
- util: https://github.com/mah0x211/lua-util


## Installation

```sh
luarocks install session --from=http://mah0x211.github.io/rocks/
```


## Session Object

### Create session object

#### sess, err = Sessoin.new( config:table )


```lua
local Cache = require('cache.inmem'); -- in-memory cache module
local Session = require('session');
local sess, err = Session.new({
    store = Cache.new(),
});
```

**Parameters**

- `store`: table - session strore.
- `ttl`: uint - cookie expiration seconds. `default: 0` that `no expires`.
- `idgen`: function - session-id generator function. `default: blake2b`.  
  e.g. `function() return math.random() end`

- `cookie`: table - cookie configuration.
    - `name`: string - name of session and cookie: `default 'sid'`.
    - `path`: string - effective path. default `'/'`.
    - `httpOnly`: boolean - http only flag. `default true`.
    - `secure`: boolean - secure flag. `default false`.

**Returns**

1. `sess`: table - session object.
2. `err`: string - error string. 

---

### About the session store.

the session store must implement the following methods.

#### data, err = store:get( key:string )

getting the data associated with specified key.

**Parameters**

- `key`: string - this parameter should support the session-id string.

**Returns**

1. `data`: table.
2. `err`: string - error string. 


#### ok, err = store:set( key:string, data:table, ttl:uint )

setting the data with specified key.

**Parameters**

- `key`: string - this parameter should support the session-id string.
- `data`: table.
- `ttl`: uint - expiration seconds from current time. no expiration if `0`.

**Returns**

1. `ok`: boolean - true on success, or false on failure.
2. `err`: string - error string. 


#### ok, err = store:delete( key:string )

deleting the data associated with specified key.

**Parameters**

- `key`: string - this parameter should support the session-id string.

**Returns**

1. `ok`: boolean - true on success, or false on failure.
2. `err`: string - error string. 


### Customizing session id.

e.g. use `UUID` value to session id.

```lua
local uuid = require('ossp-uuid');
local Cache = require('cache.inmem'); -- in-memory cache module
local Session = require('session');
local sess, err = Session.new({
    store = Cache.new(),
    idgen = function() return uuid.generate( uuid.str, uuid.v4 ); end
});
```

---


### Create session item

#### item, err = sess:create()

create the session item.

```lua
local item, err = sess:create();
```

**Returns**

1. `item`: table - session item.
2. `err`: string - error string.


### Fetching the session item

#### item, err = sess:fetch( sid:string )

fetching the session item object associated with specified key.

```lua
local item, err = sess:fetch('sid');
```

**Parameters**

1. `sid`: string - session id.


**Returns**

1. `item`: table - session item.
2. `err`: string - error string.


## Session Item

### Accessing the session item data

#### tbl = item:proxy()

getting the proxy table of session item for accessing the data.

```lua
local tbl = item:proxy();

tbl.strfield = 'myfield data';
print( tbl.strfield ); -- 'myfield data'

tbl.numfield = 10;
print( tbl.numfield ); -- 10
```

**Returns**

1. `tbl`: table.


**Proxy table limitation.**

- field name must be `string`.
- field value must be `nil`, `string` or `finite number`.


### Save and Destroy

#### cookie, err = item:save( [genCookie:boolean] )

save item to the session store and return a cookie or session-id.

```lua
local cookie, err = item:save();
print( cookie );
```

**Parameters**

1. `genCookie`: boolean - generate cookie. `default: true`.

**Returns**

1. `sid`: string - cookie value, or a session-id if a genCookie argument is false.
2. `err`: string - error string.


#### cookie, err = item:destroy( [genCookie:boolean] )

destroy item from the session store and return a cookie or session-id.

```lua
local cookie, err = item:destroy();
print(  cookie );
```

**Parameters**

1. `genCookie`: boolean - generate cookie. `default: true`.


**Returns**

1. `sid`: string - cookie value, or a session-id if a genCookie argument is false.
2. `err`: string - error string.


