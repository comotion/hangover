-- playlist
--- stores a list of tracks in order
local db  = require "lib.tokyo"
local u   = require "lib.util"

module(..., package.seeall)

function playlist:init()
  return tokyo:init("playlists")
end
pls = playlist:init()

function playlist:put(pkey,cols)

