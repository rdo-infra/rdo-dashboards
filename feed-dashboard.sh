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

PUPPET_URL=https://raw.githubusercontent.com/openstack/puppet-openstack-integration/master/manifests/repos.pp
CURRENT_URL=http://trunk.rdoproject.org/centos7/current/versions.csv
CONSISTENT_URL=http://trunk.rdoproject.org/centos7/consistent/versions.csv
TRIPLEO_URL=http://trunk.rdoproject.org/centos7/current-tripleo/versions.csv
RDO_URL=http://trunk.rdoproject.org/centos7/current-passed-ci/versions.csv
MTK_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-mitaka/consistent/versions.csv
MTK_TRIPLEO_URL=http://trunk.rdoproject.org/centos7-mitaka/current-tripleo/versions.csv
MTK_RDO_URL=http://trunk.rdoproject.org/centos7-mitaka/current-passed-ci/versions.csv
PERIODIC_CGI=http://tripleo.org/cgi-bin/cistatus-periodic.cgi
ISSUES_URL=https://etherpad.openstack.org/p/delorean_master_current_issues

send_to_dashboard() {
    curl -s -d "{ \"auth_token\": \"$TOKEN\", \"value\": $2 $3 }" $WIDGETS_URL/$1
}

get_max_ts() {
    url=$1
    widget=$2
    extra="$3"
    ts=0
    for line in $(curl -s $url); do
        val="$(echo $line|cut -d, -f7)"
        if [[ "$val" != 'Last Success Timestamp' ]] && [[ "$val" -gt "$ts" ]]; then
            ts=$val
        fi
    done
    
    days=$(( ( $now - $ts ) / (24 * 3600) ))
    send_to_dashboard $widget $days "$extra"
}

min=$(date '+%s')
now=$min

# process puppetci
PUPPET_REPO_URL=$(curl -s $PUPPET_URL|egrep '(/trunk|delorean/)'|sed -e "s/.* => '\(.*\)'.*/\1/")

get_max_ts $PUPPET_REPO_URL/versions.csv puppetci

# process tripleoci

ts=$(curl -s $PERIODIC_CGI|grep ^periodic-tripleo-ci-f22-ha,|grep -F SUCCESS|cut -d, -f2)
days=$(( ( $now - $ts ) / (24 * 3600) ))
send_to_dashboard tripleoci $days

# process tripleopin

get_max_ts $TRIPLEO_URL tripleopin
#get_max_ts $MTK_TRIPLEO_URL tripleopinmitaka

# process delorean

get_max_ts $CONSISTENT_URL delorean
get_max_ts $MTK_CONSISTENT_URL deloreanmitaka

# process the deloreanci

issues=$(curl -s $ISSUES_URL/export/txt | egrep '^[0-9]+\.' | grep -Fvi '[fixed]' | wc -l)

if [ $issues -gt 0 ]; then
    if [ $issues -eq 1 ]; then
        extra=", \"moreinfo\": \"$issues issue\", \"link\": \"$ISSUES_URL\""
    else
        extra=", \"moreinfo\": \"$issues issues\", \"link\": \"$ISSUES_URL\""
    fi
else
    extra=
fi

get_max_ts $RDO_URL deloreanci "$extra"
get_max_ts $MTK_RDO_URL deloreancimitaka

# feed-dashboard.sh ends here
