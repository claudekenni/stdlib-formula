# -*- coding: utf-8 -*-
# vim: ft=sls

{%- set tplroot = tpldir.split('/')[0] %}
{% set map = salt['slsutil.renderer']("salt://stdlib/map.sls") %}

{% do salt.log.info(map|yaml(False)) %}