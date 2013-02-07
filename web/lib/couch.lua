-- abstract some couch shit

--[[
couchdb has views for queries.
want to look up some word for all fields

get all keys:
map: function(doc) { for (var thing in doc) { emit(thing,1); } }
reduce: function(key,values) { return sum(values); }


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

function couch:genuid(doc)
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

-- needs a moar thorough rewrite..
-- lookup artist and album and title contains query
---- or tag = "" or tag contains query
function couch:search(db, query, qop, order)
   doc:retrieve(query);
end

return couch

