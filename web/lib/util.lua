module("util", package.seeall)
-- dump a table
function dump(o)
   local s = ''
   if type(o) == 'table' then
      s = '{ '
      for k,v in pairs(o) do
         s = s .. k .. " = ".. dump(v)
         if i ~= #o then s = s .. '; ' end
      end
      s = s .. ' }\n'
   else
      s = tostring(o)
   end
   return s
end
-- helpers
function out(thing)
   print(dump(thing))
end
-- log to file
function log_line(file, line)
   print ("logging to " .. file ..  "::" .. line)
   local outfile = assert(io.open(file, "a+"))
   outfile:write(line)
   outfile:flush()
   outfile:close()
   io.stderr:write("wrote line!\n")
end

return _M
