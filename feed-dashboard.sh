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
TRIPLEO_ISSUES=https://etherpad.openstack.org/p/tripleo-ci-status
RDO_URL=http://trunk.rdoproject.org/centos7/current-passed-ci/versions.csv
MTK_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-mitaka/consistent/versions.csv
MTK_TRIPLEO_URL=http://trunk.rdoproject.org/centos7-mitaka/current-tripleo/versions.csv
MTK_RDO_URL=http://trunk.rdoproject.org/centos7-mitaka/current-passed-ci/versions.csv
MTK_ISSUES_URL=https://etherpad.openstack.org/p/delorean_mitaka_current_issues
NWTN_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-newton/consistent/versions.csv
NWTN_TRIPLEO_URL=http://trunk.rdoproject.org/centos7-newton/current-tripleo/versions.csv
NWTN_RDO_URL=http://trunk.rdoproject.org/centos7-newton/current-passed-ci/versions.csv
NWTN_ISSUES_URL=https://etherpad.openstack.org/p/delorean_newton_current_issues
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
    for line in $(curl -s -L $url); do
        val="$(echo $line|cut -d, -f7)"
        if [[ "$val" != 'Last Success Timestamp' ]] && [[ "$val" -gt "$ts" ]]; then
            ts=$val
        fi
    done
    
    if [ $ts != 0 ]; then
        days=$(( ( $now - $ts ) / (24 * 3600) ))
        send_to_dashboard $widget $days "$extra"
    fi
}

process_issues() {
    url="$1"
    tag="$2"
    issues_url="$3"
    
    issues=$(curl -s "$issues_url/export/txt" | egrep '^[0-9]+\.' | grep -Fvi '[fixed]' | wc -l)

    if [ $issues -gt 0 ]; then
        if [ $issues -eq 1 ]; then
            extra=", \"moreinfo\": \"$issues issue\", \"link\": \"$issues_url\""
        else
            extra=", \"moreinfo\": \"$issues issues\", \"link\": \"$issues_url\""
        fi
    else
        extra=
    fi
    get_max_ts "$url" "$tag" "$extra"
}

min=$(date '+%s')
now=$min

# process puppetci
PUPPET_REPO_URL=$(curl -s $PUPPET_URL|egrep '(/trunk|delorean/)'|sed -e "s/.* => '\(.*\)'.*/\1/")

get_max_ts $PUPPET_REPO_URL/versions.csv puppetci

# process tripleoci

# ts=$(curl -s $PERIODIC_CGI|grep ^periodic-tripleo-ci-f22-ha,|grep -F SUCCESS|cut -d, -f2)
# days=$(( ( $now - $ts ) / (24 * 3600) ))
# send_to_dashboard tripleoci $days

# process tripleopin

process_issues $TRIPLEO_URL tripleopin $TRIPLEO_ISSUES
#get_max_ts $MTK_TRIPLEO_URL tripleopinmitaka

# process delorean

get_max_ts $CONSISTENT_URL delorean
get_max_ts $MTK_CONSISTENT_URL deloreanmitaka

set -x
get_max_ts $NWTN_CONSISTENT_URL deloreannewton
set +x

# process the deloreanci

process_issues $RDO_URL deloreanci $ISSUES_URL
process_issues $MTK_RDO_URL deloreancinewton $MTK_ISSUES_URL
process_issues $NWTN_RDO_URL deloreancinewton $NWTN_ISSUES_URL

# feed-dashboard.sh ends here
