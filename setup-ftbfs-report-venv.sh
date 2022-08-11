#!/usr/bin/env bash

echo "*** removing '.venv-ftbfs-report' if(exists), and creating a virtualenv for ftbfs-report"
rm -rf .venv-ftbfs-report

echo ""
echo "*** using virtualenv with '--system-site-packages' needed by DNF python
module"
python3 -m virtualenv --system-site-packages .venv-ftbfs-report

echo ""
echo "*** checking if DNF is present"
source .venv-ftbfs-report/bin/activate

# upgrade pip
pip install pip -U

python3 -c 'import dnf' && echo "DNF ok" || echo "Please install package dnf"
