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

/*
  To create (if not exists) this db, run:
  $ sqlite3 dbname.db
  > .read create.sql
*/

-- ASF <-> GitHub ID lookup DB
CREATE TABLE IF NOT EXISTS ids(
    asfid VARCHAR(64) PRIMARY KEY UNIQUE NOT NULL, -- ASF ID
    githubid VARCHAR(64) UNIQUE NOT NULL,          -- GitHub ID
    mfa BOOLEAN NOT NULL default '0',              -- MFA Enabled?
    updated DATETIME NOT NULL                      -- Last change time
);

-- Pushlog DB
CREATE TABLE IF NOT EXISTS pushlog(
    id INTEGER PRIMARY KEY AUTOINCREMENT,  -- Just an ID, bleh
    repository VARCHAR(100) NOT NULL,      -- repository name (sans .git)
    old CHARACTER(40) NOT NULL,            -- Previous revision
    new CHARACTER(40) NOT NULL,            -- New (current revision)
    ref VARCHAR(200) NOT NULL,             -- branch/tag name
    baseref VARCHAR(200),                  -- original branch/tag name if branching off. can be null.
    date DATETIME NOT NULL,                -- Time of push
    asfid VARCHAR(64) NOT NULL,            -- ASF ID of pusher
    githubid VARCHAR(64) -- this may change over time, so we keep a record
                         -- of it for each push.
);

-- Web UI session DB
CREATE TABLE IF NOT EXISTS sessions(
    cookie   VARCHAR(40),                               -- Web UI cookie
    asfid    VARCHAR(64) PRIMARY KEY UNIQUE NOT NULL,   -- ASF ID coupled to session
    githubid VARCHAR(64),                               -- GitHub ID of session
    asfname  VARCHAR(100)                               -- Display name
);

CREATE INDEX IF NOT EXISTS I_GITHUBID ON ids (githubid);
CREATE INDEX IF NOT EXISTS I_OLDREF ON pushlog (old);
CREATE INDEX IF NOT EXISTS I_NEWREF ON pushlog (new);
