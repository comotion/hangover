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
-- search(track{key=val},sort,limit,paginate)
-- filter to return only specific fields
-- count total results (or pages)
-- TODO:
-- keyword search and tag:val search
-- station/selector/program storage

require "tokyocabinet"
require "os"
local u = require "lib/util"

module("tracks", package.seeall)

function tracks:init(file)
  local file = file or "tracks.tch"
  trk = tokyocabinet.tdbnew()
  if not trk:open(file, trk.OWRITER + trk.OCREAT) then
    ecode = trk:ecode() 
    print("database open error: " .. trk:errmsg(ecode))
  end
end

tracks:init() 
-- fix this stupidity. if you spell the query type wrong,
-- you get no warnings, nothing.
local q = tokyocabinet.tdbqrynew(trk)
local op = {
  -- string
  equal     = q.QCSTREQ,
  inclusive = q.QCSTRINC,
  begins    = q.QCSTRBW,
  ends      = q.QCSTREW,
  all       = q.QCSTRAND,
  one       = q.QCSTROR,   -- inclusive or
  eqone     = q.QCSTROREQ, -- equal or
  regex     = q.QCSTRRX,
  -- numeric
  eq        = q.QCNUMEQ,
  gt        = q.QCNUMGT,
  ge        = q.QCNUMGE,
  lt        = q.QCNUMLT,
  le        = q.QCNUMLE,
  tween     = q.QCNUMBT,
  numor     = q.QCNUMOREQ,
  -- fulltext
  phrase    = q.QCFTSPH,
  alltokens = q.QCFTSAND,
  onetoken  = q.QCFTSOR,
  compound  = q.QCFTSEX,
  -- flags
  negate    = q.QCNEGATE,
  noindex   = q.QCNOIDX,
}
local sort = {
  lexic     = q.QOSTRASC,
  reverse   = q.QOSTRDESC,
  increasing= q.QONUMASC,
  decreasing= q.QONUMDESC,
}

function tracks:put(pkey,cols)
  if not trk:put(pkey, cols) then
    ecode = trk:ecode()
    return nil,nil,trk:errmsg(ecode)
  else
    return pkey, cols
  end
end

-- tracks must have a name, can have table of other tags
-- (artist,track) pair is unique
-- returns: trackid,entry,error
function tracks:add(artist,title, cols) 
  local cols = cols or {}
  local res = tracks:search{artist = artist, title = title}
  for i,v in pairs(res) do
     return tracks:update(i,cols)
  end
  local pkey = trk:genuid()
  cols.title   = title
  cols.artist  = artist
  cols.added   = os.time()
  cols.station = cols.station or default_station
  return tracks:put(pkey, cols)
end

function tracks:ssearch(query, limit, page, qop, order)
  local query = query or {station=default_station}
  local qop = qop or op.equal
  q = tokyocabinet.tdbqrynew(trk)
  for k,v in pairs(query) do
    q:addcond(k, qop, v)
  end
  local size = #q:search() -- just to get size
  q:setorder(unpack(order))
  q:setlimit(limit, skip)
  return q:search(),math.floor(size/limit)+1
end

-- search within the database
-- you can specify limit and page number
-- returns array [id]={result}
function tracks:search(query, qf, limit, page, qop, order)
  local limit = limit or 25
  local page = page or 1
  local skip = (page-1)*limit
  local order = order or {"added", sort.decreasing}
  if type(order) ~= "table" then order = {"added", order} end
  if query == "" then query = {} end

  local result, pages
  if type(query) == "table" then
    result,pages = tracks:ssearch(query, limit, page, qop, order)
  else
    result,pages = tracks:gsearch(query, qf, limit, page, order)
  end
  return tracks.fill(result),pages
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
function tracks:gsearch(q, qf, limit, page, order)
  local queries = {}
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
        q:addcond(t,op.one,v)
      else
        q:addcond(t,op.inclusive,v)
      end
    end
    if #accu > 0 then
      print("adding condition: " .. u.join(accu))
      q:addcond(f,op.onetoken,u.join(accu))
    end
    table.insert(queries,q)
  end
  -- pull out last query and execute on it
  qry = table.remove(queries)
  qry:setorder(unpack(order))
  local pages = math.floor(#qry:metasearch(queries,qry.MSUNION)/limit)+1
  qry:setlimit(limit, skip)
  return qry:metasearch(queries,qry.MSUNION),pages
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
function tracks.filter(result, fields)
  local res = {}
  for k,v in pairs(result) do
    local one = {}
    for i,f in pairs(fields) do
      one[f] = v[f]
    end
    res[k] = one
  end
  return res
end

tracks:add("yo","mama", {foo="bar"})
tracks:add("world","musack", {foo="baz"})
u.out("fapfapfap", tracks:dump())
return tracks
