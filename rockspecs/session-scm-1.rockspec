package = "session"
version = "scm-1"
source = {
    url = "git://github.com/mah0x211/lua-session.git",
}
description = {
    summary = "session module.",
    homepage = "https://github.com/mah0x211/lua-session",
    license = "MIT/X11",
    maintainer = "Masatoshi Teruya",
}
dependencies = {
    "lua >= 5.1",
    "lauxhlib >= 0.6.1",
}
build = {
    type = "builtin",
    modules = {
        ["session.base32"] = "lib/base32.lua",
    },
}

