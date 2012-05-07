#!/usr/local/bin/orbit
local orbit = require "orbit"
local ocash = require "orbit.cache"
local json  = require "cjson"
json.encode_invalid_numbers = true
-- local cjson2 = cjson.new()
-- local cjson_safe = require "cjson.safe"
module("hangover", package.seeall, orbit.new)
local cache  = orbit.cache.new(hangover, cache_path)
local tracks = require "lib/model"
local u      = require "lib/util"

-- Hangover API
-- GET   /db
-- Searches the database
-- Arguments: q=[query] (fields=title,artist) (maxresults=40) (page=0) (qf=artist,title,mood)
-- Output: {fields=[id,title,artist], pages=3, result=[{id => 2, title => penis}, ...]}
function get_db(web,...)
  local query = web.GET.q
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

  if not query then
     local result,pages = tracks:search()
     if fields then result = tracks.filter(result,u.split(fields)) end
    return json.encode{result=result,pages=pages}
  end

  local result,pages = tracks:gsearch(query, qf, limit, page)
  if fields then
     result = tracks.filter(result,u.split(fields))
  else
     fields = util.get_keys(result);
   end
  return json.encode{fields=fields,result=result,pages=pages}
end

-- POST /db
-- Insert shit in database
-- returns: trackid or error
function post_db(web,...)
  local input = json.decode(web.input.post_data)
  if not input.artist or not input.title then
     web.status = 501
     return "Not enough"
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
  --return render("hello", html{
  --  li{a{ href= web:link("/"), "HOME" }},
  --  tracks:dump(),
  --})
  --return orbit.web_methods.page("views/add_track")
  --return render("web!",  web:page_inline(fooin))
end
function view_web(web)
  web.script_name = "foo"
  return render("web!",  web:page("views/foo.op"))
  --return render("web!",html { li{a{ href= web:link("/"), "HOME" }} })
end
-- inline page example
fooin = [===[ <html> <body> <p>Hello Balle!</p>
<p>I am in $web|real_path, and the script is $web|script_name.</p>
$lua{[[
if not web.input.msg then
  web.input.msg = "nothing"
end
]]}
<p>You passed: $web|input|msg.</p>
$include{ "bar.op" }
</body> </html>
]===] 
hangover:htmlify("render")
--hangover:htmlify("index")
hangover:htmlify("view_web")

hangover:dispatch_get(view_web, "/web", "/stfu")
hangover:dispatch_get(index, "/", "/post/(%d+)")

-- the real red meat
hangover:dispatch_get   (get_db, "/db/?")
hangover:dispatch_post  (post_db,"/db/?")
hangover:dispatch_put   (put_db, "/db/(%d+)")
hangover:dispatch_delete(del_db, "/db/(%d+)")

hangover:dispatch_static("/p/.+")

return _M

