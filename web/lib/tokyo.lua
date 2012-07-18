-- goal is to abstract away db calls here

require "tokyocabinet"
require "os"
local u = require "lib/util"

module("tokyo", package.seeall)

function tokyo:init(name)
  local name = name or "db"
  local file = name .. ".tch"
  local db = tokyocabinet.tdbnew()

  if not db:open(file, db.OWRITER + db.OCREAT) then
    ecode = db:ecode() 
    print("database open error: " .. db:errmsg(ecode))
  end
  return db
end

db = tokyo:init()

-- fix this stupidity. if you spell the query type wrong,
-- you get no warnings, nothing.
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

return tokyo
