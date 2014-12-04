#!/bin/sh

# This script ensures that the assignee for issues in a Bugzilla database are
# set to the default assignee for the component. This is important as at the
# ASF the default assignee is always the mailing list. The assignee is read-only
# but there are circumstances (promotion to TLP, moving bugs between projects)
# where the assignee needs to change but isn't always.
#
# This script assumes that the user running it has an appropriate .my.cnf file
# configured for passwordless login and that the user has the necessary
# permissions to modify the database

# Select DBs to fix
DBSELECT="bugs"

# Binaries
MYSQL=/usr/local/bin/mysql

# Process each mysql database in turn, setting the assignee
for DB in ${DBSELECT}
 do
   cat << EOF | $MYSQL $DB
   update bugs,components set bugs.assigned_to=components.initialowner where bugs.component_id=components.id;
EOF
 done
