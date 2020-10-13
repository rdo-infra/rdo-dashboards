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

This has been tested on CentOS 8

##### Install dependencies needed to get rolling.

```bash
sudo dnf install git ruby rubygem-bundler ruby-devel lbxcrypt-devel openssl-devel nodejs gcc-c++ make redhat-rpm-config \
    python3 python3-virtualenv python3-koji
gem install --user-install bundler
gem install --user-install dashing
```

##### bundle (install ruby deps)

```bash
git clone https://github.com/rdo-infra/rdo-dashboards
cd rdo-dashboards
bundle
```

##### The output should look like the following.

_note: Don't panic!  The first time you bundle, there will be spam from gems being installed._

```bash
[you@yourbox dlrnapi-dashboard] $ bundle
The latest bundler is 1.16.0.pre.3, but you are currently running 1.16.0.pre.2.
To install the latest version, run `gem install bundler --pre`
Using public_suffix 3.0.0
Using addressable 2.5.2
Using backports 3.10.3
Using buftok 0.2.0
Using bundler 1.16.0.pre.2
Using coffee-script-source 1.12.2
Using execjs 2.0.2
Using coffee-script 2.2.0
Using daemons 1.2.5
Using unf_ext 0.0.7.4
Using unf 0.1.4
Using domain_name 0.5.20170404
Using equalizer 0.0.11
Using ffi 1.9.18
Using ethon 0.11.0
Using eventmachine 1.2.5
Using multipart-post 2.0.0
Using faraday 0.11.0
Using hike 1.2.3
Using http-cookie 1.0.3
Using http-form_data 1.0.3
Using http_parser.rb 0.6.0
Using http 2.2.2
Using json 2.1.0
Using thread_safe 0.3.6
Using memoizable 0.4.2
Using multi_json 1.12.2
Using naught 1.1.0
Using rack 1.5.5
Using rack-protection 1.5.3
Using rack-test 0.7.0
Using typhoeus 1.3.0
Using ruby_dlrnapi 1.0.0 from https://github.com/halcyondude/ruby_dlrnapi.git (at master@ab830dc)
Using tzinfo 1.2.3
Using rufus-scheduler 2.0.24
Using sass 3.2.19
Using simple_oauth 0.3.1
Using tilt 1.4.1
Using sinatra 1.4.8
Using sinatra-contrib 1.4.7
Using sprockets 2.10.2
Using thin 1.6.4
Using thor 0.20.0
Using dashing 1.0.0
Using twitter 6.1.0
Bundle complete! 3 Gemfile dependencies, 45 gems now installed.
Use `bundle info [gemname]` to see where a bundled gem is installed.

```

##### Now start your dashboard!

```bash
dashing start
```

The dashboard uses [Thin](https://github.com/macournoyer/thin), which can be run in other ways (background, arbitrary ports, etc), for example with ``dashing start -p 5000``.

Point your favorite browser at: http://localhost:3030

# Notes:

- feed-dashboard.log will be created and has the full debug output.
- history.yml is what the dashboard uses as a cache.  If you're hacking on this and getting unexpected behaviors, nuke that.
- Check out [http://dashing.io/](http://dashing.io/) for more information.

# for the rdo-dev dashboard:

- Copy config.ru.in to config.ru then add your secret token to config.ru.
- Add a crontab launching:

```bash
    ./feed-dashboard.sh <dashboard url>
```

A file named /etc/rdo-dashboards.conf is expected to be present. This file must be in YAML format, and provide the token like this:

```yaml
---
auth_token: "token"
```
