#!py

import os 

def run():
  map = {}

  master_files = __salt__['cp.list_master'](saltenv='base')
  minion_files = __salt__['cp.list_minion'](saltenv='base')
  repl = __salt__['file.join'](opts['cachedir'], 'files/base/')


  for filepath in minion_files:
    basefile = filepath.replace(repl, '')
    if basefile not in master_files and basefile.startswith('stdlib_data') and basefile.endswith('.yml'):
      __salt__['log.warning']("Removing: {}".format(filepath))
      __salt__['file.remove'](filepath)


  dirname = __salt__['file.join'](opts['cachedir'], 'files/base/stdlib_data')
  config = __salt__['slsutil.renderer']('salt://stdlib_data/map.conf')

  for folder in config:
    configpath = __salt__['file.join'](dirname,folder)
    __salt__['log.info']("Path: {}".format(configpath))
    __salt__['cp.cache_dir']('salt://stdlib_data/' + folder)

    for filepath in __salt__['file.find'](configpath, name='*.yml', maxdepth=1):
      __salt__['log.info']("Importing: {}".format(filepath))
      data = __salt__['slsutil.renderer'](filepath)
      __salt__['slsutil.update'](map, data)

  return map