#!/usr/local/bin/orbit
local orbit = require "orbit"
local ocash = require "orbit.cache"
local cjson  = require "cjson.safe" -- arf on error instead of barfing
local json = cjson.new() -- is thread safer
local convert, ratio, safe = json.encode_sparse_array(true)
json.encode_invalid_numbers = true -- avoid b00gs

module("hangover", package.seeall, orbit.new)
package.path = package.path..";lib/?.lua;lib/?/?.lua"
local cache  = ocash.new(hangover, cache_path)
local tracks = require "tracks"
local u      = require "util"
local io     = require "io"
local crypto = require "crypto"
local meta   = require "metadata"
local program= require "program"

require "config"
local user = "badface" -- XXX: basic auth/user db

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
  if web.GET.id then
    return get_track(web, web.GET.id)
  end
  local query = web.GET.q or {}
  local limit = web.GET.maxresults or 25
  local page = web.GET.page or 1
  local skip = (page-1)*limit
  local fields = web.GET.fields
  local qf = web.GET.qf or "artist,title"
  if type(limit)  == "table" then limit=limit[1] end
  if type(page)   == "table" then page=page[1] end
  -- join these so they split nicely later;to avoid pathology
  if type(fields) == "table" then fields = u.join(fields) end
  if type(query)  == "table" then query = u.join(query) end
  if type(qf)     == "table" then qf = u.join(qf) end

  local result, size = tracks:search(query, qf)
  local pages = math.floor(size/limit)+1

  print('got query: '.. u.dump(web.GET).. ' result: '.. u.dump(result))

  if fields then
    fields = u.split(fields)
    print("splitting fields: "..u.dump(fields))
  end
  result = tracks.filter(result, fields, limit, skip)
  return json.encode({{fields=tracks.fields(result),pages=pages,result=result}}).."\n"
end

function getfile(file)
  t = {}
  t.user = user
  t.submitted = os.time()
  t.filename = file.name
  -- XXX: mayhap we shouldn't accept anything other than audio/?
  t.contenttype = string.gsub(string.gsub(file['content-type'], "audio",""), "/","")
  t.extension = file.name:gmatch(".(%w+)$")()
  local dest, tname = u.open_temp_file(temp_dir.."/hangover_up@@@")
  local bytes = file.contents
  if not dest then
    return nil,json.encode{{status="fail",reason="bad tempfile, baad"}}
  end
  -- XXX: for progress we need chunking and status
  dest:write(bytes)
  dest:close()
  print("["..os.date("%c", t.submitted).. "] '"..t.filename.."' -> "..tname)
  print("'"..t.filename .. "'".." " .. os.difftime(os.time(), t.submitted).."s")
  t.md5 = crypto.digest("md5", bytes)
  local destname = t.md5..'.'..t.extension-- krav's pathless filename
  t.path = tracks_path .. "/" .. destname
  print("now moving ... ".. tname .. ' path: '..t.path)
  os.execute('mkdir -p '..tracks_path)
  local rc, err = os.rename(tname, t.path)
  if not rc then
    return nil, json.encode{{status="fail", reason=err}}
  end
  print("'"..destname.. "'".." " .. os.difftime(os.time(), t.submitted).."s")
  print(u.dump(t));
  return t
end

-- POST /db
-- Insert shit in database
-- returns: trackid or error
function post_db(web,...)
  local id, file = web.POST.id, web.POST.file
  if file then -- someone is uploading a mix
    t, some = getfile(file)
    if not t then
       return some
    end
    -- attempt id3 extraction / file metadata
    tags, failure = meta.gettags(t.path, t)
    if not tags then
       return failure
    end
    -- add to database, tags and all
    id = tracks:add(tags)
    -- add to database, tags and all
    return json.encode{tracks=t,id=id,tags=tags}
  elseif id then -- just editing the node
    return tracks:put(id,web.POST)
  else -- not an upload, we have no id-ea
    web.status = 400
    return "Not enough, try harder."
  end

  -- redirect to tag editor (what of multiple files?)
  return web:redirect("/#!database/edit/"..id)
end

-- GET   /db/:id:
function get_track(web,...)
  local id = ...
  local track = tracks:get(id)
  return json.encode(track)
end


