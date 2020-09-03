#!/usr/bin/env python
import requests
import importlib
import json
import sys

try:
    token = sys.argv[1]
except IndexError:
    print("{}: Error: token not provided".format(sys.argv[0]))
    sys.exit(1)

report = importlib.import_module('report-uc')
repos_url = ['https://trunk.rdoproject.org/centos8-master/current/delorean.repo',
             'https://trunk.rdoproject.org/centos8-master/delorean-deps.repo']

rows = []
for uc in report.provides_uc('master', 'centos8', repos_url, [], None,
                             '', 'cbs'):
    if uc.pkg_name == '':
        continue
    _row = {}
    _row["cols"] = []
    for data in uc.to_list():
        _row["cols"].append({"value": data})
    rows.append(_row)

hrows = [{"cols":[{"value":'Release'},
                  {"value": 'ModName'},
                  {"value": 'ModVers'},
                  {"value": 'PkgName'},
                  {"value": 'PkgVers'},
                  {"value": 'Source'},
                  {"value": 'Status'}
                  ]}]

postdata={"auth_token": token, "hrows": hrows, "rows": rows}
json_payload=json.dumps(postdata)
headers = {'content-type': 'application/json'}
r=requests.post('http://localhost:3030/widgets/report-uc',
                data=json_payload,
                headers=headers)
print("POST status code: %s" % r.status_code)
