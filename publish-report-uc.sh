#!/usr/bin/env bash

echo ""
echo "*** obliterating and recreating virtualenv"
./setup-publish-report-uc-venv.sh

echo ""
echo "*** sourcing publish-report-uc venv"
source .venv-publish-report-uc/bin/activate
python_version=`python3 --version`
echo "python version: $python_version"

echo ""
echo "*** cloning releng scripts"
pushd ${HOME}
ls releng >/dev/null 2>&1 || git clone https://review.rdoproject.org/r/rdo-infra/releng
pushd releng
git fetch origin && git rebase origin
pip install -r requirements.txt
popd
popd

echo ""
echo "*** add releng scripts to PYTHONPATH"
export PYTHONPATH="${PYTHONPATH}:${HOME}/releng/scripts"
echo "PYTHONPATH='${PYTHONPATH}'"

echo ""
echo "*** load the authentication token"
TOKEN_FILE='/etc/rdo-dashboards.conf'
ls $TOKEN_FILE >/dev/null 2>&1 && TOKEN=$(grep auth_token ${TOKEN_FILE} | cut -f2 -d:  | awk '{print $1}' | tr -d '"')

echo ""
echo "*** publishing report-uc table"
./publish-report-uc.py $TOKEN centos8
