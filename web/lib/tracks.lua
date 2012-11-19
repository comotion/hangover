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
local db = require "lib/tokyo"
local u = require "lib/util"

module("tracks", package.seeall)

function tracks:init()
  return tokyo:init("tracks")
end

local trk  = tracks:init()

function tracks:put(pkey,cols)
  return tokyo.put(trk, pkey, cols)
end

-- can have table of tags
-- returns: trackid,entry,error
function tracks:add(cols) 
  local cols = cols or {}
  local pkey = trk:genuid()
  cols.added   = os.time()
  cols.station = cols.station or default_station
  print("adding ".. u.dump(cols))
  if cols.md5 then
    id = tracks:ssearch({md5=md5})
    if #id ~= 0 then
       print("found id "..u.dump(id))
       return id
    end
  end
  id = tracks:put(pkey, cols)
  print("the id added wasy: "..id)
  return id
end

-- the simple search
function tracks:ssearch(query, qop, order)
  local query = query or {station=default_station}
  local qop = qop or db.op.equal
  q = tokyocabinet.tdbqrynew(trk)
  for k,v in pairs(query) do
    q:addcond(k, qop, v)
  end
  if order then q:setorder(unpack(order)) end
  local res = q:search()
  -- q:setlimit(limit, skip) -- we need the size so there is no use
  return res, #res
end

-- search within the database
-- returns array [id]={result}
function tracks:search(query, qf, qop, order)
  local order = order or {"added", db.sort.decreasing}
  if type(order) ~= "table" then order = {order, db.sort.increasing} end
  if not query or query == "" then query = {} end

  local result, size
  if type(query) == "table" then
    result,size = tracks:ssearch(query, qop, order)
  else
    result,size = tracks:gsearch(query, qf, order)
  end
  return tracks.fill(result),size
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

-- search for query in all queryfields
-- honour queries like "foo bar tag:value"
-- todo: filter out results that don't match whole query
function tracks:gsearch(q, qf, order)
  local queries = {}
  q,qf = q or '', qf or ''
  local tokens = u.split(q,', ')
  local qf = u.split(qf)
  local qry

  -- collect terms
  local accu = {}
  local tags = {}
  for i,v in pairs(tokens) do
    t = u.split(v,':')
    if #t > 1 then
      tags[t[1]] = t[2]
    else
      table.insert(accu, v)
    end
  end

  -- create one search per field
  for j,f in pairs(qf) do
    local q = tokyocabinet.tdbqrynew(trk)
    for t,v in pairs(tags) do
      a = u.split(v,',')
      if #a > 1 then
        q:addcond(t,db.op.one,v)
      else
        q:addcond(t,db.op.inclusive,v)
      end
    end
    if #accu > 0 then
      print("search " .. f .. " for " .. u.join(accu))
      q:addcond(f,db.op.onetoken,u.join(accu))
    end
    table.insert(queries,q)
  end
  -- pull out last query and execute on it
  qry = table.remove(queries)
  qry:setorder(unpack(order))
  local result  = qry:metasearch(queries,qry.MSUNION)
  return result, #result
end
  
function tracks:dump()
  trk:iterinit()
  local key, value, accu
  accu = {}
  while true do
    key = trk:iternext()
    if not key then break end
    value = trk:get(key)
    table.insert(accu,value)
  end
  return u.dump(accu)
end

function tracks:get(pkey)
  local track = trk:get(pkey)
  track.id = pkey
  return track
end

function tracks:update(pkey, cols)
  p = tracks:get(pkey)
  for k,v in pairs(p) do
    cols[k] = v
  end
  cols.updated = os.time()
  return tracks:put(pkey,cols)
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

