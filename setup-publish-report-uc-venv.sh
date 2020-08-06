#!/usr/bin/env bash

echo "*** removing '.venv-publish-report-uc' if(exists), and creating a virtualenv for publish-report-uc"
rm -rf .venv-publish-report-uc

echo ""
echo "*** using virtualenv with '--system-site-packages' needed by DNF python
module"
python2 -m virtualenv --system-site-packages .venv-publish-report-uc

echo ""
echo "*** checking if DNF is present"
source .venv-publish-report-uc/bin/activate

# upgrade pip
pip install pip -U

python2 -c 'import dnf' && echo "DNF ok" || echo "Please install package dnf"
