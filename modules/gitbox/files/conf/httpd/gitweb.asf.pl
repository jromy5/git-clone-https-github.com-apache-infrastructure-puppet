our $projectroot = "/x1/repos/asf";
our $site_name = "ASF Git Repos";
our $site_header = "<h1>ASF Git Repos</h1>";

# Fix URLs for static assests to simplify the
# httpd configuration.
our @stylesheets = ("/static/gitweb.css");
our $logo = "/static/git-logo.png";
our $favicon = "/static/git-favicon.png";
our $javascript = "/static/gitweb.js";
$feature{'avatar'}{'default'} = ['gravatar'];
$feature{'highlight'}{'default'} = [1];
