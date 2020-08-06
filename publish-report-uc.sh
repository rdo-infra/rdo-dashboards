#!/usr/bin/env bash

echo ""
echo "*** obliterating and recreating virtualenv"
./setup-publish-report-uc-venv.sh

echo ""
echo "*** sourcing publish-report-uc venv"
source .venv-publish-report-uc/bin/activate
python_version=`python --version`
echo "python version: $python_version"

echo ""
echo "*** cloning releng scripts"
pushd ${HOME}
ls releng >/dev/null 2>&1 || git clone https://review.rdoproject.org/r/rdo-infra/releng
pushd releng
git fetch origin && git rebase origin
popd
popd

echo ""
echo "*** add releng scripts to PYTHONPATH"
export PYTHONPATH="${PYTHONPATH}:${HOME}/releng/scripts"
echo "PYTHONPATH='${PYTHONPATH}'"

echo ""
echo "*** publishing report-uc table"
./publish-report-uc.py
