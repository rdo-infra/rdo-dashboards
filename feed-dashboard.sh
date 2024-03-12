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

MASTER_C9_CURRENT_URL=http://trunk.rdoproject.org/centos9-master/current/delorean.repo
MASTER_C9_RDO_URL=http://trunk.rdoproject.org/centos9/puppet-passed-ci/versions.csv
WALLABY_C8_CURRENT_URL=http://trunk.rdoproject.org/centos8-wallaby/current/delorean.repo
WALLABY_C9_RDO_URL=http://trunk.rdoproject.org/centos9-wallaby/puppet-passed-ci/versions.csv
XENA_C8_CURRENT_URL=http://trunk.rdoproject.org/centos8-xena/current/delorean.repo
XENA_C9_RDO_URL=http://trunk.rdoproject.org/centos9-xena/puppet-passed-ci/versions.csv
YOGA_C9_CURRENT_URL=http://trunk.rdoproject.org/centos9-yoga/current/delorean.repo
YOGA_C9_RDO_URL=http://trunk.rdoproject.org/centos9-yoga/puppet-passed-ci/versions.csv
YOGA_C8_CURRENT_URL=http://trunk.rdoproject.org/centos8-yoga/current/delorean.repo
YOGA_C8_RDO_URL=http://trunk.rdoproject.org/centos8-yoga/puppet-passed-ci/versions.csv
ZED_C9_CURRENT_URL=http://trunk.rdoproject.org/centos9-zed/current/delorean.repo
ZED_C9_RDO_URL=http://trunk.rdoproject.org/centos9-zed/puppet-passed-ci/versions.csv
ANTELOPE_C9_CURRENT_URL=http://trunk.rdoproject.org/centos9-antelope/current/delorean.repo
ANTELOPE_C9_RDO_URL=http://trunk.rdoproject.org/centos9-antelope/puppet-passed-ci/versions.csv
BOBCAT_C9_CURRENT_URL=http://trunk.rdoproject.org/centos9-bobcat/current/delorean.repo
BOBCAT_C9_RDO_URL=http://trunk.rdoproject.org/centos9-bobcat/puppet-passed-ci/versions.csv

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
    for repo in $(curl -s -L $url |grep baseurl|sed 's/baseurl=//g')
    do
        component=$(echo $repo|awk -F "component/" '{print $2}'|awk -F '/' '{print $1}')
        ftbfs=$(get_ftbfs ${repo}/versions.csv)
        if [ $ftbfs -ne 0 ]; then
            val=$(get_days_first_failure ${repo}/versions.csv)
            if [[ "$val" =~ ^[0-9]+$ ]] && [[ "$val" -gt "$ts" ]]; then
                ts=$val
            fi
        fi
    done

    send_comps_to_dashboard $widget $ts
}

min=$(date '+%s')
now=$min

# process FTBFS

get_components_max_ts $MASTER_C9_CURRENT_URL deloreanmasterc9
get_components_max_ts $WALLABY_C8_CURRENT_URL deloreanwallaby
get_components_max_ts $XENA_C8_CURRENT_URL deloreanxena
get_components_max_ts $YOGA_C9_CURRENT_URL deloreanyogac9
get_components_max_ts $YOGA_C8_CURRENT_URL deloreanyogac8
get_components_max_ts $ZED_C9_CURRENT_URL deloreanzedc9
get_components_max_ts $ANTELOPE_C9_CURRENT_URL deloreanantelopec9
get_components_max_ts $BOBCAT_C9_CURRENT_URL deloreanbobcatc9

# process promotion CI

get_max_ts $MASTER_C9_RDO_URL deloreanci
get_max_ts $WALLABY_C9_RDO_URL deloreanciwallaby
get_max_ts $XENA_C9_RDO_URL deloreancixena
get_max_ts $YOGA_C9_RDO_URL deloreanciyoga
get_max_ts $ZED_C9_RDO_URL deloreancized
get_max_ts $ANTELOPE_C9_RDO_URL deloreanciantelope
get_max_ts $BOBCAT_C9_RDO_URL deloreancibobcat
# feed-dashboard.sh ends here
