-- abstract some couch shit

--[[
couchdb has views for queries.
want to look up some word for all fields



get all values for a key: ( not really cool, uses loadsa disk)
map: function(doc) { for (prop in doc) { emit([prop, doc[prop] ], null); } }

query by:
startkey=["property", 0]&endkey=["property", {}]

madness:
http://wiki.apache.org/couchdb/FullTextIndexWithView?action=show
http://lethain.com/full-text-search-in-couchdb-using-couchdb/
http://sitr.us/2009/06/30/database-queries-the-couchdb-way.html

--]]



require "luchia"
module("couch", package.seeall)

local u = require "util"
local default_server = { host = "localhost", port = 5984, protocol = "http" }
local db
local doc
local srv = luchia.core.server:new(server)

-- return a new doc handle for database, creating if need be
function couch:init(database, server) 
   server = server or default_server
   db = luchia.database:new(server)
   local info = db:info(database)
   if not info then
      local resp = db:create(database)
      if not db:response_ok(resp) then
         error("failed to create database ".. database .. " on "..server.host..":"..server.port)
      end
   end
   doc = luchia.document:new(database, server)
   return doc
end

-- put up view scaffolding
-- FIXME: add moar views.
function couch:put_views(database)
  local views = {
     _id = "_design/search",
     language = "javascript",
     views = {
        all = {
           map= "function(doc) { emit(null, doc) }"
        },
        allkeys = {
           map = "function(doc) { for (var thing in doc) { emit(thing,1); } }",
           reduce = "function(key,values) { return sum(values); }"
        },
        md5 = {
           map = "function(doc) { if(doc.md5) { emit(doc.md5, null) } }"
        }
     }
  }
  return database:create(views, views._id)
end

function couch:genuid()
   local uuid = srv:uuids(1)[1]
   -- check if uuid is in use, to be sure
   while pcall(doc.info,doc,uuid) do
      uuid = db:uuids(1)[1]
   end
   -- XXX very unlikely but uuid might collide after we checked
   return uuid
end

-- put an object. existing couch docs have revisions
function couch:put(doc, id, cols)
   local rev = cols.rev
   local resp
   if not rev then
      resp = doc:create(cols, id)
      if doc:response_ok(resp) then
         cols.rev = doc:current_revision(id)
      end
   else
      resp = doc:update(cols, id, rev)
   end
   if not doc:response_ok(resp) then
      return nil, nil, resp.error .. ": "..resp.reason
   end
   return id, cols
end

function couch:dump()
   local resp = doc:retrieve("_all_docs?include_docs=true")

end

function lookup(doc, view, k, v)
   local path = "_design/"..view.."/_view/"..k
   print("Path is "..path .. " v: " ..v)
   return doc:retrieve(path, { key = '"'..v..'"' })
end
-- needs a moar thorough rewrite..
-- lookup artist and album and title contains query
---- or tag = "" or tag contains query
function couch:search(doc, query, qop, order)
   local rset = {}
   local ret
   for k,v in pairs(query) do
      print("search: "..k .." -> " .. v)
      ret = couch.lookup(doc, "search", k, v)
      --ret = doc:retrieve("_design/search/_view/md5", {key=v})
      if ret then
         return ret
      end
   end
   return rset
end

function couch:generate_view(doc, query)
   local sel = ''
   for k, v in pairs(query) do
      sel = sel .. 'doc.'..k..'.indexOf("'..v..'") != -1 && '
   end
   sel = sel .. '1'
   print("generating view: ".. sel)
   local view = {
      map = "function(doc) { if ( "..sel.." ) { emit(doc) } }"
   }
   return doc:create(view, "_temp_view")
end

return couch

