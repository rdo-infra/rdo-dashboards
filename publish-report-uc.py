#!/usr/bin/env python
import requests
import importlib
import json

report = importlib.import_module('report-uc')
repos_url = ['https://trunk.rdoproject.org/centos8-master/current/delorean.repo',
             'https://trunk.rdoproject.org/centos8-master/delorean-deps.repo']

rows = []
filtered_uc = {}
for uc in report.provides_uc('master', 'centos8', repos_url, [], None,
                             '', 'cbs'):
    try:
        if uc.pkg_name == '':
            continue
        if uc.pkg_version > filtered_uc[uc.pkg_name]:
            filtered_uc[uc.pkg_name] = uc
    except:
        filtered_uc[uc.pkg_name] = uc

for uc in filtered_uc.values():
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

postdata={"auth_token": "YOUR_AUTH_TOKEN", "hrows": hrows, "rows": rows}
json_payload=json.dumps(postdata)
headers = {'content-type': 'application/json'}
r=requests.post('http://localhost:3030/widgets/report-uc',
                data=json_payload,
                headers=headers)
print("POST status code: %s" % r.status_code)
