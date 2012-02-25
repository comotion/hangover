local orbit = require "orbit"
local inspect =require "inspect"

module("hangover", package.seeall, orbit.new)
require "lib/model"

function render(t, content)
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


function index()
  return render("hello","world")
end

function render_add_track()
  return render("Add track", html{
     "something something"
  })
end

function render_add_track2()
  return orbit.web_methods.page("views/add_track")
end

function view_web(web)
  print(inspect( web)) -- debug a little.
  return render("web!",html { li{a{ href= web:link("/"), "HOME" }} })
end

hangover:htmlify("render")
hangover:htmlify("render_add_track")
hangover:htmlify("view_web")


hangover:dispatch_get(index, "/")
hangover:dispatch_get(render_add_track, "/track")
hangover:dispatch_get(render_add_track2, "/wtf")
hangover:dispatch_get(view_web, "/stfu")

hangover:dispatch_static("/p/.+")

return _M

