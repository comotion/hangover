#!/usr/bin/env lua
module("getracks",package.seeall)
--id3 = require "lamt.mpeg" -- ffi doesnt work
--id3 = require "lib.meta.id321" -- id3v2 cant get all tags
--id3 = require "lib.meta.id3" -- only id3v1, kinda sucky
--id3 = require "lib.meta.id3-lua" -- doesnt handle UTF16
--id3 = require "lamt.id3v1" -- fucken v1
--local id3v2 = require "lamt.id3v2"
-- lesson learned: libs suck!

package.path = package.path..";lib/?.lua;lib/?/?.lua"
local u = require "util"
local meta = require "metadata"
local tracks = require "tracks"
local md5 = require "md5"

local json = require "cjson"
local p = require "lamt.tagfrompath"
local types,info,edit = unpack(require "lamt.mpeg")
local BUFSIZE = 1048576

for path in io.lines() do 
  tag = {}
  local tag = meta.gettags(path)
  -- need to move the file to the proper place
  -- need to read the file to get the mdsum
  --tag.md5 = u.bintohex(md5.sum('abcdef'))
  -- should check if we have that hash
  print(u.dump(tag))
  --id = tracks:add{unpack(tag),unpack{tag.tags}}
end

