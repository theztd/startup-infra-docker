Vultr management by ansible
===========================

For a small infrastructure sometimes does not make sense to split logic between two automatization tools (like an ansible and a terraform). This repository is an example of how to manage the whole Vultr infrastructure by ansible.

Before start
------------

 * Register vultr account
 * Enable vultr API
 * Place your api key to file ~/.vultr.ini (echo -e "[default]\nkey = YOUR_API_KEY\n" > ~/.vultr.ini)
 * Now use ansible as usual


The key parts are:
------------------
 * **env/devel/hosts** is inventory used to for deploy servers in vultr infrastructure
 * **env/devel/vultr.yaml** file tell to ansible to get inventory from vultr api (especuialy IP addresses etc)
 * **~/.vultr.ini** is the right place where api key should be placed


