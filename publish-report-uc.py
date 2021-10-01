#!/usr/bin/env python
import requests
import importlib
import json
import yaml
import sys

try:
    token = sys.argv[1]
except IndexError:
    print("{}: Error: token not provided".format(sys.argv[0]))
    sys.exit(1)

try:
    distro = sys.argv[2]
except IndexError:
    print("{}: Error: distro not provided".format(sys.argv[0]))
    sys.exit(1)

with open('report-uc-data.yml', 'r') as file:
    report_uc_data = yaml.safe_load(file)

report = importlib.import_module('report-uc')

rows = []
for uc in report.provides_uc('master', distro,
                             report_uc_data[distro]['repos_url'],
                             report_uc_data[distro]['repos'],
                             None, '', 'cbs', ''):
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
r=requests.post('http://localhost:3030/widgets/{}'.format(
                report_uc_data[distro]['url_path']),
                data=json_payload,
                headers=headers)
print("POST status code: %s" % r.status_code)
