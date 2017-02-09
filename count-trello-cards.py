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

'''
'''

import json
import requests
import sys


def get_lists(board_id):
    r = requests.get('https://api.trello.com/1/boards/%s/lists/' % board_id)
    return json.loads(r.text)


def get_cards(list_id):
    r = requests.get('https://api.trello.com/1/lists/%s/cards/' % list_id)
    return json.loads(r.text)


def main(argv):
    if len(argv) == 1:
        print('Usage: %s <board name> <list name> [<list name>...]' % argv[0])
        sys.exit(1)

    lists = get_lists(argv[1])
    sum = 0
    for list_json in lists:
        if list_json['name'] in argv[2:]:
            sum += len(get_cards(list_json['id']))
    print sum


if __name__ == "__main__":
    main(sys.argv)

# count-trello-cards.py ends here
