#!/usr/bin/env bash

#
# Copyright (C) 2017 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

echo ""
echo "*** Removing '.venv-dlrnapi' if(exists), and creating a virtualenv for dlrnapi"
echo ""

# remove existing venv
rm -rf .venv-dlrnapi

# create virtualenv so dlrnap requirements are sandboxed.

python3 -m virtualenv .venv-dlrnapi

# enter the venv
source .venv-dlrnapi/bin/activate

# upgrade pip
pip install pip -U

pip install -r requirements-dlrnapi.txt

echo ""
echo "*** Don't forget to 'source .venv-dlrnapi/bin/activate' - Use 'dlrnapi --help' for more details."
echo ""
