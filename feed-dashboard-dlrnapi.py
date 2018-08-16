#!/usr/bin/env python

#
# Copyright (C) 2017 Red Hat, Inc.
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

#
# REQUIRED: pip install -r requirements-dlrnapi-get-promotions.txt
#
# https://github.com/softwarefactory-project/dlrnapi_client#getting-started
#
from __future__ import print_function
import argparse
import os
from datetime import datetime
import time
from pprint import pprint
import json
import requests
from urllib import urlopen

import dlrnapi_client
from dlrnapi_client.rest import ApiException

##################################################

parser = argparse.ArgumentParser(description="display promotion status for RDO releases.  Pike is the default release.",
                                 formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=25,width=180))

parser.add_argument("-d", "--dashboard", help='default to http://localhost:3030, useful for testing')
parser.add_argument("-v", "--verbose")

args = parser.parse_args()

if not args.dashboard:
    args.dashboard = 'http://localhost:3030'

##################################################


#
# TODO: Propose API change.  This should not be something clients of dlrnapi need to codify.  It's beyond fragile.
#
def get_url_from_commit_distro(commit, distro, base_url):
    if base_url[-1] != '/':
        base_url += '/'
    return (base_url + commit[0:2] + '/' + commit[2:4] + '/' + commit + '_' + distro[:8])

def get_shorthash_from_commit_distro(commit, distro):
    return (commit + '_' + distro[:8])


#
#
#
map_version_to_endpoint = {'master'  : 'https://trunk.rdoproject.org/api-centos-master-uc',
                           'rocky'  : 'https://trunk.rdoproject.org/api-centos-rocky',
                           'queens'  : 'https://trunk.rdoproject.org/api-centos-queens',
                           'pike'    : 'https://trunk.rdoproject.org/api-centos-pike',
                           'ocata'   : 'https://trunk.rdoproject.org/api-centos-ocata'}

def get_endpoint(release):
    return map_version_to_endpoint[release]

# Promotext widgets that contain the most recent promoted url
def get_promotext_widget_url(dashurl, release, promote_name):

    map_name_to_widget = {'current-tripleo'              : 'promotext_%s_ooo'  % release,
                          'current-tripleo-rdo'          : 'promotext_%s_rdo1' % release,
                          'current-tripleo-rdo-internal' : 'promotext_%s_rdo2' % release}

    widget = map_name_to_widget[promote_name]
    url = "%s/widgets/%s" % (dashurl, widget)
    return url

# Promolist widget
def get_promoactivity_widget_url(dashurl, release):

    widget = 'promolist_%s_all' % release
    url = "%s/widgets/%s" % (dashurl, widget)
    return url

#
def get_promotions(release, promote_name):

    host = get_endpoint(release)

    api_client = dlrnapi_client.ApiClient(host=host)
    api_instance = dlrnapi_client.DefaultApi(api_client=api_client)
    params = dlrnapi_client.PromotionQuery()

    if promote_name:
        params.promote_name = promote_name

    try:
        api_response = api_instance.api_promotions_get(params)

    except ApiException as e:
        print("Exception when calling DefaultApi->api_promotions_get: %s\n" % e)

    return api_response

#
def update_dashboard_promotion_tile(dashurl, release, promote_name):

    api_response = get_promotions(release, promote_name)

    if api_response:
        # first in the list is most recent
        promo = api_response[0]

        promote_ts = datetime.fromtimestamp(promo.timestamp)

        # RFE: Propose API change.  This is also needlessly forcing clients of the API to understand RDO infra.
        dlrn_base_url = "https://trunk.rdoproject.org/centos7-%s" % release
        delorean_url = get_url_from_commit_distro(promo.commit_hash, promo.distro_hash, dlrn_base_url)
        hash_id = get_shorthash_from_commit_distro(promo.commit_hash, promo.distro_hash)

        widget_url = get_promotext_widget_url(dashurl, release, promote_name)

        # fetch the timestamp of the delorean.repo file (when this repo was last touched by delorean)
        # if things don't get promoted in a while, this could be missing!
        f=urlopen('%s/delorean.repo' % delorean_url)
        i = f.info()

        lastmod_ts_str = "MISSING"

        if f.getcode() == 200:
            lastmod = i.getdate('last-modified')
            lastmod_ts = datetime.fromtimestamp(time.mktime(lastmod))
            lastmod_ts_str = lastmod_ts.strftime("%Y-%m-%d %H:%M")

        # TODO: pull out auth token in a better way
        postdata = { "auth_token": "YOUR_AUTH_TOKEN",
                     "hash_id": hash_id,
                     "delorean_url": delorean_url,
                     "promote_ts": promote_ts.strftime("%Y-%m-%d %H:%M"),
                     "lastmod_ts": lastmod_ts_str}

        json_payload = json.dumps(postdata)

        r = requests.post(widget_url, data = json_payload)

        pprint('*** UPDATE %s' % widget_url)
        pprint(postdata)
        pprint('*** RETURN')
        pprint(vars(r))

#
def update_dashboard_promotion_activity(dashurl, release):

    # no promote _name --> all activity
    api_response = get_promotions(release, None)

    items = list()


    for promo in api_response:

        # for now filter these out
        if promo.promote_name == 'tripleo-ci-testing':
            continue

        if len(items) > 30:
            break

        ts = datetime.fromtimestamp(promo.timestamp)

        # RFE: Propose API change.  This is also needlessly forcing clients of the API to understand RDO infra.
        dlrn_base_url = "https://trunk.rdoproject.org/centos7-%s" % release
        delorean_url = get_url_from_commit_distro(promo.commit_hash, promo.distro_hash, dlrn_base_url)
        hash_id = get_shorthash_from_commit_distro(promo.commit_hash, promo.distro_hash)

        # TODO: pass thru delorean_url and make a link within the <li>

        #  ts: val,  ts := "2017-05-04 09:00",  val := "01234567 (current-tripleo-rdo-internal)"
        item = { "label": ts.strftime("%Y-%m-%d %H:%M"), "value": '%s %s' % (promo.promote_name, hash_id)}

        items.append(item)

    # TODO: pull out auth token in a better way
    postdata = {"auth_token": "YOUR_AUTH_TOKEN",
                "items": items}

    widget_url = get_promoactivity_widget_url(dashurl, release)
    json_payload = json.dumps(postdata)

    r = requests.post(widget_url, data=json_payload)

    pprint('*** UPDATE %s' % widget_url)
    pprint(postdata)
    pprint('*** RETURN')
    pprint(vars(r))

###

def update_dashboard(dashboard, release):
    update_dashboard_promotion_tile(dashboard, release, 'current-tripleo')
    update_dashboard_promotion_tile(dashboard, release, 'current-tripleo-rdo')
    update_dashboard_promotion_tile(dashboard, release, 'current-tripleo-rdo-internal')

    update_dashboard_promotion_activity(dashboard, release)

#####
# update dashboards from delorean api
#####
update_dashboard(args.dashboard, 'master')
update_dashboard(args.dashboard, 'queens')
update_dashboard(args.dashboard, 'pike')
update_dashboard(args.dashboard, 'ocata')
