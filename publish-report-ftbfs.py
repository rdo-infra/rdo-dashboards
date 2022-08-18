#!/usr/bin/env python
import csv
import json
import requests
import sys

try:
    report_file = sys.argv[1]
except IndexError:
    print("{}: Error: report file not provided.".format(sys.argv[2]))
    sys.exit(1)

try:
    token = sys.argv[2]
except IndexError:
    print("{}: Error: token not provided".format(sys.argv[2]))
    sys.exit(1)

try:
    with open(report_file, 'r') as report:
        csv_reader = csv.reader(report)
        listReport = list(csv_reader)
except OSError:
    print("{}: Report file not exists or can't be opened.")
    sys.exit(1)

rows = []

for data in listReport[1:]:
    _row = {}
    _row["cols"] = []
    for field in data:
        if field.endswith("rpmbuild.log"):
            field = "<a href='{0}'>rpmbuild.log</a>".format(field)
        if field.startswith("https://"):
            field = "<a href='{0}'>{0}</a>".format(field)
        _row["cols"].append({"value": field})
    rows.append(_row)

hrows = [{"cols": [{"value": 'Project'},
                   {"value": 'Component'},
                   {"value": 'Status'},
                   {"value": 'Release'},
                   {"value": 'Review'},
                   {"value": 'Logs'},
                   {"value": 'Date of FTBFS'}
                   ]}]

postdata = {"auth_token": token, "hrows": hrows, "rows": rows}
json_payload = json.dumps(postdata)
headers = {'content-type': 'application/json'}

r = requests.post('http://localhost:3030/widgets/report-ftbfs',
                  data=json_payload,
                  headers=headers)
print("POST status code: %s" % r.status_code)
