#!/bin/bash

WAGTAIL_ROOT=/home/vagrant/wagtail
WAGTAILDEMO_ROOT=/home/vagrant/wagtaildemo

VIRTUALENV_DIR=/home/vagrant/.virtualenvs/wagtaildemo
PYTHON=$VIRTUALENV_DIR/bin/python
PIP=$VIRTUALENV_DIR/bin/pip

NODE_VERSION=v0.12.3

# bring up a vanilla wagtaildemo instance using the current release version of wagtail
$WAGTAILDEMO_ROOT/vagrant/provision.sh

# patch local.py to use our git checkout of wagtail
cp $WAGTAILDEMO_ROOT/wagtaildemo/settings/local.py.example $WAGTAILDEMO_ROOT/wagtaildemo/settings/local.py
cat << EOF >> $WAGTAILDEMO_ROOT/wagtaildemo/settings/local.py
import sys
import os
PATH_TO_WAGTAIL = os.path.join(os.path.dirname(__file__), '..', '..', '..', 'wagtail')
sys.path.insert(1, PATH_TO_WAGTAIL)
EOF

# install additional dependencies of wagtail master
cd $WAGTAIL_ROOT
$PYTHON setup.py develop

# install developer-specific dependencies
apt-get install -y libenchant-dev
su - vagrant -c "$PIP install -r $WAGTAIL_ROOT/requirements-dev.txt"

# run additional migrations in wagtail master
su - vagrant -c "$PYTHON $WAGTAILDEMO_ROOT/manage.py migrate --noinput"

# install node + SASS compilation dependencies
cd
wget http://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION.tar.gz
tar xzf node-$NODE_VERSION.tar.gz
cd node-$NODE_VERSION/
./configure && make && make install

su - vagrant -c "cd $WAGTAIL_ROOT && npm install && npm run build"