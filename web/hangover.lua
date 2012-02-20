require "orbit"

module("hangover", package.seeall, orbit.new)
require "lib/model"

function render(content)
  return html {
    head { title("Hangover"),
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
  return render(
  )
end

hangover:dispatch_static("/p/.+")
hangover:dispatch_get(index, "/")

hangover:htmlify("render")

return _M

