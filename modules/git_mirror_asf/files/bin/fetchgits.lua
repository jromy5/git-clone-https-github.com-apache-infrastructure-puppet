local f = io.open("../git-wip.txt", "r")
local line = f:read("*l")
while line do
    local repo, title = line:match("(.-%.git) ([^\r\n]+)")
    if repo and title then
	    print("Prepping for " .. repo .. " (" .. title .. ")...")
            os.execute("/x1/git/bin/create-mirror-from-git.sh " .. repo .. " \"" .. title .. "\"")
    end
    line = f:read("*l")
end
f:close()

