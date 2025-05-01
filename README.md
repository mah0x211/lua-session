lua-session
=========

session module.


## Installation

```sh
luarocks install session
```

---

## m = session.new( cfg )

create a new session manager object.  
if invalid configuration is specified, it will throw an error.

**Parameters**

- `store:any`: session store that use with [lua-cache](https://github.com/mah0x211/lua-cache) module (default `nil`). please refer to the lua-cache module documentation for more information.
- `cookie:session.cookie.config`: cookie configuration that can specify the following fields;
    - `name:string`: cookie name (default `sid`).
    - `path:string`: path (default `/`).
    - `secure:boolean`: secure flag. (default `true`)
    - `httponly:boolean`: http-only flag. (default `true`)
    - `samesite:string`: same-site flag. (default `Lax`)
    - `maxage:integer`: max-age seconds. (default `1800`)
- `idgen:function`: session id generator function. (default `session.idgen`)


**Returns**

- `m:session.Manager`: a session manager object.


**Example**

```lua
local session = require('session')
local m = session.new()
print(m) -- session.Manager: 0x6000030de700
```

# session.Manager

the following methods are available in the `session.Manager` object.

## cookie = Manager:bake_cookie( sid )

bake the session cookie with specified session id.

**Parameters**

- `sid:string`: session id.

**Returns**

- `cookie:string`: cookie string that can be set to the `Set-Cookie` header.


## cookie = Manager:bake_void_cookie()

bake the void session cookie that cookie value is specified to `'void'`.  
this cookie can be used to delete the session cookie.

**Returns**

- `cookie:string`: cookie string that can be set to the `Set-Cookie` header.


## s = Manager:create()

create a new session object.

**Returns**

- `s:session.Session`: a session object.

**Example**

```lua
local session = require('session')
local m = session.new()
local s = m:create()
print(s) -- session.Session: 0x6000030de700
```


## ok, err, timeout = Manager:save( sid, data )

save the session data with specified session id.

**Parameters**

- `sid:string`: session id.
- `data:table`: session data.

**Returns**

- `ok:boolean`: `true` on success, or `false` on failure.
- `err:any`: an error message.
- `timeout:boolean`: `true` if the data saving operation timed out.


## ok, err, timeout = Manager:fetch( sid )

fetch the session data associated with specified session id.

**Parameters**

- `sid:string`: session id.

**Returns**

- `ok:boolean`: `true` on success, or `false` on failure.
- `err:any`: an error message.
- `timeout:boolean`: `true` if the data retrieval operation timed out.


## newsid, err, timeout = Manager:rename( sid )

rename the session id and return the new session id.

**Parameters**

- `sid:string`: session id.

**Returns**

- `newsid:string`: new session id.
- `err:any`: an error message.
- `timeout:boolean`: `true` if the data renaming operation timed out.


## ok, err, timeout = Manager:destroy( sid )

destroy the session data associated with specified session id.

**Parameters**

- `sid:string`: session id.

**Returns**

- `ok:boolean`: `true` on success, or `false` on failure.
- `err:any`: an error message.
- `timeout:boolean`: `true` if the data deletion operation timed out.


## n, err, timeout = Manager:evict( [n [, ...]] )

evict the session data that expired.

**Parameters**

- `n:uint`: the number of session data to evict. (default `-1` that means all session data)
- `...:any`: additional arguments that passed to the session store.

**Returns**

- `n:uint`: the number of session data that evicted.
- `err:any`: an error message.
- `timeout:boolean`: `true` if the data eviction operation timed out.


# session.Session

the following methods are available in the `session.Session` object.


## sid = Session:getid()

get the session id.

**Returns**

- `sid:string`: session id.


## ok, err, timeout = Session:set( key, val )

set the session data with specified key if the key is already exists, it will be overwritten. also, if the `val` is `nil`, the key will be removed.

**NOTE:** the session data is not saved to the session store until the `Session:save()` method is called.

**Parameters**

- `key:string`: key.
- `val:any`: value that must be a `nil`, `string`, `number` or `table` value. a `table` value will be copied.

**Returns**

- `ok:boolean`: `true` on success, or `false` on failure.
- `err:any`: an error message.


## val = Session:get( key )

get the session data associated with specified key.

**Parameters**

- `key:string`: key.

**Returns**

- `val:any`: value.


## vals = Session:getall()

get all session data.

**Returns**

- `vals:table`: a table that contains all session data.


## val = Session:get_copy( key )

get the copied session data associated with specified key.

**Parameters**

- `key:string`: key.

**Returns**

- `val:any`: copied value.


## vals = Session:getall_copy()

get the all copied session data.

**Returns**

- `vals:table`: a table that contains all copied session data.


## val = Session:delete( key )

delete the session data associated with specified key.

**NOTE:** the session data is not removed from the session store until the `Session:save()` method is called.

**Parameters**

- `key:string`: key.

**Returns**

- `val:any`: value that was removed.


## ok, err = Session:set_flash( key, val )

set the flash data with specified key. if the key is already exists, it will be overwritten.  
flash data is removed from the session after being retrieved by `get_flash()` or `getall_flash()`.

**Parameters**

- `key:string`: key.
- `val:any`: value that must be a `nil`, `string`, `number` or `table` value. a `table` value will be copied.

**Returns**

- `ok:boolean`: `true` on success, or `false` on failure.
- `err:any`: an error message.


## val = Session:get_flash( key )

get the flash data associated with specified key.  
the retrieved data will be removed from the session.

**Parameters**

- `key:string`: key.

**Returns**

- `val:any`: value.


## vals = Session:getall_flash()

get all flash data and remove them from the session.

**Returns**

- `vals:table`: a table that contains all flash data.


## cookie, err, timeout = Session:save()

save the session data to the session store and return the session cookie.

**Returns**

- `cookie:string`: session cookie.
- `err:any`: an error message.
- `timeout:boolean`: `true` if the data saving operation timed out.


## cookie, err, timeout = Session:rename()

rename the session id and return the new session cookie that includes the new session id.

**Returns**

- `cookie:string`: session cookie.
- `err:any`: an error message.
- `timeout:boolean`: `true` if the data renaming operation timed out.


## cookie, err, timeout = Session:destroy()

destroy the session data from the session store and return the session cookie that can be used to delete the session cookie.




---

# Usage

```lua
local dump = require('dump')

-- create new session manager with default configuration.
local session = require('session')
local m = session.new()
print(m) -- session.Manager: 0x6000002f5000

-- create new session object from the store.
local s = m:create()
print(s) -- session.Session: 0x6000002f5480

-- set session data.
s:set('foo', {
    bar = {
        baz = 'qux',
    },
})

-- get session data.
local data = s:get('foo')
print(dump(data)) -- { bar = { baz = 'qux' } }

-- save the session data into the store.
local cookie, err, timeout = s:save()
print(dump({
    cookie = cookie,
    err = err,
    timeout = timeout,
})) -- { cookie = "sid=01JE5J36QE_lGa543; Expires=Tue, 03 Dec 2024 06:37:35 GMT; Max-Age=1800; Path=/; SameSite=Lax; Secure; HttpOnly" }

-- fetch the session data from the store.
local sid = s:getid()
s = m:fetch(sid)
print(s) -- session.Session: 0x600000c5c3c0
data = s:get('foo')
print(dump(data)) -- { bar = { baz = 'qux' } }

-- rename the session id.
cookie, err, timeout = s:rename()
local newsid = s:getid()
print(dump({
    newsid = s:getid(),
    cookie = cookie,
    err = err,
    timeout = timeout,
})) -- { newsid = "01JE5J9CW7_yuEmS1", cookie = "sid=01JE5J9CW7_yuEmS1; Expires=Tue, 03 Dec 2024 06:40:58 GMT; Max-Age=1800; Path=/; SameSite=Lax; Secure; HttpOnly" }

-- cannot fetch the session data from the store with the old session id.
s = m:fetch(sid)
print(s) -- nil

-- fetch the session data from the store with the new session id.
s = m:fetch(newsid)
print(s) -- session.Session: 0x600000c5c3c0
data = s:get('foo')
print(dump(data)) -- { bar = { baz = 'qux' } }

-- destroy the session data from the store.
cookie, err, timeout = s:destroy()
print(dump({
    cookie = cookie,
    err = err,
    timeout = timeout,
})) -- { cookie = "sid=void; Expires=Tue, 03 Dec 2024 05:43:17 GMT; Max-Age=-1800; Path=/; SameSite=Lax; Secure; HttpOnly" }

-- cannot fetch the destroyed session data from the store.
s = m:fetch(newsid)
print(s) -- nil
```



