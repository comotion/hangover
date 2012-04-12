local orbit = require "orbit"
require "orbit.cache"

module("hangover", package.seeall, orbit.new)
local cache = orbit.cache.new(hangover, cache_path)
tracks = require "lib/model"

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


function index(web)
  return render("hello",tracks:dump())
end

function render_add_track()
  return render("Add track", html{
     "something something"
  })
end

function render_add_track2()
  return orbit.web_methods.page("views/add_track")
end

function view_links(web)
  return render("web!",html { li{a{ href= web:link("/"), "HOME" }} })
end

function view_webi(web)
  return render("web!",  web:page_inline(fooin))
end
function view_web(web)
  web.script_name = "foo"
  return render("web!",  web:page("views/foo.op"))
  --return render("web!",html { li{a{ href= web:link("/"), "HOME" }} })
end

-- inline page example
fooin = [===[
<html>
<body>
<p>Hello Balle!</p>
<p>I am in $web|real_path, and the script is
$web|script_name.</p>
$lua{[[
if not web.input.msg then
  web.input.msg = "nothing"
end
]]}
<p>You passed: $web|input|msg.</p>
$include{ "bar.op" }
</body>
</html>
]===]

hangover:htmlify("render")
hangover:htmlify("render_add_track")
hangover:htmlify("view_links")

hangover:dispatch_get(index, "/")
hangover:dispatch_get(render_add_track, "/track")
hangover:dispatch_get(render_add_track2, "/wtf")
hangover:dispatch_get(view_web, "/stfu")
hangover:dispatch_get(view_webi, "/stfui")
hangover:dispatch_get(view_links, "/lonks")
hangover:dispatch_get(cache(index), "/post/(%d+)")

hangover:dispatch_static("/p/.+")

return _M

