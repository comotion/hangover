#!/usr/local/bin/orbit
local orbit = require "orbit"
local ocash = require "orbit.cache"
local json  = require "cjson"
json.encode_invalid_numbers = true
-- local cjson2 = cjson.new() -- is thread safer
-- local cjson_safe = require "cjson.safe" -- arf on error instead of barfing

-- globally default station
default_station = "oslobass"

module("hangover", package.seeall, orbit.new)
local cache  = ocash.new(hangover, cache_path)
local tracks = require "lib/tracks"
local u      = require "lib/util"
local io = require "io"

hangover.not_found = function (web)
  web.status = "404 Not Found"
  return [[<html><head><title>Not Found</title></head>
  <body><p>Not found! Try harder you nit</p></body></html>]]
end                  
hangover.server_error = function (web, msg)                                                                                  
  web.status = "500 Something died"
  io.stderr:write("G U R U M E D I A T I O N\n", msg, u.dump(web), "\n-- \n")
  msg = "Something died, sorry. Death is a natural part of life."
  return [[<html><head><title>Server Error</title></head>
  <body><pre>]] .. msg .. [[</pre></body></html>]]
end

-- Hangover API
-- GET   /db
-- Searches the database
-- Arguments: q=[query] (fields=title,artist) (maxresults=40) (page=0) (qf=artist,title,mood)
-- Output: {fields=[id,title,artist], pages=3, result=[{id => 2, title => penis}, ...]}
function get_db(web,...)
  local query = web.GET.q or {}
  local limit = web.GET.maxresults or 25
  local page = web.GET.page or 0
  local fields = web.GET.fields
  local qf = web.GET.qf or "artist,title"
  if type(limit)  == "table" then limit=limit[1] end
  if type(page)   == "table" then page=page[1] end
  -- join these so they split nicely later;to avoid pathology
  if type(fields) == "table" then fields = u.join(fields) end
  if type(query)  == "table" then query = u.join(query) end
  if type(qf)     == "table" then qf = u.join(qf) end

  local result, pages = tracks:search(query, qf, limit, page)

  if fields then
    fields = u.split(fields)
    result = tracks.filter(result, fields)
  else
    fields = tracks.fields(result);
  end
  return json.encode{{fields=fields,pages=pages,result=result}}
end

-- POST /db
-- Insert shit in database
-- returns: trackid or error
function post_db(web,...)
  local input = json.decode(web.input.post_data)
  if not input.artist or not input.title then
    web.status = 423
    return "Not enough, try harder."
  end
  return tracks:add(input.artist,input.title,input)
end

-- PUT   /db/:id:
-- Update
function put_db(web,...)
  local id = ...
  local input = web.input.post_data
  u.out(input)
  if input then
    input = json.decode(input)
  end
  return tracks:update(id, input)
end
-- DELETE /db/:id:
-- Remove
function del_db(web,...)
  local id = ...
  return json.encode({web.GET, path, tracks:dump()})
end
-- GET /dayplan/station/(interval)
-- Get selectors and playlists for interval.
function get_dayplan(web, ...)
  station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end
function get_next(web, ...)
  station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end
function get_end(web, ...)
  station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end
function get_meta(web, ...)
  station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end
function get_fail(web, ...)
  a = fail[d] + f
end

function render( t, content)
  return html {
    head { title("Hangover - " .. t),
           meta{ ["http-equiv"] = "Content-Type",
             content = "text/html; charset=utf-8" },
           link{ rel = 'stylesheet', type = 'text/css',  
             href = '/p/style.css', media = 'screen'}
  },
    body { 
      div{ id="content",
        content 
      }
    }
  }
end

-- land us at our js-fantastic instead of this bull
function index(web)
  return web:redirect("p/test.html")
end
function view_web(web)
  web.script_name = "foo"
  return render("web!",  web:page("views/foo.op"))
end
hangover:htmlify("render")

hangover:dispatch_get(view_web, "/web", "/stfu")
hangover:dispatch_get(index, "/", "/post/(%d+)")

-- the real red meat
hangover:dispatch_get   (get_db, "/db/?")
hangover:dispatch_post  (post_db,"/db/?")
hangover:dispatch_put   (put_db, "/db/(%d+)")
hangover:dispatch_delete(del_db, "/db/(%d+)")
hangover:dispatch_get   (get_next, "/next/?", "/next/(%w+)")
hangover:dispatch_get   (get_end, "/end/?", "/end/(%w+)")
hangover:dispatch_get   (get_meta, "/meta/?", "/meta/(%w+)")
hangover:dispatch_get   (get_dayplan, "/dayplan/?", "/dayplan/(%w+)")
hangover:dispatch_get   (get_fail, "/fail/?")

hangover:dispatch_static("/p/.+")

return _M

