module("util", package.seeall)
-- split a string
function split(str,sep)
  local sep, fields = sep or ",", {}
  local pattern = string.format("([^%s]+)", sep)
  string.gsub(str,pattern, function(c) fields[#fields+1] = c end)
  return fields
end
function join(t, sep)
  sep = sep or ","
  return table.concat(t,sep) --> "a,b,c"
end

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

function get_keys(thing)
   if type(thing) == "table" then
      local res = {}
      for k,_ in pairs(thing) do
         table.insert(res,k)
      end
      return res
   end
   return nil
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
