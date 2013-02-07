-- test some c0uchdb stuff

require "luchia"
local cjson  = require "cjson.safe" -- arf on error instead of barfing
local json = cjson.new() -- is thread safer

local server = { host = "localhost", port = 5984, protocol = "http" }
local db = luchia.database:new(server)
local info = db:info("example")
if not info then
   resp = db:create("example")
   print(json.encode(resp))
end
local doc = luchia.document:new("example", server)
-- Simple document.
local contents = { hello = "world" }
-- Create new document.
local resp = doc:create(contents)
print(json.encode(resp))
-- Check for successful creation.
if doc:response_ok(resp) then
   -- Update document contents.
   print(resp.id)

   contents = { hello = "world", foo = "bar" }
   -- Update document.
   doc:update(contents, resp.id, resp.rev)
else
   print "Fail"
end

local tr = luchia.document:new("tracks", server)
resp = tr:retrieve("_design/search/_view/md5", { startkey="a", endkey="b"})
print(json.encode(resp.rows[1]))
utils = luchia.utilities:new(server)
resp = utils:utilities_get_call("_design/v/_view/name")
print(resp)
