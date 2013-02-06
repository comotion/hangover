-- access model through tyrant
--
-- interface to the database
-- get(table, id), set(table, id, cols), add(table, cols)
-- search(table, query, fields, order)
-- only one database, but many "models" or object types

package.path = package.path..";lib/?.lua;lib/?/?.lua"
require "os"
local tyr = require "tokyotyrant"
local u = require "util"

module("tyrant", package.seeall)

local db = nil
local tbl = nil

-- create table mapping to magic constants
local op = {
  -- string
  equal     = "STREQ",
  inclusive = "STRINC",
  begins    = "STRBW",
  ends      = "STREW",
  all       = "STRAND",
  one       = "STROR",   -- inclusive or
  eqone     = "STROREQ", -- equal or
  regex     = "STRRX",
  -- numeric
  eq        = "NUMEQ",
  gt        = "NUMGT",
  ge        = "NUMGE",
  lt        = "NUMLT",
  le        = "NUMLE",
  tween     = "NUMBT",
  numor     = "NUMOREQ",
  -- fulltext
  phrase    = "FTSPH",
  alltokens = "FTSAND",
  onetoken  = "FTSOR",
  compound  = "FTSEX",
  -- flags
  negate    = "NEGATE",
  noindex   = "NOIDX",
}

tyrant.sort = {
  lexic     = "STRASC",
  reverse   = "STRDESC",
  increasing= "NUMASC",
  decreasing= "NUMDESC",
}

function tyrant:init(name)
  if db == nil then
    tbl = tyr.tbldb.new()
    db = tyr.rdb.new()
    tbl:open()
    db:open()
  end
  -- XXX pass "handle" back to client
  return db,tbl
end

-- create an entry
function tyrant:add(name, cols)
  cols._type = name
  cols.added = cols.added or os.time()
  local id = tbl:genuid()
  print("ADDING!"..u.dump(cols))
  return tbl:put(id, cols)
end

-- find entries of given _type=name
function tyrant:search(name, query, qop, order)
  local q = tyr.query.new()
  q:addcond('_type', op.equal, name)
  for k,v in pairs(query) do
    q:addcond(k, qop, v)
  end
  if order then q:setorder(unpack(order)) end
  return tbl:search(q)
end

-- the simple search. pass us a table of queries
function tyrant:ssearch(name, query, qop, order)
  local query = query or {_type = name, station=default_station}
  local qop = qop or op.equal
  print("qop is ".. u.dump(qop))
  -- q:setlimit(limit, skip) -- we need the size so there is no use
  local res = tyrant:search(name, query, qop, order)
  return res, #res
end


function tyrant:get(name ,id)
  local thing = db:get(id)
  if id._type == name then
    return thing
  end
  return nil
end

function tyrant:put(name, id, cols)
  cols._type = name
  db:put(id, cols)
end


db,tbl = tyrant:init()
print(u.dump(tbl:size()))
id = tbl:genuid()
u.out(id)
print(u.dump(tbl:put(id, {a="b",c="d"})))
print('aha')
print(u.dump(tbl:get(id)))
print("aargh")
u.out(tbl)
q = tyr.query.new()
keys = tbl:search(q)
for k=1,#keys do
   v = keys[k]
   thing = tbl:get(v)
   print(v .. ' -> ' .. u.dump(thing)) 
end

function tyrant:dump(name)
--iterate over the whole db, or _type = name
end

-- search for query in all queryfields
-- honour queries like "foo bar tag:value"
-- todo: filter out results that don't match whole query
function tyrant:gsearch(q, qf, order)
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


return tyrant