-- PUT   /db/:id:
-- Update
function put_db(web,...)
  local id = ...
  local input = web.input.post_data
  u.out(input)
  if not input then
    return json.encode{{result=nil, error="nothing to put"}}
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

-- POST /playlist/
function post_playlist(web, ...)
  station = ... or default_station
  -- only god knows yet
  local id = web.POST.id
  local list = json.decode(web.POST.list)
  if id then
    playlist:put(id, list)
  else
    playlist:add(list)
  end
  return json.encode{id=id, list=list}
end
function get_playlist(web, ...)
  station = ... or default_station
  local id = web.GET.id
  if id then
    return json.encode{playlist:get(id)}
  else
    return json.encode{playlist:search(web.GET.q)}
  end
end
function put_playlist(web, ...)
  station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end
-- PUT /playlist/:id:
-- [{id={blah}},..]}
function put_playlist(web, ...)
  station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end

-- POST /selecta/:id:
-- [{q=drit,w=1,100},{..}]
function post_selecta(web, ...)
  station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end
function get_selecta(web, ...)
  station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end
function put_selecta(web, ...)
  station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end
-- GET /program/:id:
-- {name:blah, selector=:id:, start:time, end:time, playlist:[{id={songid,etc}},..]}
function get_program(web, ...)
  local id = ... or nil
  if not id then
    web.status = "404 Not Found"
    return ""
  end
end
-- POST /program/
-- {name:blah, selector=:id:, start:time, end:time, playlist:[{id={songid,etc}},..]}
function post_program(web, ...)
  local id = ... or nil
  if not web.POST.start then
    web.status = 400
    return "Not enough, programs start somewhere"
  end
  if id then
    program:put(id, web.POST)
  else
    program:add(web.POST)
  end
end

-- GET /plan?from=time,to=time
-- [{program, fra, til, pri},{}
-- returns all overlapping programs in time period,
-- with priorities (re: most specific match wins)
function get_plan(web, ...)
  station = ... or default_station
  local from = web.GET.from or 'now'
  local to = web.GET.to or 'now'

  programs = program:search(from, to)
  return json.encode{programs}
end

-- GET /next/:station:?time=now
-- returns the path to the next song to play.
-- finds the current ostn, specific program and in that
-- program selects the next song
function get_next(web, ...)
  local station = ... or default_station
  -- pick a random unplayed track
  local result = tracks:search('', "path", 1, nil, "played")
  result = tracks.filter(result, {"path", "title"})
  return result[1].title
  --return json.encode(result[1])
end
function get_end(web, ...)
  local station = ... or default_station
  -- only god knows yet
  return json.encode({web.GET, path, tracks:dump()})
end
function get_meta(web, ...)
  local station = ... or default_station
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
--  return web:redirect("p/index.html")
--  return render("web!",  web:page("views/index.op"))
--  web.script_name = "index"
  return web:page("views/index.op")
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
hangover:dispatch_get   (get_track, "/db/(%d+)")
hangover:dispatch_post  (post_db,"/db/?")
hangover:dispatch_put   (put_db, "/db/(%d+)")
hangover:dispatch_post  (put_db, "/db/(%d+)")
hangover:dispatch_delete(del_db, "/db/(%d+)")
hangover:dispatch_get   (get_next, "/next/?", "/next/(%w+)")
hangover:dispatch_get   (get_end, "/end/?", "/end/(%w+)")
hangover:dispatch_get   (get_meta, "/meta/?", "/meta/(%w+)")
hangover:dispatch_get   (get_dayplan, "/dayplan/?", "/dayplan/(%w+)")
hangover:dispatch_get   (get_program, "/program/(%w+)", "/program/?")
hangover:dispatch_get   (get_plan, "/plan/?", "/plan/(%w+)")
hangover:dispatch_get   (get_playlist, "/playlist/?", "/playlist/(%d+)")
hangover:dispatch_get   (get_selecta, "/selecta/?", "/selecta/(%d+)")
hangover:dispatch_put   (put_selecta, "/selecta/?", "/selecta/(%d+)")
hangover:dispatch_post  (post_selecta, "/selecta/?", "/selecta/(%d+)")

hangover:dispatch_get   (get_fail, "/fail/?")

hangover:dispatch_static("/css/.+")
hangover:dispatch_static("/js/.+")
hangover:dispatch_static("/img/.+")
hangover:dispatch_static("/tmpl/.+")

return _M

