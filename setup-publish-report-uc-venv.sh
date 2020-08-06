#!/usr/bin/env bash

echo "*** removing '.venv-publish-report-uc' if(exists), and creating a virtualenv for publish-report-uc"
rm -rf .venv-publish-report-uc

echo ""
echo "*** using virtualenv with '--system-site-packages' needed by DNF python
module"
virtualenv -p /usr/bin/python3 --system-site-packages .venv-publish-report-uc

echo ""
echo "*** checking if DNF is present"
source .venv-publish-report-uc/bin/activate
python -c 'import dnf' && echo "DNF ok" || echo "Please install package dnf"
