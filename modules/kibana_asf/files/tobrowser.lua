#!/usr/bin/env lua
package.path = package.path .. ";/usr/local/etc/logging/?.lua"

local redded = 0 -- number of redacted entries

-- Get which user has authed this request
local user = os.getenv('REMOTE_USER')

-- Query LDAP for host records
local hosts = {}

-- If auth is broken/circumvented, return nothing
if not user then
    print("{}")
    os.exit()
end

-- Validate user id, just in case
user = user:gsub("[^-a-zA-Z0-9_.]+", "")

-- Construct a list of valid hosts to retain data for
local p = io.popen("ldapsearch -x -LLL uid="..user .. " host", "r")
if p then
    local data = p:read("*a")
    p:close()
    for host in data:gmatch("host: ([^\r\n]+)") do
        host = host:gsub("%.apache%.org", "")
        table.insert(hosts, host)
    end
end


-- Function for redacting ElasticSearch JSON results
function retain(parent, name, values)
    for k, v in pairs(parent) do

        -- Redact children
        if type(v) == "table" and k ~= "nodes" then
            parent[k] = retain(v, name, values)
            
            -- Kill off _source elements that contain redacted information
            if k == '_source' and parent[k] == nil then
                return nil
            end
        else
            -- If 'key' is set and matches (or no key is present) and value is not found in value array, remove the element
            if k == name or name == nil then
                local okay = false
                for x,y in pairs(values) do
                    if y == v or y == "*" then
                        okay = true
                        break
                    end
                end
                if not okay then
                    redded = redded + 1
                    return nil
                end
            end
        end
    end
    return parent
end


-- Init program
local JSON = require"JSON"

-- Read JSON data from stdin
local data = io.stdin:read("*a")

-- Decode JSON
local json = JSON:decode(data)

-- Only retain allowed hosts from result set
json = retain(json, "host", hosts)
json = retain(json, "node", hosts)

-- Change search result info
if redded > 0 and json._shards then
    json.hits.total = json.hits.total - redded
end

local out

if redded > 0 then
    -- Re-encode JSON object
    out = JSON:encode(json)
    
    -- Spit it out
    print(out)
else
    print(data)
end

