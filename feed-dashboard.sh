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

if [ $# != 1 ]; then
    echo "Usage: $0 <dashboard url>" 1>&2
    exit 1
fi

WIDGETS_URL="$1/widgets"
TOKEN_FILE='/etc/rdo-dashboards.conf'
TOKEN=$(grep auth_token ${TOKEN_FILE} | cut -f2 -d:  | awk '{print $1}' | tr -d '"')

CURRENT_C9_URL=http://trunk.rdoproject.org/centos9-master/current/delorean.repo
CONSISTENT_URL=http://trunk.rdoproject.org/centos8/consistent/versions.csv
TRIPLEO_URL=http://trunk.rdoproject.org/centos8/current-tripleo/versions.csv
TRIPLEO_ISSUES=https://trello.com/b/U1ITy0cu/tripleo-and-rdo-ci
RDO_URL=http://trunk.rdoproject.org/centos8/current-passed-ci/versions.csv
TRAIN_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-train/consistent/versions.csv
TRAIN_RDO_URL=http://trunk.rdoproject.org/centos7-train/current-tripleo-rdo/versions.csv
TRAIN_TRIPLEO_URL=https://trunk.rdoproject.org/centos7-train/current-tripleo/versions.csv
VICTORIA_CURRENT_URL=http://trunk.rdoproject.org/centos8-victoria/current/delorean.repo
VICTORIA_RDO_URL=http://trunk.rdoproject.org/centos8-victoria/current-tripleo-rdo/versions.csv
VICTORIA_TRIPLEO_URL=https://trunk.rdoproject.org/centos8-victoria/current-tripleo/versions.csv
WALLABY_CURRENT_URL=http://trunk.rdoproject.org/centos8-wallaby/current/delorean.repo
WALLABY_RDO_URL=http://trunk.rdoproject.org/centos8-wallaby/current-tripleo-rdo/versions.csv
WALLABY_TRIPLEO_URL=https://trunk.rdoproject.org/centos8-wallaby/current-tripleo/versions.csv
XENA_CURRENT_URL=http://trunk.rdoproject.org/centos8-xena/current/delorean.repo
YOGA_C9_CURRENT_URL=http://trunk.rdoproject.org/centos9-yoga/current/delorean.repo
YOGA_C8_CURRENT_URL=http://trunk.rdoproject.org/centos8-yoga/current/delorean.repo
PERIODIC_CGI=http://tripleo.org/cgi-bin/cistatus-periodic.cgi

send_to_dashboard() {
    curl -s -d "{ \"auth_token\": \"$TOKEN\", \"value\": $2 $3 }" $WIDGETS_URL/$1
}


send_comps_to_dashboard() {
        curl -s -d "{ \"auth_token\": \"$TOKEN\", \"value\": $2 }" $WIDGETS_URL/$1
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

get_ftbfs() {
    url=$1
    FTBFS=$(curl -s -L $url |grep -c -v -e "^Project" -e SUCCESS)
    echo $FTBFS
}

get_days_first_failure() {
    url=$1
    ts=$now
    for line in $(curl -s -L $url | grep -v -e SUCCESS -e ^Project); do
        val="$(echo $line|cut -d, -f7)"
        if [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -lt "$ts" ]]; then
            ts=$val
        fi
    done

    if [ $ts != $now ]; then
        days=$(( ( $now - $ts ) / (24 * 3600) ))
        echo $days
    else
       echo 1000
    fi
}

get_components_max_ts() {
    url=$1
    widget=$2

    ts=0
    failed_comps=""
    for repo in $(curl -s -L $url |grep baseurl|sed 's/baseurl=//g')
    do
        component=$(echo $repo|awk -F "component/" '{print $2}'|awk -F '/' '{print $1}')
        ftbfs=$(get_ftbfs ${repo}/versions.csv)
        if [ $ftbfs -ne 0 ]; then
            val=$(get_days_first_failure ${repo}/versions.csv)
            if [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -gt "$ts" ]]; then
                ts=$val
            fi
            failed_comps="$failed_comps $component"
        fi
    done

    send_comps_to_dashboard $widget $ts "$failed_comps"
}

process_issues() {
    url="$1"
    tag="$2"
    issues_url="$3"
    shift 3

    case $issues_url in
        *trello.com*)
            issues=$($DIR/count-trello-cards.py "$@" 2>/dev/null)
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
get_max_ts https://trunk.rdoproject.org/centos8-master/puppet-passed-ci/versions.csv puppetci

# process tripleoci

# ts=$(curl -s $PERIODIC_CGI|grep ^periodic-tripleo-ci-f22-ha,|grep -F SUCCESS|cut -d, -f2)
# days=$(( ( $now - $ts ) / (24 * 3600) ))
# send_to_dashboard tripleoci $days

# process tripleopin

process_issues $TRIPLEO_URL tripleopin $TRIPLEO_ISSUES U1ITy0cu 'TripleoCI Promotion blocker+master' 'Critical CI Outage' 'CI Failing Jobs'

process_issues $TRAIN_TRIPLEO_URL tripleopin-train $TRIPLEO_ISSUES U1ITy0cu 'TripleoCI Promotion blocker+stable branch: train' 'Critical CI Outage' 'CI Failing Jobs'

process_issues $VICTORIA_TRIPLEO_URL tripleopin-victoria $TRIPLEO_ISSUES U1ITy0cu 'TripleoCI Promotion blocker+stable branch: victoria' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $WALLABY_TRIPLEO_URL tripleopin-wallaby $TRIPLEO_ISSUES U1ITy0cu 'TripleoCI Promotion blocker+stable branch: wallaby' 'Critical CI Outage' 'CI Failing Jobs'

# process delorean

get_components_max_ts $CURRENT_C9_URL deloreanmasterc9
get_components_max_ts $VICTORIA_CURRENT_URL deloreanvictoria
get_components_max_ts $WALLABY_CURRENT_URL deloreanwallaby
get_components_max_ts $XENA_CURRENT_URL deloreanxena
get_components_max_ts $YOGA_C9_CURRENT_URL deloreanyogac9
get_components_max_ts $YOGA_C8_CURRENT_URL deloreanyogac8
get_max_ts $TRAIN_CONSISTENT_URL deloreantrain

# process the deloreanci

process_issues $RDO_URL deloreanci "$TRIPLEO_ISSUES?menu=filter&filter=label:master,label:RDO CI Promotion blocker" U1ITy0cu 'RDO CI Promotion blocker+master' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $TRAIN_RDO_URL deloreancitrain "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A train,label:RDO CI Promotion blocker" U1ITy0cu 'RDO CI Promotion blocker+stable branch: train' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $VICTORIA_RDO_URL deloreancivictoria "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A victoria,label:RDO CI Promotion blocker" U1ITy0cu 'RDO CI Promotion blocker+stable branch: victoria' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $WALLABY_RDO_URL deloreanciwallaby "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A wallaby,label:RDO CI Promotion blocker" U1ITy0cu 'RDO CI Promotion blocker+stable branch: wallaby' 'Critical CI Outage' 'CI Failing Jobs'

# feed-dashboard.sh ends here

