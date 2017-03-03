#!/bin/bash
#
# Copyright (C) 2016-2017 Red Hat, Inc.
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

DIR=$(cd $(dirname $0); pwd)

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
TRIPLEO_ISSUES=https://trello.com/b/WXJTwsuU/tripleo-and-rdo-ci-status
RDO_URL=http://trunk.rdoproject.org/centos7/current-passed-ci/versions.csv
MTK_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-mitaka/consistent/versions.csv
MTK_TRIPLEO_URL=http://trunk.rdoproject.org/centos7-mitaka/current-tripleo/versions.csv
MTK_RDO_URL=http://trunk.rdoproject.org/centos7-mitaka/current-passed-ci/versions.csv
NWTN_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-newton/consistent/versions.csv
NWTN_TRIPLEO_URL=http://trunk.rdoproject.org/centos7-newton/current-tripleo/versions.csv
NWTN_RDO_URL=http://trunk.rdoproject.org/centos7-newton/current-passed-ci/versions.csv
OCAT_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-ocata/consistent/versions.csv
OCAT_RDO_URL=http://trunk.rdoproject.org/centos7-ocata/current-tripleo-rdo/versions.csv
OCAT_TRIPLEO_URL=https://trunk.rdoproject.org/centos7-ocata/current-tripleo/versions.csv
PERIODIC_CGI=http://tripleo.org/cgi-bin/cistatus-periodic.cgi

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
        if [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -gt "$ts" ]]; then
            ts=$val
        fi
    done

    if [ $ts != 0 ]; then
        days=$(( ( $now - $ts ) / (24 * 3600) ))
        send_to_dashboard $widget $days "$extra"

        echo "$url -> $days" 1>&2
    else
        send_to_dashboard $widget 1000 "$extra"

        echo "$url -> never" 1>&2
    fi
}

process_issues() {
    url="$1"
    tag="$2"
    issues_url="$3"
    shift 3

    case $issues_url in
        *trello.com*)
            issues=$($DIR/count-trello-cards.py "$@")
            ;;
        *)
            issues=$(curl -s "$issues_url/export/txt" | egrep '^[0-9]+\.' | grep -Fvi '[fixed]' | wc -l)
            ;;
    esac

    if [ $issues -gt 0 ]; then
        echo "$issues issues"
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

process_issues $TRIPLEO_URL tripleopin $TRIPLEO_ISSUES WXJTwsuU 'TripleoCI Promotion blocker+master' 'Critical CI Outage' 'CI Failing Jobs'

process_issues $OCAT_TRIPLEO_URL tripleopin-ocata $TRIPLEO_ISSUES WXJTwsuU 'TripleoCI Promotion blocker+stable branch: ocata' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $NWTN_TRIPLEO_URL tripleopin-newton $TRIPLEO_ISSUES WXJTwsuU 'TripleoCI Promotion blocker+stable branch: newton' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $MTK_TRIPLEO_URL tripleopin-mitaka $TRIPLEO_ISSUES WXJTwsuU 'TripleoCI Promotion blocker+stable branch: mitaka' 'Critical CI Outage' 'CI Failing Jobs'

#get_max_ts $MTK_TRIPLEO_URL tripleopinmitaka

# process delorean

get_max_ts $CONSISTENT_URL delorean
get_max_ts $MTK_CONSISTENT_URL deloreanmitaka
get_max_ts $NWTN_CONSISTENT_URL deloreannewton
get_max_ts $OCAT_CONSISTENT_URL deloreanocata

# process the deloreanci

process_issues $RDO_URL deloreanci "$TRIPLEO_ISSUES?menu=filter&filter=label:master,label:RDO CI Promotion blocker" WXJTwsuU 'RDO CI Promotion blocker+master' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $MTK_RDO_URL deloreancimitaka "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A mitaka,label:RDO CI Promotion blocker" WXJTwsuU 'RDO CI Promotion blocker+stable branch: mitaka' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $NWTN_RDO_URL deloreancinewton "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A newton,label:RDO CI Promotion blocker" WXJTwsuU 'RDO CI Promotion blocker+stable branch: newton' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $OCAT_RDO_URL deloreanciocata "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A ocata,label:RDO CI Promotion blocker" WXJTwsuU 'RDO CI Promotion blocker+stable branch: ocata' 'Critical CI Outage' 'CI Failing Jobs'

# feed-dashboard.sh ends here
