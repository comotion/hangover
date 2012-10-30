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
local crypto = require "crypto"

local json = require "cjson"
local p = require "lamt.tagfrompath"
local types,info,edit = unpack(require "lamt.mpeg")
local BUFSIZE = 1048576

for path in io.lines() do 
  tag = {}
  local initial = meta.pathstuff(path)
  tag = meta.gettags(path, initial)
  -- read the file to get the mdsum
  md5 = crypto.digest.new("md5")
  fd = io.open(path)
  local block = fd:read(BUFSIZE)
  while block do
    md5:update(block)
    block = fd:read(BUFSIZE)
  end
  tag.md5 = md5:final()
  -- check if we have that hash
  print(u.dump(tag))
  --id = tracks:add(tag)
  -- move the file to the proper place
  -- symlink to canonical name? (for ease)
end

