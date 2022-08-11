#!/usr/bin/env bash

report_csv_file="$1"
releng_workdir="${HOME}/releng"

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

./publish-report-ftbfs.py "$report_csv_file" "$TOKEN"
