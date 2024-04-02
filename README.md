# What is this?

The dashboard will query the [RDO delorean api](https://github.com/softwarefactory-project/DLRN/blob/master/doc/api_definition.yaml) using [dlrnapi_client](https://github.com/softwarefactory-project/dlrnapi_client) every 15 minutes.

It will show status of Ocata, Pike, and Master branches.

![Dashboard Screenshot](dlrnapi-dashboard-screenshot.png)

### What's current-tripleo?  current-tripleo-rdo? current-tripleo-rdo-internal?

They are symlinks created by CI to indicate that a specific set of RPM's have passed a phase of CI.
For more information please refer to the [DLRN documentation](http://dlrn.readthedocs.io/en/latest/repositories.html).

![Promotion Pipeline Diagram](promotion-pipeline.png)


### What _exactly_ is a "delorean hash"?

- A delorean ([time machine](https://en.wikipedia.org/wiki/DeLorean_time_machine)) "hash" is a specific and unique point in time in the lifespan of all the RPM's that comprise RDO's OpenStack rpm's.
- A hash is comprised of 2 logical parts, a commit identifier, and a distro identifier (see below)
- When the CI jobs in RDO Phase 1 pass (having tested the RPM's associated with a specific hash) they "promote" a new symlink via the API:

```bash
https://trunk.rdoproject.org/centos7-pike/current-tripleo-rdo
```

This actually targets (for example):

```bash
https://trunk.rdoproject.org/centos7-pike/9f/5f/9f5f3b2481d9580b78bbb3d144ceacf11ae39c9d_0701ece8
```

The "hash" listed in the dashboards in this example is: "9f5f3b2481d9580b78bbb3d144ceacf11ae39c9d_0701ece8"

The full details reside in an [artifact (commit.yaml)](https://trunk.rdoproject.org/centos7-pike/9f/5f/9f5f3b2481d9580b78bbb3d144ceacf11ae39c9d_0701ece8/commit.yaml):

```yaml
commits:
- commit_branch: stable/pike
  commit_hash: 9f5f3b2481d9580b78bbb3d144ceacf11ae39c9d
  distgit_dir: /home/centos-pike/data/instack-undercloud_distro/
  distro_hash: 0701ece8f02481a830ffb263f8784803fac38b9f
  dt_build: '1509193864'
  dt_commit: '1509140710'
  dt_distro: '1507655821'
  flags: '0'
  id: '4142'
  notes: OK
  project_name: instack-undercloud
  repo_dir: /home/centos-pike/data/instack-undercloud
  rpms: repos/9f/5f/9f5f3b2481d9580b78bbb3d144ceacf11ae39c9d_0701ece8/instack-undercloud-7.4.3-0.20171028123227.9f5f3b2.el7.centos.noarch.rpm,repos/9f/5f/9f5f3b2481d9580b78bbb3d144ceacf11ae39c9d_0701ece8/instack-undercloud-7.4.3-0.20171028123227.9f5f3b2.el7.centos.src.rpm
  status: SUCCESS
```

Note that the "hashes" referred to in dashboards and by CI folk are in the form: **{commit}_{distro:8}**

Full URI: https://trunk.rdoproject.org/centos7-{release}/{commit[0:2]}/{commit[2:4]}/{commit}_{distro[:8]}

# installation directions

This has been tested on CentOS Stream 9

##### Install dependencies needed to get rolling.

```bash

sudo dnf install epel-release -y
sudo dnf install --enablerepo=crb git ruby ruby-devel rubygem-bundler libxcrypt-devel openssl-devel gcc-c++ make redhat-rpm-config \
    nodejs python3 python3-virtualenv python3-koji
```

##### bundle (install ruby deps)

```bash
git clone https://github.com/rdo-infra/rdo-dashboards
cd rdo-dashboards
bundle config set --local path ~/.gem
bundle install
```

##### The output should look like the following.

_note: Don't panic!  The first time you bundle, there will be spam from gems being installed._

```bash
$ bundle install
Fetching gem metadata from https://rubygems.org/..............
Fetching gem metadata from https://rubygems.org/.
Resolving dependencies...
Using backports 3.18.2
Using bundler 2.1.4
Using coffee-script-source 1.12.2
Using execjs 2.0.2
Using coffee-script 2.2.0
Using concurrent-ruby 1.1.7
Using daemons 1.3.1
Using rack 1.5.5
Using tzinfo 2.0.2
Using rufus-scheduler 2.0.24
Using sass 3.2.19
Using rack-protection 1.5.5
Using tilt 1.4.1
Using sinatra 1.4.8
Using multi_json 1.15.0
Using rack-test 1.1.0
Using sinatra-contrib 1.4.7
Using hike 1.2.3
Using sprockets 2.10.2
Using eventmachine 1.2.7
Using thin 1.6.4
Using thor 1.0.1
Using dashing 1.3.7
Using json 2.3.1
Bundle complete! 2 Gemfile dependencies, 24 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

```
##### Configuration for the rdo-dev dashboard:

- Copy config.ru.in to config.ru then add your secret token to config.ru.
- Add crontab jobs launching:

```bash
    ./feed-dashboard.sh <dashboard url>
```
If not adding feed-dashboard.sh to cron, this script should be run after starting dashboard running to feed it once (useful for development purposes).

A file named /etc/rdo-dashboards.conf is expected to be present. This file must be in YAML format, and provide the token like below.
Note, that token provided in this file must be the same, as in file config.ru.

```yaml
---
auth_token: "YOUR_AUTH_TOKEN"
```

##### Now start your dashboard!

```bash
/usr/bin/bundle exec smashing start
```

The dashboard uses [Thin](https://github.com/macournoyer/thin), which can be run in other ways (background, arbitrary ports, etc), for example with ``smashing start -p 5000``.

Point your favorite browser at: http://localhost:3030

# Notes:

- feed-dashboard.log will be created and has the full debug output.
- history.yml is what the dashboard uses as a cache.  If you're hacking on this and getting unexpected behaviors, nuke that.
- Check out [http://dashing.io/](http://dashing.io/) for more information.

