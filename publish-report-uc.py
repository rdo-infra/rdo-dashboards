#!/usr/bin/env python
import requests
import importlib
import json

report = importlib.import_module('report-uc')
repos_url = ['https://trunk.rdoproject.org/centos8-master/current/delorean.repo',
             'https://trunk.rdoproject.org/centos8-master/delorean-deps.repo']

repos = ['BaseOS,http://mirror.regionone.rdo-cloud.rdoproject.org/centos/8/BaseOS/x86_64/os/',
         'AppStream,http://mirror.regionone.rdo-cloud.rdoproject.org/centos/8/AppStream/x86_64/os/',
         'extras,http://mirror.regionone.rdo-cloud.rdoproject.org/centos/8/extras/x86_64/os/',
         'PowerTools,http://mirror.regionone.rdo-cloud.rdoproject.org/centos/8/PowerTools/x86_64/os/']

rows = []
for uc in report.provides_uc('master', 'centos8', repos_url, repos, None,
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

postdata={"auth_token": "YOUR_AUTH_TOKEN", "hrows": hrows, "rows": rows}
json_payload=json.dumps(postdata)
headers = {'content-type': 'application/json'}
r=requests.post('http://localhost:3030/widgets/report-uc',
                data=json_payload,
                headers=headers)
print("POST status code: %s" % r.status_code)
