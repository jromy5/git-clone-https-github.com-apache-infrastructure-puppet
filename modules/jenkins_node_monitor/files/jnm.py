# This script pulls the Jenkins node displayName, offline status, and offlineCauseReason
# then posts it to DataDog as a custom service check. 

import ConfigParser
import datadog
import requests

config = ConfigParser.ConfigParser()
config.read("settings.cfg")
options = {'api_key': config.get("dd_agent", "api_key")}
datadog.initialize(**options)

url = "https://builds.apache.org/computer/api/json"
check = 'jenkinsNode.status'
jenkinsNodes = requests.get(url).json()

for node in jenkinsNodes["computer"]:
    if (node["offline"]==True):
        host = node["displayName"]
        status = 2 # CheckStatus.CRITICAL
    if (node["offline"]==False):
        host = node["displayName"]
        status = 0 # CheckStatus.OK
    
    datadog.api.ServiceCheck.check(check=check, host_name=host, status=status, message=node["offlineCauseReason"])
