-- playlist
--- stores a list of tracks in order
--
--[[ track: 
{
	id       : "DMxCgbHM",
	name     : "For recreational use only",
	author   : "lafa",
	schedules: ["oslobass/NsaDU"],
	tracks   : [
		"1dcca23355272056f04fe8bf20edfce0",
		"26ab0db90d72e28ad0ba1e22ee510510",
		"31d30eea8d0968d6458e0ad0027c9f80"
	]
}
--]]


local db  = require "couch"
local u   = require "util"

module("playlist", package.seeall)
local database = "playlist"

function playlist:init()
  return db:init(database)
end

local pls = playlist:init()

function playlist:put(id,cols)
	db:put(pls, id, cols)
end

function playlist:add(cols)
	cols.added = os.time()
	cols.station = cols.station or default_station
   local id = cols.station..'/'..db:genuid()
	db:put(pls, id, cols)
end

function playlist:get(id)
	return db:get(pls, id)
end

function playlist:find(name)
	-- bah
   return db:generate_view(trk, { name = name })
end
