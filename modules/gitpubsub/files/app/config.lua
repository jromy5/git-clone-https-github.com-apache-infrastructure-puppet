local config = {}

function split(txt, delim)
    local tbl = {}
    for k in txt:gmatch("([^"..delim.."]+)" .. delim) do
        table.insert(tbl, k)
    end
    return tbl
end

function config.read(file)
    local f = io.open(file)
    local cfg = {}
    if f then
        local name, key, value, pobj
        while true do
            local line = f:read("*l")
            if not line then break end
            if not line:match("^%s*#") then
                local n = line:match("^%[(%S+)%]")
                if n then
                    name = n
                    local o = cfg
                    for child in n:lower():gmatch("([^:]+)") do
                        o[child] = o[child] or {}
                        o = o[child]
                    end
                    pobj = o
                else
                    local k, v = line:match("%s*(%S+):%s+([^#]*)")
                    if k and v then
                        if v:sub(#v,#v) == [[\]] then
                            v = v:sub(1,#v-1)
                            while true do
                                local line = f:read("*l")
                                if not line then break end
                                local b = (line:sub(#line, #line) ~= [[\]])
                                v = v .. (b and line or line:sub(1,#line-1))
                                if b then break end
                            end
                        end
                        v = v:gsub("\\n", "\n")
                        local fname = v:match("read%('([^']+)'%)")
                        if fname then
                            local i = io.open(fname)
                            if i then
                                v = i:read("*a")
                                i:close()
                            end
                        end
                        if v:match("^%d+$") then
                            v = tonumber(v)
                        else
                            if v == "true" then v = true elseif v == "false" then v = false end
                        end
                        pobj[k] = type(v) == "string" and v:gsub("%s+$", "") or v
                    end
                end
            end
        end
        f:close()
        return cfg
    else
        return nil
    end
end

return config
