-- goal is to abstract away db calls here
--
-- foo:init
-- foo:put* key, val)
-- foo:get(key)
-- 

require "tokyocabinet"
require "os"
local u = require "lib/util"

module("tokyo", package.seeall)

function tokyo:init(name)
  local file = name .. ".tct"
-- fix this stupidity. if you spell the query type wrong,
-- you get no warnings, nothing.

  -- the global database, get at it by passing nothing
  if not db and not tokyo.op then
    tokyo.db = tokyo_booter()
  end
  if not name then
    return tokyo.db
  end

  -- here if you just want a database
  local db = tokyocabinet.tdbnew()
  if not db:open(file, db.OWRITER + db.OCREAT) then
    ecode = db:ecode() 
    print("database open error: " .. db:errmsg(ecode))
  end
  print("opened db:"..file)
  return db
end

function tokyo:put(db, pkey, cols)
  if not db:put(pkey, cols) then
    ecode = db:ecode()
    return nil,nil,db:errmsg(ecode)
  else
    return pkey, cols
  end
end

function tokyo:search(db, query, qop, order)
  local q = tokyocabinet.tdbqrynew(db)
  for k,v in pairs(query) do
    q:addcond(k, qop, v)
  end
  if order then q:setorder(unpack(order)) end
  return q:search()
end

-- create table mapping to magic constants
-- run only once plz
function tokyo_booter()
  local db = tokyocabinet.tdbnew()
  local q = tokyocabinet.tdbqrynew(db)
  tokyo.op = {
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
  tokyo.sort = {
    lexic     = q.QOSTRASC,
    reverse   = q.QOSTRDESC,
    increasing= q.QONUMASC,
    decreasing= q.QONUMDESC,
  }
  return db
end

function tokyo:dump()
  trk:iterinit()
  local key, value, accu
  accu = {}
  while true do
    key = trk:iternext()
    if not key then break end
    value = trk:get(key)
    table.insert(accu,value)
  end
  return accu
end


return tokyo
