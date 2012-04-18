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
-- Arguments: q=[query] (fields=title,artist) (maxresults=40) (page=0)
-- Output: {fields=[id,title,artist], pages=3, result=[{id => 2, title => penis}, ...]}
function get_db(web,...)
  if type(web.GET.q) == "table" then
    -- foo
  end
  limit = web.GET.maxresults or 25
  if type(limit) == "table" then
    limit=limit[1]
  end
  page = web.GET.page or 0
  if type(page) == "table" then
    page=page[1]
  end
  --if type(fields) = "table" then
  fields = web.GET.fields
  fields = u.split(fields,',')

  result = tracks:search(query, limit, page)
  if fields then result = u.filter(result,fields) end
  return json.encode({web.GET, path, result})
end

-- POST /db
-- Insert shit in database
function post_db(web,...)
  return json.encode({web.POST, path, tracks:dump()})
end

-- PUT   /db/:id:
-- Update
function put_db(web,...)
  return json.encode({web.GET, path, tracks:dump()})
end
-- DELETE /db/:id:
-- Remove
function delete_db(web,...)
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
hangover:dispatch_get (get_db, "/db", "/db/.*")
hangover:dispatch_post(post_db,"/db", "/db/.*")
hangover:dispatch_put (put_db, "/db/.+")
hangover:dispatch_delete(delete_db, "/db/.+")

hangover:dispatch_static("/p/.+")

return _M

