#!/usr/bin/lua
require "lib/model"
local u = require "lib/util"
print("init:")
tracks:init("test.tch")
print("add:")
u.out(tracks:add("world", "mordi", {length=42, foo="bar"}))
u.out(tracks:add("world", "lftr",{artist="lftr", genre="moody"}))
--for k,v in ipairs(cols) do
  --print("  " .. k .. " => " .. v)
--end
print("TEST SEARCH:")
print("search for mordi:")
u.out(tracks:search({track="mordi"}))
print("search for world:")
u.out(tracks:search({track="world"}))
print("searching for artist world:")
u.out(tracks:search({artist="world"}))
print("searching all")
u.out(tracks:search())
print("TRACK DUMP:")
print(tracks:dump())

