# This script pulls the Jenkins node displayName, offline status, and offlineCauseReason
# then posts it to DataDog as a custom service check. 

import ConfigParser
from datadog import initialize, api
from datadog.api.constants import CheckStatus
import json
import urllib

config = ConfigParser.ConfigParser()
config.read("settings.cfg")
options = {'api_key': config.get("datadog_agent", "api_key")}
initialize(**options)

url = "https://builds.apache.org/computer/api/json"
check = 'jenkinsNode.status'
response = urllib.urlopen(url)
jenkinsNodes = json.loads(response.read())

for node in jenkinsNodes["computer"]:
    if (node["offline"]==True):
        host = node["displayName"]
        status = CheckStatus.CRITICAL # equals 2
    if (node["offline"]==False):
        host = node["displayName"]
        status = CheckStatus.OK # equals 0
    
    api.ServiceCheck.check(check=check, host_name=host, status=status, message=node["offlineCauseReason"])
