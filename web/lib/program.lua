-- PROGRAM -----------------
--
--   - program
--     - station - start - stop - selector - items
--     - recurring -> weekly, daily, blank

-- the station plan consists of overlapping programs
-- each program has a period
-- eg every Monday at 12 or 13 May 00:00
-- and a duration, eg 2 hours
-- 
-- a program has
-- { id, name, [selector, playlist]}
require "os"
require "math"
local db  = require "lib.tokyo"
local u   = require "lib.util"

module("program", package.seeall)

function program:init()
  return tokyo:init("programs")
end
prg = program:init()

function program:put(pkey,cols)
  return tokyo:put(prg,pkey,cols)
end

-- a program has a human-friendly name, 
-- launches at some date, starts at a particular time of day
-- lasts for x minutes and optionally repeats
-- every X * {day, week, month, year}
function program:add(name, startdate, time, duration, every, X)
  local p = {}
  p.name = name
  p.startday = startdate
  p.time = time
  p.duration = duration
end

-- when asked to compile a plan,
-- we find all programs for given time
-- and give priority to shorter, non-regular programs
-- so if it doesn't repeat, more prio than repeat programs
-- if a shorter than b at same time, more priority to a
function program:search(from, to)
  local now = os.time()
  local programs
  if from == 'now' then
     from = now
  end
  if from == 'now' then
     from = now
  end
  -- for each program in db,
  -- generate time, check interval
  -- for a program in interval
  --   for b program in interval
  --      if overlap?
  --        if a irregular a >= b + 1
  --        if a shorter a >= b + 1
  --        if a starts earlier, a wins
  -- tiebreaker: newest program wins
  --
  return programs
end


