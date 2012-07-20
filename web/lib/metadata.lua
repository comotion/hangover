module("metadata",package.seeall)
local types,info,edit = unpack(require "lamt.mpeg")
local u = require "util"

function gettags(path)
   local ok, intel, err = pcall(info, {path=path})
   if not ok or not intel then 
      errcode = intel or err
      return nil, errcode, path
   end

   -- clean up tags, unpacking table{table} things
   tag = {}
   if not intel.tags then intel.tags = {} end
   for k,v in pairs(intel.tags) do
      if type(v) == "table" then
         v = u.join(v)
         tag[k] = v
      end
   end
   intel.tags = tag
   return intel
end

return _M
