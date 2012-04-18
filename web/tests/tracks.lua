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
print("searching all")
u.out(tracks:search())
do return end

print("search for mordi:")
for k,v in pairs(tracks:search({track="mordi"})) do
   u.out(tracks:get(v))
end
print("search for world:")
for k,v in pairs(tracks:search({track="world"})) do
   u.out(tracks:get(v))
end
print("searching for artist world:")
for k,v in pairs(tracks:search({artist="world"})) do
   u.out(tracks:get(v))
end
print("searching all")
for k,v in pairs(tracks:search()) do
   u.out(tracks:get(v))
end
print("TRACK DUMP:")
print(tracks:dump())

