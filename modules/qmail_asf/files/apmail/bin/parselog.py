import json, re, time, sys, os
from datetime import datetime
from os import listdir
from os.path import isfile, join

execfile("common.conf")

wsec = 604800 # Seconds per week
now = time.time()
now = int(now - (now % wsec)) + wsec
gjs = {}
gjson = {}

domains = [ f for f in listdir("LISTS_DIR/") if os.path.isdir(join("LISTS_DIR/",f)) ]

for domain in domains:
    ls = []
    if not (domain == ".." or domain == "." or domain == "apache.org"):
        dirs = [ f for f in listdir("LISTS_DIR/%s/" % domain) if os.path.isdir(join("LISTS_DIR/%s/" % domain,f)) and (f != ".." and f != ".") ]
        for l in dirs:
            js = {}
            when = now
            for i in range(0,52*5):
                when = now - (wsec*i)
                js[when] = 0
            
            print ("Scanning LISTS_DIR/%s/%s/Log" % (domain, l))
            try:
                if os.path.isfile("LISTS_DIR/%s/%s/Log" % (domain, l)):
                    with open("LISTS_DIR/%s/%s/Log" % (domain, l), "r") as log:
                        for line in log:
                            m = re.match(r"(\d+) ([-+]).*", line)
                            if m:
                                w = int(m.group(1))
                                w = w - (w % wsec)
                                a = 1
                                if (m.group(2) == "-"):
                                    a = -1
                                if w in js:
                                    js[w] += a
                                else:
                                    js[when] += a
                        log.close()
                    
#                    with open("JSON_DIR/output/%s-%s.json" % (domain, l), "w") as jsout:
#                        jsout.write(json.dumps(js))
#                        jsout.close()
#                        print("Wrote %s-%s.json" % (domain, l))
                        ls.append(l)
                        gjson["%s-%s" % (domain, l)] = js
            except Exception as err:
                print(err)
                
        gjs[domain] = ls
    
    
with open("JSON_DIR/output/global.json", "w") as f:
    f.write(json.dumps(gjs))
    f.close()

with open("JSON_DIR/output/everything.json", "w") as f:
    f.write(json.dumps(gjson))
    f.close()
    
print("All done!")

