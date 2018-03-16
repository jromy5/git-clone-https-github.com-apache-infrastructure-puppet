-- Function that checks for membership in ASF
function isMember(uid)
   local ldapquery = ([[ldapsearch -x -LLL -b cn=member,ou=groups,dc=apache,dc=org]])
    local ldapdata = io.popen( ldapquery )
    local data = ldapdata:read("*a")
    ldapdata:close()
    for match in data:gmatch("memberUid: ([-a-z0-9_.]+)") do
        -- Found them?
        if match == uid then
           return true
        end
    end
    return false
end

-- Function that checks if user is a VP/chair
function isChair(uid)
   local ldapquery = ([[ldapsearch -x -LLL -b cn=pmc-chairs,ou=groups,ou=services,dc=apache,dc=org]])
    local ldapdata = io.popen( ldapquery )
    local data = ldapdata:read("*a")
    ldapdata:close()
    for match in data:gmatch("member: uid=([-a-z0-9_.]+)") do
        -- Found them?
        if match == uid then
           return true
        end
    end
    return false
end



function handler(r)
 -- Allow hermes
    if r.useragent_ip == "140.211.11.3" then
        return apache2.OK
    end
    
    -- Check LDAP otherwise
    local user = r.user
    if not r.user then
        local ah = r.headers_in['Authorization'] or 'foo'
        local btxt = ah:match("Basic (.+)")
        if btxt then
            unenc = r:base64_encode(btxt)
            local u = unenc:match("([^:]+):.+")
            if u then
                user = u
            end
        end
    end
    if user and (isMember(user) or isChair(user)) then
        return apache2.OK
    else
        user = user or 'nobody(?)'
        r:err("Access to self-serve denied to user " .. user .. ", not chair/member!")
        return 403
   end
end
