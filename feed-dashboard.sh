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

CURRENT_URL=http://trunk.rdoproject.org/centos7/current/versions.csv
CONSISTENT_URL=http://trunk.rdoproject.org/centos7/consistent/versions.csv
TRIPLEO_URL=http://trunk.rdoproject.org/centos7/current-tripleo/versions.csv
TRIPLEO_ISSUES=https://trello.com/b/U1ITy0cu/tripleo-and-rdo-ci
RDO_URL=http://trunk.rdoproject.org/centos7/current-passed-ci/versions.csv
QUEENS_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-queens/consistent/versions.csv
QUEENS_RDO_URL=http://trunk.rdoproject.org/centos7-queens/current-tripleo-rdo/versions.csv
QUEENS_TRIPLEO_URL=https://trunk.rdoproject.org/centos7-queens/current-tripleo/versions.csv
ROCKY_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-rocky/consistent/versions.csv
ROCKY_RDO_URL=http://trunk.rdoproject.org/centos7-rocky/current-tripleo-rdo/versions.csv
ROCKY_TRIPLEO_URL=https://trunk.rdoproject.org/centos7-rocky/current-tripleo/versions.csv
STEIN_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-stein/consistent/versions.csv
STEIN_RDO_URL=http://trunk.rdoproject.org/centos7-stein/current-tripleo-rdo/versions.csv
STEIN_TRIPLEO_URL=https://trunk.rdoproject.org/centos7-stein/current-tripleo/versions.csv
TRAIN_CONSISTENT_URL=http://trunk.rdoproject.org/centos7-train/consistent/versions.csv
TRAIN_RDO_URL=http://trunk.rdoproject.org/centos7-train/current-tripleo-rdo/versions.csv
TRAIN_TRIPLEO_URL=https://trunk.rdoproject.org/centos7-train/current-tripleo/versions.csv
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
get_max_ts https://trunk.rdoproject.org/centos7-master/puppet-passed-ci/versions.csv puppetci

# process tripleoci

# ts=$(curl -s $PERIODIC_CGI|grep ^periodic-tripleo-ci-f22-ha,|grep -F SUCCESS|cut -d, -f2)
# days=$(( ( $now - $ts ) / (24 * 3600) ))
# send_to_dashboard tripleoci $days

# process tripleopin

process_issues $TRIPLEO_URL tripleopin $TRIPLEO_ISSUES U1ITy0cu 'TripleoCI Promotion blocker+master' 'Critical CI Outage' 'CI Failing Jobs'

process_issues $QUEENS_TRIPLEO_URL tripleopin-queens $TRIPLEO_ISSUES U1ITy0cu 'TripleoCI Promotion blocker+stable branch: queens' 'Critical CI Outage' 'CI Failing Jobs'

process_issues $ROCKY_TRIPLEO_URL tripleopin-rocky $TRIPLEO_ISSUES U1ITy0cu 'TripleoCI Promotion blocker+stable branch: rocky' 'Critical CI Outage' 'CI Failing Jobs'

process_issues $STEIN_TRIPLEO_URL tripleopin-stein $TRIPLEO_ISSUES U1ITy0cu 'TripleoCI Promotion blocker+stable branch: stein' 'Critical CI Outage' 'CI Failing Jobs'

process_issues $TRAIN_TRIPLEO_URL tripleopin-train $TRIPLEO_ISSUES U1ITy0cu 'TripleoCI Promotion blocker+stable branch: train' 'Critical CI Outage' 'CI Failing Jobs'

# process delorean

get_max_ts $CONSISTENT_URL delorean
get_max_ts $QUEENS_CONSISTENT_URL deloreanqueens
get_max_ts $ROCKY_CONSISTENT_URL deloreanrocky
get_max_ts $STEIN_CONSISTENT_URL deloreanstein
get_max_ts $TRAIN_CONSISTENT_URL deloreantrain

# process the deloreanci

process_issues $RDO_URL deloreanci "$TRIPLEO_ISSUES?menu=filter&filter=label:master,label:RDO CI Promotion blocker" U1ITy0cu 'RDO CI Promotion blocker+master' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $QUEENS_RDO_URL deloreanciqueens "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A queens,label:RDO CI Promotion blocker" U1ITy0cu 'RDO CI Promotion blocker+stable branch: queens' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $ROCKY_RDO_URL deloreancirocky "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A rocky,label:RDO CI Promotion blocker" U1ITy0cu 'RDO CI Promotion blocker+stable branch: rocky' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $STEIN_RDO_URL deloreancistein "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A stein,label:RDO CI Promotion blocker" U1ITy0cu 'RDO CI Promotion blocker+stable branch: stein' 'Critical CI Outage' 'CI Failing Jobs'
process_issues $TRAIN_RDO_URL deloreancitrain "$TRIPLEO_ISSUES?menu=filter&filter=label:stable branch%3A train,label:RDO CI Promotion blocker" U1ITy0cu 'RDO CI Promotion blocker+stable branch: train' 'Critical CI Outage' 'CI Failing Jobs'

# feed-dashboard.sh ends here
