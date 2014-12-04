#!/bin/bash -eu
# Generates a Jelly script to delete Jira users that have never created an issue
# and are not currently assigned an issue

PSQL=/usr/local/bin/psql
DB=jira-4.2.4-main

echo '<JiraJelly xmlns:jira="jelly:com.atlassian.jira.jelly.JiraTagLib">'

$PSQL $DB -tAc "select '<jira:RemoveUser name=\"' || username || '\"/>' from (userbase as u left join (select reporter from jiraissue group by reporter) as r on u.username=r.reporter) left join (select assignee from jiraIssue group by assignee) as a on u.username=a.assignee where r.reporter is null and a.assignee is null;"

echo '</JiraJelly>'

