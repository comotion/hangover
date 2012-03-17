
-- MODEL ------------------------
--
-- objects:
--   - track
--     - length
--     - artist
--     - path
--     - id
--     - mood
--     - ...
--   - selector
--     - station
--     - name
--     - criteria
--       - mood
--         - happy
--   - program
--     - station
--     - recourring -> weekly, daily, blank
--     - start
--     - stop
--     - selector
--     - items
--   
--   - stations
--     - name
--     - selector
---------------------------------

require "tokyocabinet"

module("tracks", package.seeall)

function tracks:init()
  trk = tokyocabinet.tdbnew()
  if not trk:open("tracks.tch", trk.OWRITER + trk.OCREAT) then
    ecode = trk:ecode() 
    print("database open error: " .. trk:errmsg(ecode))
  end
end

tracks:init() 

function tracks:add()
  pkey = trk:genuid()
  cols = { artist = "mordi", title = "dance music" }
  if not trk:put(pkey, cols) then
    ecode = trk:ecode()
    print("Error adding track: " .. trk:errmsg(ecode))
  else
    print("Added track:" .. pkey)
  end
end

function tracks:searchtest()
  q = tokyocabinet.tdbqrynew(trk)
  --`op' specifies an operation type: 
  --`TDBQCSTREQ' for string which is equal to the expression, 
  --`TDBQCSTRINC' for string which is included in the expression, 
  --`TDBQCSTRBW' for string which begins with the expression, 
  --`TDBQCSTREW' for string which ends with the expression, 
  --`TDBQCSTRAND' for string which includes all tokens in the expression, 
  --`TDBQCSTROR' for string which includes at least one token in the expression, 
  --`TDBQCSTROREQ' for string which is equal to at least one token in the expression, 
  --`TDBQCSTRRX' for string which matches regular expressions of the expression, 
  --`TDBQCNUMEQ' for number which is equal to the expression, 
  --`TDBQCNUMGT' for number which is greater than the expression, 
  --`TDBQCNUMGE' for number which is greater than or equal to the expression, 
  --`TDBQCNUMLT' for number which is less than the expression, 
  --`TDBQCNUMLE' for number which is less than or equal to the expression, 
  --`TDBQCNUMBT' for number which is between two tokens of the expression, 
  --`TDBQCNUMOREQ' for number which is equal to at least one token in the expression, 
  --`TDBQCFTSPH' for full-text search with the phrase of the expression, 
  --`TDBQCFTSAND' for full-text search with all tokens in the expression, 
  --`TDBQCFTSOR' for full-text search with at least one token in the expression, 
  --`TDBQCFTSEX' for full-text search with the compound expression. 
  -- All operations can be flagged by bitwise-or: `TDBQCNEGATE' for negation, `TDBQCNOIDX' for using no index.

  q:addcond("artist", q.QSCTRINC, "mordi")
  res = q:search()
  for i = 1, #res do
    c = trk:get(res[i])
  end
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

print(tracks:searchtest())


