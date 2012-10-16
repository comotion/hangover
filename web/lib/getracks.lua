#!/usr/bin/env lua
module("getracks",package.seeall)
--id3 = require "lamt.mpeg" -- ffi doesnt work
--id3 = require "lib.meta.id321" -- id3v2 cant get all tags
--id3 = require "lib.meta.id3" -- only id3v1, kinda sucky
--id3 = require "lib.meta.id3-lua" -- doesnt handle UTF16
--id3 = require "lamt.id3v1" -- fucken v1
--local id3v2 = require "lamt.id3v2"

package.path = package.path..";lib/?.lua;lib/?/?.lua"
local u = require "util"
local meta = require "metadata"
local tracks = require "tracks"
local md5 = require "md5"

local json = require "cjson"
local p = require "lamt.tagfrompath"
local types,info,edit = unpack(require "lamt.mpeg")

function getv2tags(path)
  --tag = id3.getV1(file) --or id4.getV2(file,"artist")
  --tag = id3.readID3(file)
  --tag = id3.readtags(file) -- id3-lua
  local file = assert(io.open(path, 'rb'))
  local off, header,get = id3v2.find(file)
  local tag
  if off then
     ok,tag = pcall(id3v2.read,get,header)
  end
  if not ok or not tag then
     -- fail
     return nil, "tag fail"
  else
    -- clean up tags, unpacking table{table} things
    for k,v in pairs(tag) do
       if type(v) == "table" then
          v = u.join(v)
          tag[k] = v
       end
    end
    tag.path = path
    --print(json.encode{path,tag})
    return tag
  end
end

function notag(path)
 -- Tag matching patterns
  -- Let tags be guessed by file paths
  -- Tags are surrounded by //
  -- //_// is a junk operator
  -- ? makes the preceding character optional
pat = {
  Basic = "//Artist// - //Title//" ;
  Daurn = "//Album Artist//, //Album// ?{?//Release//}? ?(?D?i?s?c? ?//Disc//)?/[//Track//] //Artist// - //Title//" ;
  Track = "//Artist// - //Album// - //_////Track//.? ?//Title//";
  TF    = "//Artist// - //Album// - //_////Track// -? ?//Title//";
  EAC = "//Artist// - //Album// (//Year//)//_/////Track// - //Title//" ;
}
  -- Default - must be the name of a pattern from above.
  -- fucks up with:
  -- ["Sonny Boy Williamson II - Nine Below Zero - The Blues Collection 10\/10 - Bring It On Home.mp3",{"artist":"Sonny Boy Williamson II - Nine Below Zero - The Blues Collection 10 - 10","title":"Bring It On Home"}]
  -- ["karifon\/04 Blodtørst.m4a",{"artist":"karifon","title":"04 Blodtørst"}]
  -- ["Sleep\/Sleep - 1995 - Jerusalem\/03 - Jerusalem (pt. 3).mp3",{"artist":"Sleep - Sleep - 1995 - Jerusalem - 03","title":"Jerusalem (pt. 3)"}]
  -- ["Melissa auf der Maur\/Out Of Our Minds 2010\/09 - Father's Grave.mp3",{"artist":"Melissa auf der Maur - Out Of Our Minds 2010 - 09","title":"Father's Grave"}]

  local info
  if not info then info = p.info(path,pat.Basic) end
  -- could run track match if /(%d+) ?

  if not info then info = p.info(path,pat.Track) end
  --print(json.encode{path,info})
  return info
end

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

