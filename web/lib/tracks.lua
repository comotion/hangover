-- MODEL ------------------------
-- objects:
--   - track
--     - stations, length - artist - title - path
--     - id - mood - played list, playcount
--   - playlist
--     - sequential list of tracks to play
--   - selector
--     - station - name - criteria - mood - happy
--   - program
--     - station - start - stop - selector - items
--     - recurring -> weekly, daily, blank
--   - stations
--     - name - selector
---------------------------------
-- Goals:
-- unique add(artist,track,{key=val})
-- search(track{key=val},sort) : paginate
-- filter to return only specific fields
-- count total results (or pages)

require "os"
local db = require "couch"
local u = require "lib/util"

module("tracks", package.seeall)
local database = "tracks"

function tracks:init()
  local base = db:init(database)
  db:put_views(base)
  return base
end

-- local instance of the db connection saves us an init call
local trk  = tracks:init()

function tracks:put(pkey,cols)
  return db:put(trk, pkey, cols)
end
-- can have table of tags
-- returns: trackid,entry,error
function tracks:add(cols) 
  local cols = cols or {}
  local pkey = db:genuid()
  cols.added   = os.time()
  cols.station = cols.station or default_station
  print("adding ".. u.dump(cols))
  if cols.md5 then
    local id = db:search(trk, {md5=cols.md5})
    if #id ~= 0 then
       print("found id "..u.dump(id))
       return id
    end
  end
  return db:put(trk, id, cols)
end


-- search within the database
-- returns array [id]={result}
function tracks:search(query, qf, qop, order)
end

function tracks.fields(result)
  local fset = {}
  for _,t in ipairs(result) do
    for k,v in pairs(t) do
      fset[k] = true
    end
  end
  local rset = {}
  for k,v in pairs(fset) do
    table.insert(rset,k)
  end
  return rset
end


-- take an array of id's and return a set of result tracks
function tracks.fill(result)
  local rset = {}
  for i,v in ipairs(result) do
    rawset(rset,tonumber(v),tracks:get(v))
  end
  return rset
end 
  
function tracks:dump()
  return u.dump(db:dump())
end

function tracks:get(pkey)
  local track = db:get(pkey)
  track.id = pkey
  return track
end

function tracks:update(pkey, cols)
  p = tracks:get(pkey)
  -- merge teh data
  for k,v in pairs(cols) do
    p[k] = v
  end
  cols.updated = os.time()
  return tracks:put(pkey, p)
end

-- return result with only fields
-- you can specify limit and page number
function tracks.filter(result, fields, limit, skip)
  local res = {}
  local c = 0
  for k,v in pairs(result) do
    c = c + 1
    if(c > skip+limit) then
      break
    end
    if(c > skip) then
      if not fields or #fields == 0 then
        one = v -- no fields, so all fields
      else
        local one = {}
        for i,f in pairs(fields) do
          one[f] = v[f] -- just these fields
        end
      end
      res[k] = one
    end
  end
  return res
end
u.out("fapfapfap")
u.out(tracks:dump())
return tracks

