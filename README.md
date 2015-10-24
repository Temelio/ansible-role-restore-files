restore-files
=============

[![Build Status](https://travis-ci.org/infOpen/ansible-role-restore-files.svg?branch=master)](https://travis-ci.org/infOpen/ansible-role-restore-files)

Install restore-files backup script.

Requirements
------------

This role requires Ansible 2.0 or higher, and platform requirements are listed
in the metadata file.

Role Variables
--------------

Follow the possible variables with their default values

    # Defaults file for restore-files

    # Common settings
    restore_files_script_destination : "/root/scripts"
    restore_files_script_mode        : "0700"
    restore_files_script_owner       : "root"
    restore_files_script_group       : "root"

    # Logging settings
    restore_files_main_log_file      : "/var/log/syncho_restore.log"
    restore_files_error_log_file     : "/var/log/syncho_restore.err"

    # Tasks
    restore_files_tasks : []

    # Task definition example :
    # - cron :
    #     cronfile  : "foo"
    #     name      : "bar"
    #     user      : "root"
    #     minute    : 0
    #     hour      : 23
    #     month_day : "*"
    #     month     : "*"
    #     week_day  : "*"
    #   backup_directory : ""
    #   sql  :
    #     credential_file  : "/root/.my.cnf"
    #     do_mysql_restore : False
    #     mysql_databases  : []
    #   files :
    #     do_clean_folder : False
    #     files_list      : []
    #     files_owner     : "root"
    #     files_group     : "root"


Dependencies
------------

None

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: achaussier.restore-files }

License
-------

MIT

Author Information
------------------

Alexandre Chaussier (for Infopen company)
- http://www.infopen.pro
- a.chaussier [at] infopen.pro
