# Adding a Project to a Slave

Choice A:

1. Create a Jira Ticket on Infra Issue Tracker - component Buildbot.

Choice B.

1. Copy template.conf to $projectname.conf and follow comments
2. svn add $projectname.conf
3. Add your entry to the bottom of the list in projects.conf (Include the builder number you used)
4. Commit to SVN, with luck in 5 minutes your project will appear on http://ci.apache.org
5. Add your projects path entry to infrastructure/trunk/subversion/hooks/buildbot_project_paths file
6. Inform builds@apache.org who will enable it for commits to trigger a build.

