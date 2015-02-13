local cfgFile = "gitwcsub.cfg" -- change this to the location of the config file

local socket = require"socket" -- LuaSocket: http://files.luaforge.net/releases/luasocket/luasocket/luasocket-2.0.2
local JSON = require "JSON" -- JSON: http://regex.info/code/JSON.lua
local config = require "config"

local cfg = config.read(cfgFile)
local lastLogRotate = 0

local retries, lastping, lastConfigRead = 0, 0, os.time()
local _print = print
local logFD;

local function print(txt)
    local now = os.time()
    if not logFD then
        logFD = io.open(cfg.logging.logFile, "w+")
        if not logFD then 
            _print("Could not open log file " .. cfg.logging.logFile .. " for writing!!")
            os.exit()
        end
    end
    if cfg and cfg.logging.logFile then
        -- First, check if midnight has passed and we need to create a new log.
        if (now % cfg.logging.rotateTime) <= 20 and now > (lastLogRotate+20) then
            if logRotate ~= 0 then
                _print("Rotating logs...")
                logFD:close()
            end
            local newName = os.date("!" .. cfg.logging.logArchives)
            _print("Relocating "..cfg.logging.logFile .. " to " .. newName)
            os.execute( ("mv %s %s"):format(cfg.logging.logFile, newName) )
            local ancientName = os.date("!" .. cfg.logging.logArchives, now - (cfg.logging.logLimit * cfg.logging.rotateTime) )
            os.execute( ("rm %s"):format(ancientName) )
            lastLogRotate = now
            logFD = io.open(cfg.logging.logFile, "w+")
        end
        logFD:write(os.date("![%Y-%m-%d %h:%M:%S]: ") .. txt .. "\n")
        logFD:flush()
        _print (os.date("![%Y-%m-%d %h:%M:%S]: ") .. txt)
    else
        _print(txt)
    end
end
        

function connectToPubSub(url)
    local server, port, uri = url:match("^([^:]+):(%d+)(/.+)$")
    print("Connecting to PubSub server " .. server)
    local s = socket.tcp()
    s:settimeout(2)
    local success, err = s:connect(socket.dns.toip(server) or server, tonumber(port))
    if not success then
        print("Failed to connect: ".. err)
        return false
    end
    s:send("GET " .. uri .. " HTTP/1.1\r\n");
    s:send("Host: " .. server .. "\r\n\r\n");
    s:settimeout(20)
    return s
end

-- updateRepository: Updates a repository or clones a new one if it doesn't exist.
function updateRepository(path, repository)
    -- Check that the repo exists
    local f = io.popen("ls " .. path)
    if f then
        local data = f:read("*l")
        f:close()
        local pullFailed = false
        if data then
            -- if the repository does exist, pull from it
            print( ("Pulling from %s%s.git into %s"):format(cfg.servers.git, repository, path) )
            local rc, foo, rv = os.execute( ("git --git-dir %s/.git pull"):format(path) )
            if rv ~= 0 then
                pullFailed = true
                print( ("Pull from %s%s.git into %s failed, trying clone instead"):format(cfg.servers.git, repository, path) )
            end
        end
        if not data or pullFailed then
            -- if it doesn't exist, or if pull failed (folder exists but is empty), create it by cloning
            print( ("Cloning from %s%s.git into %s"):format(cfg.servers.git, repository, path) )
            local rc, foo, rv = os.execute( ("git clone -b %s --single-branch %s%s.git %s"):format(cfg.misc.refreal, cfg.servers.git, repository, path) )
            if rv ~= 0 then
                print( ("Could not clone from %s%s.git into %s!"):format(cfg.servers.git, repository, path) )
            end
        end
    end
end


-- readPubSub: Tries to read a line from the pubsub
function readPubSub(s)
    lastping = os.time()
    while true do
    
        -- Reread the configuration every 30 seconds, so we won't have to restart anything
        if (lastConfigRead + 30) < os.time() then
            if cfg.misc.debug then
                print("Reloading configuration...")
            end
            lastConfigRead = os.time()
            cfg = config.read(cfgFile)
        end
        
        -- Try to fetch a json object from pubsub
        local receive, err = s:receive('*l')
        if receive and receive:match("^([[a-zA-Z0-9]+)$") then
            local howMuch = tonumber(receive, 16)
            receive, err = s:receive(howMuch+2)
        end
        
        -- We got an object, parse it and see if it matches a site object
        if receive then
            if cfg.misc.debug then
                print(receive)
            end
            lastping = os.time()
            if receive:match([[^{%s*"commit"%s*:]]) and receive:len() > 3 then
                local line = receive:gsub("\0", ""):gsub(",\r?\n", "")
                local okay, json = pcall(function() return JSON:decode(line) end)
                if okay and json then
                    local commit = json.commit or {}
                    if commit.log and commit.repository and commit.repository == "git" then
                        if cfg.misc.debug then
                            print("Got git push from repository " .. (commit.project or "?") .. ".git")
                        end
                        -- For each repository...
                        for path, repository in pairs(cfg.tracking) do
                            -- Do we have a match?
                            if commit.project and commit.project == repository then
                                if commit.ref == cfg.misc.ref then
                                    if cfg.misc.debug then
                                        print( ("Pulling from %s.git"):format(commit.project) )
                                    end
                                    -- We have a match, let's update the local copy (or create it)
                                    updateRepository(path, repository)
                                end
                            end
                        end
                    end
                end
            end
        -- various timeouts
        else
            if err == "timeout" then
                if lastping < (os.time() - 30) then
                    err = "disconnected (ping timeout)"
                    retries = 0
                end
            end
            if err ~= "timeout" then
                print("Connection closed: " .. err)
                s = connectToPubSub(cfg.servers.pubsub)  -- reconnect to PubSub server
                if s then 
                    retries = 0
                else
                    retries = retries + 1
                end
            end
            
            if not s and retries > 100 then
                print("Disconnected and could not reconnect, giving up.")
                break -- timeout, nothing more to receive at the moment, let's get back to responding to PINGs
            end
        end
    end
end


--[[
Main program
]]
print("Program started, updating/populating repositories:")
for path, repository in pairs(cfg.tracking) do
    print("Checking " .. path .. "...")
    updateRepository(path, repository)
end

local s = connectToPubSub(cfg.servers.pubsub)
if s then
    readPubSub(s)
else
    print("Failed to connect to pubsub service!")
end

print("Bye for now!")


