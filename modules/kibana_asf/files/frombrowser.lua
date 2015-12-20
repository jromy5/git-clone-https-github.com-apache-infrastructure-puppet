#!/usr/bin/env lua
package.path = package.path .. ";/usr/local/etc/logproxy/?.lua"
local JSON = require "JSON"

-- function for injecting strings into each 'query' element in the JSON
function inject(tbl, what)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            inject(v, what)
        elseif k == "query" then
            tbl[k] = tbl[k] .. what
        end
    end
end

-- The main filter

-- Get which user has authed this request
local user = os.getenv('REMOTE_USER')
local kint = os.getenv('REQUEST_URI'):match("^/kibana-int/") and true or false
local rm = os.getenv('REQUEST_METHOD')


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
local hosts = {}
local allHosts = false
local p = io.popen("ldapsearch -x -LLL uid="..user .. " host log-access-host log-access-vhost", "r")
if p then
    local data = p:read("*a")
    p:close()
    for host in data:gmatch("host: ([^\r\n]+)") do
        host = host:gsub("%.apache%.org", "")
        if host ~= "minotaur" then
            table.insert(hosts, ([[@node:"%s.apache.org"]]):format(host))
        end
        if host == "*" then
            allHosts = true
        end
    end
    for host in data:gmatch("log%-access%-host: ([^\r\n]+)") do
        host = host:gsub("%.apache%.org", "")
        table.insert(hosts, ([[@node:"%s.apache.org"]]):format(host))
        if host == "*" then
            allHosts = true
        end
    end
    for host in data:gmatch("log%-access%-vhost: ([^\r\n]+)") do
        host = host:gsub("%.apache%.org", "")
        table.insert(hosts, ([[(vhost:"%s.apache.org" AND logtype:"httpd_access")]]):format(host))
        if host == "*" then
            table.insert(hosts, ([[logtype:"httpd_access"]]):format(host))
        end
    end
end

-- only allow put/delete for allHost accessers
if not allHosts and (rm == "PUT" or rm == "DELETE") then
    print("{}")
else
    -- Read JSON data from stdin
    local data = io.stdin:read("*a")
    local valid, json = pcall(function() return JSON:decode(data) end)
    
    -- If the input contains a query, then mangle it...
    if valid and json then
        -- If user doesn't have access to "*", then inject a host requirement into the query
        if not (allHosts or kint) then
            local what = " AND (" .. table.concat(hosts, " OR ") .. ")"
            inject(json, what)
        end
        local output = JSON:encode(json)
        print(output) -- Send converted data down the chain
    -- If there's no query, just return what was sent
    else
        print(data)
    end
end
