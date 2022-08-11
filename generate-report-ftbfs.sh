#!/usr/bin/env bash

report_csv_file="$1"
releng_workdir="${HOME}/releng"
token_file="/etc/rdo-dashboards.conf"

echo ""
echo "*** obliterating and recreating virtualenv"
./setup-ftbfs-report-venv.sh

echo ""
echo "*** sourcing publish-report-ftbfs venv"
source .venv-ftbfs-report/bin/activate
python_version=$(python3 --version)
echo "python version: $python_version"

echo ""
echo "*** cloning releng scripts"
if [ ! -d "$releng_workdir" ]; then
    git clone https://review.rdoproject.org/r/rdo-infra/releng "$releng_workdir"
fi
pushd "$releng_workdir"
git fetch origin && git rebase origin
pip install -r requirements.txt
python setup.py install
rdo_list_ftbfs -o "$report_csv_file"
popd

echo ""
echo "*** add releng scripts to PYTHONPATH"
export PYTHONPATH="${PYTHONPATH}:${HOME}/releng/scripts"
echo "PYTHONPATH='${PYTHONPATH}'"

echo ""
echo "*** load the authentication token"
if [ -f $token_file ]; then
    token=$(grep auth_token ${token_file} | cut -f2 -d: | awk '{print $1}' | tr -d '"')
else
    echo "ERROR. Token file $token_file not exists!"
    exit 1
fi

./publish-report-ftbfs.py "$report_csv_file" "$token"
