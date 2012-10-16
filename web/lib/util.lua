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

-- flatten table tree into table
function flatten(t)
  local flat = {}
  for k,v in pairs(t) do
     if (type(v) == "table") then
        local realflat = flatten(v)
        -- merge it in
        for sk,sv in pairs(realflat) do
           if not flat[sk] then
              flat[sk] = sv
           end
        end
     else
        flat[k] = v
     end
  end
  return flat
end
        

-- dump a table
function dump(o)
  local s = ''
  if type(o) == 'table' then
    s = "\n{ "
    for k,v in pairs(o) do
      s = s .. k .. " = ".. dump(v)
      if i ~= #o then s = s .. '; ' end
    end
    s = s .. ' }'
  else
    s = tostring(o)
  end
  return s
end
-- helpers
function out(thing)
  print(dump(thing))
end

function keys(thing)
  if type(thing) == "table" then
    local res = {}
    for k,v in pairs(thing) do
      --print(k .. " -> " .. v)
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

-- open a tempfile
function open_temp_file(template)
   local handle
   local fname
   assert(string.match(template, "@@@"), 
      "ERROR open_temp_file: template must contain \"@@@\".")
   while true do
      fname = string.gsub(template, "@@@", tostring(math.random(10000000,99999999)))
      handle = io.open(fname, "r")
      if not handle then
         handle = io.open(fname, "w")
         break
      end
      io.close(handle)
      --io.write(".")   -- Shows collision, comment out except for diagnostics
   end
   return handle, fname
end

-- convert to hex
function bintohex(s)
  return (s:gsub('(.)', function(c)
    return string.format('%02x', string.byte(c))
  end))
end


return _M

