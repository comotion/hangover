module("metadata",package.seeall)
local types,info,edit = unpack(require ("lamt.mpeg"))
-- XXX: need vstruct for ogg stuff!
-- https://github.com/ToxicFrog/vstruct.git
--local otypes, oinfo, oedit = unpack(require("lamt.ogg"))

local u = require "util"

function pathstuff(path)
  local tag = {}
  local spa = u.split(path, '/')
  spa = spa[#spa] -- drop path stuff
  spa = u.split(spa, '.')
  tag.extension = spa[#spa]
  tag.filename = spa[1]
  -- initial title from path.. overwritten by tags
  tag.title = tag.filename:gsub('_', ' ')
  tag.path = path
  return tag
end

function gettags(path)
  local initial = pathstuff(path)
  local ok, intel, err = pcall(info, {path=path})
  if not ok or not intel then 
    errcode = intel or err
    return nil, errcode, path
  end

  -- clean up tags, unpacking table{table} things
  tag = {}
  if not intel.tags then intel.tags = {} end
  for k,v in pairs(intel.tags) do
    if type(v) == "table" then
      v = u.join(v)
      tag[k] = v
    end
  end
  -- merge in initial stuff
  for k,v in pairs(initial) do
    if not tag[k] then
      tag[k] = v
    end
  end
  intel.tags = tag
  -- flatten out tags and extras
  return u.flatten(intel)
end

return _M
