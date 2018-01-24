#!/usr/bin/env lua
local yaml = require 'lyaml'

-- Get rule-set on load
local yamlData = "foo: bar"
local f = io.open("/usr/local/etc/aardvark/ruleset.yaml", "r")
if f then
   yamlData = f:read("*a")
   f:close()
end   
local yamlRuleset = yaml.load(yamlData)

-- Get IP whitelist on load
local whitelist = {}
local wl = io.open("/usr/local/etc/aardvark/whitelist", "r")
if wl then
   for line in wl:lines() do
    table.insert (whitelist, line);
   end
end

function has_value(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return true
    end
  end
end

function logspam(r, buck)
   local f = io.open("/usr/local/etc/aardvark/spammers.txt", "a")
   if f then
       local dbno = r:sha1(math.random(9999,99999999) .. r.useragent_ip):sub(1,8)
       f:write("[" .. os.date("%c", os.time()) .. "] " .. r.useragent_ip .. " spammed Aardvark (" .. dbno .. ")\n")
       f:close()
       
       -- if debug data, spit into the debug dir
       if buck then
         local bb = io.open("/usr/local/etc/aardvark/debug/" .. dbno .. ".log", "w")
          if bb then
            bb:write("POST " .. r.uri .. ":\n\n")
            bb:write(buck)
            bb:close()
         end
      end
   end
end

function input_filter(r)

   -- check for IP in whitelist and exit if found
   if has_value(whitelist, r.useragent_ip) then
       return
   end
   
   -- first, if we need to ignore this URL, we'll do so
   for k, v in pairs(yamlRuleset.ignoreurls or {}) do
      if r.uri:match(v) then
         return
      end
   end
   
   -- Now, catch bad URLs
   for k, v in pairs(yamlRuleset.spamurls or {}) do
      if r.uri:match(v) then
         logspam(r, "Hit Spam URL: " .. r.uri)
         return 500
      end
   end
   
   
   local auxcounter = 0
   local reqcounter = 0
   local badbody = ""
   coroutine.yield() -- yield, wait for buckets
   
   -- for each bucket..
   while bucket do
      local caught = false -- bool for whether we caught anything
      local triggered = false
      local tmpbucket = bucket --add this
      bucket = bucket:gsub("%+", " ")
      
      -- Look for data in POST we don't like
      for k, v in pairs(yamlRuleset.postmatches or {}) do
         if bucket:lower():match(v) then
            logspam(r, bucket)
            caught = true
            return 500
         end
      end
      
      -- Then, check for multi-match rules
      -- First, required vars
      local mm = yamlRuleset.multimatch or {}
      for k, v in pairs(mm.required or {}) do
         if bucket:lower():match(v) then
            reqcounter = reqcounter + 1
            triggered = true
         end
      end
      -- then, auxiliary ones
      for k, v in pairs(mm.auxiliary or {}) do
         if bucket:lower():match(v) then
            auxcounter = auxcounter + 1
            triggered = true
         end
      end
      
      if triggered then
         badbody = badbody .. "<!-- begin bucket -->\n" .. bucket .. "\n<!-- end bucket -->\n"
      end
      
      -- Now, require all req ones and at least one aux (or none if no aux)
      if reqcounter >= #(mm.required or {}) and (auxcounter >= 1 or #(mm.auxiliary or {}) == 0) then
         caught = true
         logspam(r, badbody)
         return 500
      end
      
      -- if nothing happened, pass through bucket
      if not caught then
         coroutine.yield(tmpbucket)
      end
   end
end
