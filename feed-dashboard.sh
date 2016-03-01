#!/bin/bash
#
# Copyright (C) 2016 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

set -e

if [ $# != 2 ]; then
    echo "Usage: $0 <dashboard url> <token>" 1>&2
    exit 1
fi

WIDGETS_URL="$1/widgets"
TOKEN="$2"

CURRENT_URL=http://trunk.rdoproject.org/centos7/current/versions.csv
CONSISTENT_URL=http://trunk.rdoproject.org/centos7/consistent/versions.csv
CURRENT_URL=http://trunk.rdoproject.org/centos7/current-tripleo/versions.csv
PERIODIC_CGI=http://tripleo.org/cgi-bin/cistatus-periodic.cgi

send_to_dashboard() {
    curl -s -d "{ \"auth_token\": \"$TOKEN\", \"value\": $2 }" $WIDGETS_URL/$1
}

min=$(date '+%s')
now=$min

# process tripleoci

ts=$(curl -s $PERIODIC_CGI|grep ^periodic-tripleo-ci-f22-ha,|grep -F SUCCESS|cut -d, -f2)
if [ -z "$ts"]; then
    ts=$(python -c 'import datetime as dt;print (dt.datetime.strptime("2016-01-06", "%Y-%m-%d")- dt.datetime(1970,1,1)).total_seconds()'|sed 's/\.0//')
fi
days=$(( ( $now - $ts ) / (24 * 3600) ))
send_to_dashboard tripleoci $days

# process tripleopin

# TBD use the date from the first line of
# http://trunk.rdoproject.org/centos7/current-tripleo/versions.csv
ts=$(python -c 'import datetime as dt;print (dt.datetime.strptime("2016-02-23 18:44", "%Y-%m-%d %H:%M")- dt.datetime(1970,1,1)).total_seconds()'|sed 's/\.0//')
days=$(( ( $now - $ts ) / (24 * 3600) ))
send_to_dashboard tripleopin $days

# process delorean

ts=$(curl -s $CONSISTENT_URL|head -2|tail -1|cut -d, -f7)

days=$(( ( $now - $ts ) / (24 * 3600) ))
send_to_dashboard delorean $days

# process the deloreanci

max=0

# TBD use the date from the first line of
# http://trunk.rdoproject.org/centos7/current-passed-ci/versions.csv

ts=$(python -c 'import datetime as dt;print (dt.datetime.strptime("2016-02-23 18:44", "%Y-%m-%d %H:%M")- dt.datetime(1970,1,1)).total_seconds()'|sed 's/\.0//')
days=$(( ( $now - $ts ) / (24 * 3600) ))
send_to_dashboard deloreanci $days

# feed-dashboard.sh ends here
