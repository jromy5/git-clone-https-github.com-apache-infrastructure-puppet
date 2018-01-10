/*
 Licensed to the Apache Software Foundation (ASF) under one or more
 contributor license agreements.  See the NOTICE file distributed with
 this work for additional information regarding copyright ownership.
 The ASF licenses this file to You under the Apache License, Version 2.0
 (the "License"); you may not use this file except in compliance with
 the License.  You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/


// checkForSlows: Checks if there is a pending async URL fetching
// that is delayed for more than 2.5 seconds. If found, display the
// spinner, thus letting the user know that the resource is pending.
var pending_urls = [];
var wa = false;


Number.prototype.pad = function(size) {
    var str = String(this);
    while (str.length < size) {
        str = "0" + str;
    }
    return str;
}


function formatDate(date){
    return (date.getFullYear() + "-" +
        (date.getMonth()+1).pad(2) + "-" +
        date.getDate().pad(2) + " " +
        date.getHours().pad(2) + ":" +
        date.getMinutes().pad(2));
}

function checkForSlows() {
    var slows = 0;
    var now = new Date().getTime() / 1000;
    for (var x in pending_urls) {
        if ((now - pending_urls[x]) > 2.5) {
            slows++;
            break;
        }
    }
    if (slows === 0) {
        showSpinner(false);
    } else {
        showSpinner(true);
    }
}

// GetAsync: func for getting a doc async with a callback
function GetAsync(theUrl, xstate, callback) {
    var xmlHttp = null;
    if (window.XMLHttpRequest) {
        xmlHttp = new XMLHttpRequest();
    } else {
        xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
    }
    if (pending_urls) {
        pending_urls[theUrl] = new Date().getTime() / 1000;
    }
    xmlHttp.open("GET", theUrl, true);
    xmlHttp.send(null);
    xmlHttp.onprogress = function() {
        checkForSlows();
    }
    xmlHttp.onerror = function() {
        delete pending_urls[theUrl];
        checkForSlows();
    }
    xmlHttp.onreadystatechange = function(state) {
        if (xmlHttp.readyState == 4) {
            delete pending_urls[theUrl];
        }
        checkForSlows();
        if (xmlHttp.readyState == 4 && xmlHttp.status == 200) {
            if (callback) {
                try {
                    callback(JSON.parse(xmlHttp.responseText), xstate);
                } catch (e) {
                    callback(JSON.parse(xmlHttp.responseText), xstate);
                }
            }

        }
        if (xmlHttp.readyState == 4 && xmlHttp.status == 404) {
            alert("404'ed: " + theUrl);
        }
    };
}

// spinner for checkForSlows
function showSpinner(show) {
    var obj = document.getElementById('spinner');
    if (!obj) {
        obj = document.createElement('div');
        obj.setAttribute("id", "spinner");
        obj.innerHTML = "<img src='spinner.gif'>";
        document.body.appendChild(obj);
    }
    if (show) {
        obj.style.display = "block";
    } else {
        obj.style.display = "none";
    }
}

function renderRepos(json) {
    var obj = document.getElementById('repolist');
    if (json && json.constructor == Object) {
        var projects = [];
        for (var k in json) {
            if (k) projects.push(k);
        }
        projects.sort();
        obj.innerHTML = "";
        if (projects.length == 0) {
            obj.innerHTML = "You do not seem to have access to any repositories. Please make sure you are in the correct LDAP groups!";
        }
        else {
            for (var i in projects) {
                var project = projects[i];
                var list = json[project];
                list.sort();
                var li = "<li><b>" + project + ":\n<ul>";
                if (list.length > 0) {
                    for (var r in list) {
                        var repo = list[r];
                        li += "<li><a href='https://github.com/apache/" + repo + "'>" + repo + "</a></li>";
                    }
                } else {
                    li += "<li><i>No repositories for the " + project + " project served from gitbox yet...</i></li>";
                }
                li += "</ul></li>";
                obj.innerHTML += li;
            }
        }
    } else {
        obj.innerHTML += "<li>Something went wrong :( Please try again in a few minutes.";
    }
    
}

function renderPage(json) {
    // logged in via ASF?
    
    
    // Step 1: ASF Auth
    var obj = document.getElementById('asfauth');
    if (json && json.asfid && json.name) {
        var fname = json.name.split(" ")[0];
        obj.innerHTML = "<h3 style='color: green;'>Authed</h3>";
        obj.innerHTML += "<big>Welcome back, " + fname + "!</big><br/>";
        obj.innerHTML += "<small style='color: #269;'><i>Not " + fname + "? <a href='oauth.cgi?logout=true'>Log out</a> then!</i></small><br/>";
        obj.setAttribute("class", "tc_good tc");
    } else {
        obj.innerHTML = "<h3 style='color: orange;'>Not authed yet</h3>Start off by logging in with Apache OAuth to begin your account merge process.<br/><a href='oauth.cgi?redirect=apache' class='btn'>Start ASF Oauth</a>";
    }
    
    // Step 2: GitHub Auth
    var extra = "";
    obj = document.getElementById('github');
    if (json && json.githubid) {
        obj.innerHTML = "<h3 style='color: green;'>Authed</h3>";
        obj.innerHTML += "<p>You are currently authed as <kbd>" + json.githubid + "</kbd> on GitHub. (not the right account? <a href='oauth.cgi?unauth=github'>Reset your GitHub info then</a>.)";
        obj.setAttribute("class", "tc_good tc");
        if (document.location.search.length > 1) {
            var m = document.location.search.match(/user=([-.a-z0-9]+)/i);
            if (m) {
                extra = "?user=" + m[1];
                obj.innerHTML += "<i>Debug: matching against availid <kbd>" + m[1] + "</kbd>.</i><br/>";
            }
        }
    } else if (json.asfid) {
        obj.innerHTML = "<h3 style='color: orange;'>Not authed yet</h3>";
        obj.innerHTML += "<br/>Just two steps to go! Please Log in with your GitHub account to complete your merge application and see which repositories you have access to.<br/><a href='oauth.cgi?redirect=github' class='btn'>Auth on GitHub</a>";
    }
    
    // Step 3: MFA
    obj = document.getElementById('mfa');

    if (json && json.githubid) {
        var mfa = json.mfa;
        var t = "User not a member of the ASF GitHub organisation. Please make sure you are a part of the ASF Organisation on GitHub and have 2FA enabled. Visit <a href='https://id.apache.org/'>id.apache.org</a> and set your GitHub ID to be invited to the org.";
        var s = "???";
        if (mfa  === true) {
            t = "<b style='color: green;'>MFA ENABLED</b>";
            s = "Write access granted";
            obj.setAttribute("class", "tc_good tc");
            wa = true;
        } else if (mfa === false) {
            s = "Write access suspended. Please make sure you are a part of the ASF Organisation on GitHub and have 2FA enabled. Visit <a href='https://id.apache.org/'>id.apache.org</a> and set your GitHub ID to be invited to the org. Please allow 15 minutes for your MFA status to propagate.";
            t = "<b style='color: red;'>MFA DISABLED</b>";
            obj.setAttribute("class", "tc_bad tc");
        }
        obj.innerHTML += "<h3>" + t + "</h3>" + s;
        
        
        obj = document.getElementById('bread');
        if (wa) {
            obj.innerHTML += "<p>According to LDAP, you will have access to the following repositories:</p>";
            obj.innerHTML += "<ul id='repolist'><li>Loading repository list, hang on..!</li></ul>";
            GetAsync("oauth.cgi?repos=true", null, renderRepos);
            
            
        } else {
            obj.innerHTML += "<p>You will need to enable multi-factor authentication before you can continue.<br/>See <a style='color: #FFF;' href='https://github.com/blog/1614-two-factor-authentication'>this page for more information</a>.</p>";
        }
    }
}

function loadUserData() {
    GetAsync("oauth.cgi?load=true", null, renderPage);
}

// Check for slow URLs every 0.5 seconds
window.setInterval(checkForSlows, 500);
