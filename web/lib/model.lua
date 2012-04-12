-- MODEL ------------------------
-- objects:
--   - track
--     - length - artist - path - id - mood
--   - selector
--     - station - name - criteria - mood - happy
--   - program
--     - station - start - stop - selector - items
--     - recurring -> weekly, daily, blank
--   - stations
--     - name - selector
---------------------------------

require "tokyocabinet"
oh = require "sabot/botlib"

module("tracks", package.seeall)

function tracks:init()
  trk = tokyocabinet.tdbnew()
  if not trk:open("tracks.tch", trk.OWRITER + trk.OCREAT) then
    ecode = trk:ecode() 
    print("database open error: " .. trk:errmsg(ecode))
  end
end

tracks:init() 

function tracks:add(art, ttl)
  pkey = trk:genuid()
  cols = { artist = art, title = ttl }
  if not trk:put(pkey, cols) then
    ecode = trk:ecode()
    print("Error adding track: " .. trk:errmsg(ecode))
  else
    print("Added track:" .. pkey .. ": " .. art.. "-" .. ttl )
    end
end

-- fix this stupidity. if you spell the query type wrong, you get nothing, no warnings either.
local q = tokyocabinet.tdbqrynew(trk)
local op = {
  -- string
  equal     = q.TDBQCSTREQ,
  inclusive = q.TDBQCSTRSTRINC,
  begins    = q.TDBQCSTRBW,
  ends      = q.TDBQCSTREW,
  all       = q.TDBQCSTRAND,
  one       = q.TDBQCSTROR,
  eqone     = q.TDBQCSTROREQ,
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

function tracks:searchtest()
  q = tokyocabinet.tdbqrynew(trk)

  q:addcond("artist", op.equal, "mordi")
  res = q:search()
  c = "tracks: "
  print (c, oh.dump(res))
  --for i = 1, #res do
    --c = c .. "<br>" .. trk:get(res[i])
  --end
  --return c
end

function tracks:search(query)
  q = tokyocabinet.tdbqrynew(trk)
  q:addcond("artist", op.phrase, query)
  res = q:search()
  return oh.dump(res)
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
  return oh.dump(accu)
end

function tracks:get(id)
  return trk:get(id)
end

function tracks:update(id, cols)
  p = tracks:get(id)
  for k,v in pairs(p) do
    cols[k] = v
  end
  trk:put(id, cols)
end

--print("TEST SEARCH:")
--print(tracks:searchtest())
--print(tracks:search("mordi"))
--print(tracks:search("world"))
print("TRACK DUMP:")
print(tracks:dump())


return tracks
