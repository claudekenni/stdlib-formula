stdlib-formula
======

This is a prototype on how to create a map structure for use with Formulas / States. This is supposed to mimic the way pillarstack works (https://docs.saltstack.com/en/latest/ref/pillar/all/salt.pillar.stack.html)

This formula has two folders , the stdlib where all the Logic happens and the stdlib_data where the Yaml Data resides

Main usage with this is to import the map into another Formulas map.jinja and then merge the datasets together kind of like pillar is merged

Available states
================

``stdlib``
------------

This state is will import the map and print your data as yaml format and some informational log entries

```
root@ubuntu18:/vagrant/code/formulas/stdlib-formula/stdlib# salt-call state.apply stdlib -l info
[INFO    ] Loading fresh modules for state activity
[INFO    ] [u'stack/common/Linux', u'stack/domains/', u'stack/domains//Linux', u'stack/minions/ubuntu18']
[INFO    ] Path: /var/cache/salt/minion/files/base/stdlib_data/stack/common/Linux
[INFO    ] Caching directory 'stdlib_data/stack/common/Linux/' for environment 'base'
[INFO    ] Fetching file from saltenv 'base', ** done ** 'stdlib_data/stack/common/Linux/sshd_config.yml'
[INFO    ] Importing: /var/cache/salt/minion/files/base/stdlib_data/stack/common/Linux/others.yml
[INFO    ] Importing: /var/cache/salt/minion/files/base/stdlib_data/stack/common/Linux/salt-minion.yml
[INFO    ] Importing: /var/cache/salt/minion/files/base/stdlib_data/stack/common/Linux/sshd_config.yml
[INFO    ] Path: /var/cache/salt/minion/files/base/stdlib_data/stack/domains/
[INFO    ] Caching directory 'stdlib_data/stack/domains/' for environment 'base'
[INFO    ] Path: /var/cache/salt/minion/files/base/stdlib_data/stack/domains//Linux
[INFO    ] Caching directory 'stdlib_data/stack/domains//Linux/' for environment 'base'
[INFO    ] Path: /var/cache/salt/minion/files/base/stdlib_data/stack/minions/ubuntu18
[INFO    ] Caching directory 'stdlib_data/stack/minions/ubuntu18/' for environment 'base'
[INFO    ] linux:
  var1: false
  var2: another example
repositories:
  repositories:
    SLE11-SDK-SP4-Pool:
      urlpath: repo/$RCE/SLE11-SDK-SP4-Pool/sle-11-amd64
salt:
  minion:
    master: 127.0.0.1
sshd_config:
  Port: 22
  Protocol: 2
  ClientAliveInterval: 0
  ClientAliveCountMax: 3
  LoginGraceTime: 120
  PermitRootLogin: 'no'
  PasswordAuthentication: 'no'
local:

Summary for local
-----------
Succeeded: 0
Failed:   0
-----------
Total states run:    0
Total run time:  0.000 ms
root@ubuntu18:/vagrant/code/formulas/stdlib-formula/stdlib#
```

Usage
======

* Clone and setup the Formula
* Import the map into your Formula |`map.jinja`
```
{% set map = salt['slsutil.renderer']("salt://stdlib/map.sls") %}
```
* Merge your data `map.jinja` 
```
{# merge the mapdata that is specific to this tplroot #}
{% set mapdata = map.get(tplroot, {}) %}
{% do salt['defaults.merge'](defaults, mapdata) %}
```

Example
======

Here is an example how this could be added to the `map.jinja` in the `template-formula`
```
# -*- coding: utf-8 -*-
# vim: ft=jinja

{#- Get the `tplroot` from `tpldir` #}
{%- set tplroot = tpldir.split('/')[0] %}
{#- Start imports as #}
{%- import_yaml tplroot ~ "/defaults.yaml" as default_settings %}
{%- import_yaml tplroot ~ "/osarchmap.yaml" as osarchmap %}
{%- import_yaml tplroot ~ "/osfamilymap.yaml" as osfamilymap %}
{%- import_yaml tplroot ~ "/osmap.yaml" as osmap %}
{%- import_yaml tplroot ~ "/osfingermap.yaml" as osfingermap %}

{# Add the stdlib map #}
{% set map = salt['slsutil.renderer']("salt://stdlib/map.sls") %}

{#- Retrieve the config dict only once #}
{%- set _config = salt['config.get'](tplroot, default={}) %}

{%- set defaults = salt['grains.filter_by'](
      default_settings,
      default=tplroot,
      merge=salt['grains.filter_by'](
        osarchmap,
        grain='osarch',
        merge=salt['grains.filter_by'](
          osfamilymap,
          grain='os_family',
          merge=salt['grains.filter_by'](
            osmap,
            grain='os',
            merge=salt['grains.filter_by'](
              osfingermap,
              grain='osfinger',
              merge=salt['grains.filter_by'](
                _config,
                default='lookup'
              )
            )
          )
        )
      )
    )
%}

{# merge the mapdata that is specific to this tplroot #}
{% set mapdata = map.get(tplroot, {}) %}
{% do salt['defaults.merge'](defaults, mapdata) %}

{%- set config = salt['grains.filter_by'](
      {'defaults': defaults},
      default='defaults',
      merge=_config
    )
%}

{#- Change **TEMPLATE** to match with your formula's name and then remove this line #}
{%- set TEMPLATE = config %}

{#- Post-processing for specific non-YAML customisations #}
{%- if grains.os == 'MacOS' %}
{%-   set macos_group = salt['cmd.run']("stat -f '%Sg' /dev/console") %}
{%-   do TEMPLATE.update({'rootgroup': macos_group}) %}
{%- endif %}
```