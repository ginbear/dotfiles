# -*- coding:utf-8 -*-

import fabric
from fabric.api import *

@task
def sudo(cmd):
  fabric.operations.sudo(cmd % env)

@task
def put(local,remote,mode=None,use_sudo=None,owner=None,group=None):
  local_path = local % env
  remote_path= local % env
  fabric.operations.put(local_path,remote_path,mode=mode,use_sudo=use_sudo)

  env.use_sudo = use_sudo

  if owner:
    _exec("chown %s %s" % (owner, remote_path))

  if group:
    _exec("chgrp %s %s" % (owner, remote_path))

@task
def get(remote,local):
  fabric.operations.get(remote % env,local % env)

def _exec(cmd):
  if env.use_sudo:
    sudo(cmd)
  else:
    run(cmd)

@task
def show_hostinfo():
    run('w')
    run('uname -n')
    run('cat /etc/redhat-release')
    run('cat /etc/issue')
    run('uptime')
    run('id')
    sudo('id')

