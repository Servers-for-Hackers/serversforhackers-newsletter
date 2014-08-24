---
title: An Ansible Tutorial
topics: [Ansible]
description: Ansible is one of the simplest server provisioning and configuration management tools. This is a guide to getting started with Ansible.
draft: true
---

Ansible is a configuration management and provisioning tool, similar to Chef, Puppet or Salt.

I've found it to be one of the simplest and the easiest to get started with. A lot of this is because it's "just SSH"; It uses SSH to connect to servers and run the configured tasks.

One nice thing about Ansible is that it's very easy to convert bash scripts (still a popular way to accomplish configuration management) into Ansible tasks. Since it's primarily SSH based, it's not hard to see why this might be the case - Ansible ends up running the same commands.

We could just script our own provisioners, but Ansible is much cleaner because it automates the process of getting *context* before running tasks. With this context, Ansible is able to handle most edge cases - the kind we usually take care of with longer and increasingly complex scripts.

Ansible tasks are idempotent. Without a lot of extra coding, bash scripts are usually **not** safety run again and again. Ansible uses "Facts", which is system and environment information it gathers ("context") before running tasks.

Ansible uses these facts to check state and see if it needs to change anything in order to get the desired outcome. This makes it safe to run Ansible tasks against a server over and over again.

Here I'll show how easy it is to get started with Anible. We'll start basic and then add in more features as we improve upon our configurations.

## Install

Of course we need to start by installing Ansible. Tasks can be run off of any machine Ansible is installed on.

This means there's usually a "central" server running Ansible commands, although there's nothing particularly special about what server Ansible is installed on. Ansible is "agentless" - there's no central agent(s) running. We can even run Ansible from any server; I often run tasks from my laptop.

Here's how to install Ansible on Ubuntu 14.04. We'll use the easy-to-remember `ppa:ansible/ansible` repository as [per the official docs](http://docs.ansible.com/intro_installation.html#latest-releases-via-apt-ubuntu).

```bash
sudo apt-add-repository -y ppa:ansible/ansible
sudo apt-get update
sudo apt-get install -y ansible
```

## Managing Servers

Ansible has a default inventory file used to define which servers it will be managing. After installation, there's an example one you can reference at `/etc/ansible/hosts`.

I usually copy and *move* the default one so I can reference it later:

```bash
sudo mv /etc/ansible/hosts /etc/ansible/hosts.orig
```

Then I create my own inventory file from scratch. After moving the example inventory file, create a new `/etc/ansible/hosts` file, and define some servers to manage. Here's we'll define two servers under the "web" label:

```ini
[web]
192.168.22.10
192.168.22.11
```

That's good enough for now. If needed, we can define ranges of hosts, multiple groups, reusable variables, and use [other fancy setups](http://docs.ansible.com/intro_inventory.html), including [creating a dynamic inventory](http://docs.ansible.com/intro_dynamic_inventory.html).

For testing this article, I created a virtual machine, installed Ansible, and then ran Ansible tasks directly on that server. To do this, my `hosts` inventory file simply looked like this:

```ini
[local]
127.0.0.1
```

This makes testing pretty easy - I don't need to setup multiple servers or virtual machines. A consequence of this is that I need to tell Ansible to run tasks as user "vagrant" and ask me the user's password.

## Basic: Running Commands

Once we have an inventory configured, we can start running tasks against the defined servers.

Ansible will assume you have SSH access available to your servers, usually based on SSH-Key. Because Ansible uses SSH, the server it's on needs to be able to SSH into the inventory servers. It will attempt to connect as the current user it is being run as. If I'm running Ansible as user `vagrant`, it will attempt to connect as user `vagrant` on the other servers.

If Ansible can directly SSH into the managed servers, we can run commands without too much fuss:

```bash
$ ansible all -m ping
127.0.0.1 | success >> {
    "changed": false, 
    "ping": "pong"
}
```

We can see the output we get from Ansible is some JSON which tells us if the task made any changes and the result.

If we need to define the user and perhaps some other settings in order to connect to our server, we can. When testing locally on Vagrant, I use the following:

```bash
ansible all -m ping -s -k -u vagrant
```

Let's cover these commands:

* `all` - Use all defined servers from the inventory file
* `-m ping` - Use the "ping" module, which simply runs the `ping` command and returns the results
* `-s` - Use "sudo" to run the commands
* `-k` - Ask for a password rather than use key-based authentication
* `-u vagrant` - Log into servers using user `vagrant`

### Modules

Ansible uses "modules" to accomplish most of its tasks. Modules can do things like install software, copy files, use templates and [much more](http://docs.ansible.com/modules_by_category.html).

Modules are *the* way to use Ansible, as they can use available context ("Facts") in order to determine what actions, if any need to be done to accomplish a task.

If we didn't have modules, we'd be left running arbitrary shell commands like this:

```bash
ansible all -s -m shell -a 'apt-get install nginx'
```

Here, the `sudo apt-get install nginx` command will be run using the "shell" module. The `-a` flag is used to pass any arguments to the module. I use `-s` to run this command using `sudo`.

However this isn't particularly powerful. While it's handy to be able to run these commands on all of our servers at once, we still only accomplish what any bash script might do.

If we used a more appropriate module instead, we can run commands with an assurance of the result. Ansible modules ensure indempotence - we can run the same tasks over and over without affecting the final result.

For installing software on Debian/Ubuntu servers, the "apt" module will run the same command, but ensure idempotence. 

```bash
ansible all -s -m apt -a 'pkg=nginx state=installed update_cache=true'
127.0.0.1 | success >> {
    "changed": false
}
```

This will use the [apt module](http://docs.ansible.com/apt_module.html) to run `sudo apt-get update` to update the repository cache and install Nginx (if not installed).

The result of running the task was `"changed": false`. This shows that there were no changes; I had already installed Nginx. I can run this command over and over without worrying about it changing the desired configuration.

Going over the command:

* `all` - Run on all defined hosts from the inventory file
* `-s` - Run using sudo
* `-m apt` - Use the [apt module](http://docs.ansible.com/apt_module.html)
* `-a 'pkg=nginx state=installed update_cache=true'` - Provide the arguments for the apt module, including the package name, our desired end state and whether to update the package repository cache or not

We can run all of our needed tasks (via modules) in this ad-hoc way, but let's make this more managable. We'll move this task into a Playbook, which can run and coordinate multiple Tasks.

## Basic Playbook

[Playbooks](http://docs.ansible.com/playbooks_intro.html) can run multiple Tasks and provide some more advanced functionality that we would miss out on using ad-hoc commands. Let's move the above task into a playbook.

> Configuration files in Ansible all use Yaml.

Create file `nginx.yml`:

```yaml
---
- hosts: local
  tasks:
   - name: Install Nginx
     apt: pkg=nginx state=installed update_cache=true
```

This task does exactly the same as our ad-hoc command, however I chose to specify my "local" group of servers rather than "all". We can run it with the `ansible-playbook` command:

```bash
$ ansible-playbook -s nginx.yml

PLAY [local] ****************************************************************** 

GATHERING FACTS *************************************************************** 
ok: [127.0.0.1]

TASK: [Install Nginx] ********************************************************* 
ok: [127.0.0.1]

PLAY RECAP ******************************************************************** 
127.0.0.1                  : ok=2    changed=0    unreachable=0    failed=0
```

Use use `-s` to tell Ansible to use `sudo` again, and then pass the Playbook file.

We get some useful feedback while this runs, including what Ansible is doing. Once again we see no changes were made - I have Nginx installed already.

### Handlers

A Handler is exactly the same as a Task (it can do anything a Task can), but it will run when called by another Task. You can think of it as part of an Event system; A handler will take an action when called by an event it listens for.

This is useful for "secondary" actions that might be required after running a task, such as starting a new service after installation or reloading a service after a configuration change.

```yaml
---
- hosts: local
  tasks:
   - name: Install Nginx
     apt: pkg=nginx state=installed update_cache=true
     notify:
      - Start Nginx

  handlers:
   - name: Start Nginx
     service: name=nginx state=started
```

We can add a `notify` directive to the installation task of the task we saw previously. This notifies any Handler named "Start Nginx" after the task is run.

Then we can create the handler called "Start Nginx". This Handler is the Task called when "Start Nginx" is notified.

This particular Handler uses the [Service module](http://docs.ansible.com/service_module.html), which can start, stop, restart, reload (and so on) system services. Here we simply tell Ansible that we want Nginx to be started.

> Note that Ansible has us define the *state* you wish the service to be in, rather than defining the *change* you want. Ansible will decide if a change is needed, we just tell it the desired result.

Let's run this Playbook again:

```bash
$ ansible-playbook -s nginx.yml

PLAY [local] ****************************************************************** 

GATHERING FACTS *************************************************************** 
ok: [127.0.0.1]

TASK: [Install Nginx] ********************************************************* 
ok: [127.0.0.1]

PLAY RECAP ******************************************************************** 
127.0.0.1                  : ok=2    changed=0    unreachable=0    failed=0
```

We get the similar output, but this time the Handler was run.

We can use Playbooks to run multiple tasks, add in variables, define other settings and even include other playbooks.

### More Tasks

Let's add a few more Tasks to this Playbook and explore some other functionality.

```yaml
---
- hosts: local
  vars:
   - docroot: /var/www/serversforhackers.com/public
  tasks:
   - name: Add Nginx Repository
     apt_repository: repo='ppa:nginx/stable' state=present
     register: ppastable

   - name: Install Nginx
     apt: pkg=nginx state=installed update_cache=true
     when: ppastable|success
     register: nginxinstalled
     notify:
      - Start Nginx

   - name: Create Web Root
     when: nginxinstalled|success
     file: dest={{ '{{' }} docroot {{ '}}' }} mode=775 state=directory owner=www-data group=www-data
     notify:
      - Reload Nginx

  handlers:
   - name: Start Nginx
     service: name=nginx state=started

    - name: Reload Nginx
      service: name=nginx state=reloaded
```

There are now three tasks. One adds in the Nginx stable PPA to get the latest stable version of Nginx, using the [apt_repository module](http://docs.ansible.com/apt_repository_module.html). One installs Nginx using the Apt module. Finally, we have one which creates a web root which will be used by a website to be deployed later.

There's also an additional handler to reload Nginx's configuration.

Also new here is the `register` and `when` directives. These tell Ansible to run a task "when" something else happens. The "Add Nginx Repository" task registers "ppastable". Then we use that to inform the Install Nginx task to only run when the registered "ppastable" task is successful. This allows us to conditionally stop Ansible from running a task.

We also use a variable. The `docroot` variable is defined in the `var` section. It's then used as the destination argument of the [file module](http://docs.ansible.com/file_module.html) which creates a directory.

This playbook can be run with the usual command:

```bash
ansible-playbook -s nginx.yml
```

Next we'll take Ansible further and by organizing the Playbook into a Role while also showing some more functionality.

## Roles

Roles are good for handling multiple related tasks. For example, installing Nginx may involve defining Tasks for the package repository, installing the package, setting up configuration and more. We'll likely also have externalities - variables defined, configuration files or templates to copy, handlers and more.

Let's see how we can organize all of these into one coherent structure: a Role.

Roles have a directory structure like this:

```
rolename
 - files
 - handlers
 - meta
 - templates
 - tasks
 - vars
```

Ansible will read any Yaml file called `main.yml` automatically, so we can define configuration files within each and name them `main.yml`.

We'll break apart our `nginx.yml` file and put each component within the corresponding directory to create a cleaner and more complete provisioning toolset.

### Files

First, within the `files` directory, we can add files that we'll want copied into our servers. For Nginx, I often copy [H5BP's component configurations](https://github.com/h5bp/server-configs-nginx/tree/master/h5bp). I simply download the latest there, make any tweaks I want, and put them into the `files` directory.

```
nginx
 - files
 - - h5bp
```

These configurations will be added via the [copy module](http://docs.ansible.com/copy_module.html).

### Handlers

Inside of the `handlers` directory, we can put all of our Handlers that were once within the `nginx.yml` Playbook.

Inside of `handlers/main.yml`:

```yaml
---
- name: Start Nginx
  service: name=nginx state=started

- name: Reload Nginx
  service: name=nginx state=reloaded
```

Once these are in place, we can reference them from other files freely.

### Meta

The `main.yml` file within the `meta` directory contains Role meta data, including dependencies.

If this Role depended on another Role, we could define that here. For example, I have the Nginx role depend on the SSL Role, which installs SSL certificates.

```yaml
---
dependencies:
  - { role: ssl }
```

Otherwise we can omit or leave this file "blank":

```yaml
---
dependencies: []
```

### Template

Template files can contain template variables, based on Python's [Jinja2 template engine](http://jinja.pocoo.org/docs/dev/). Files in here should end in `.j2`, but can otherwise have any name. Similar to `files`, we won't find a `main.yml` file within the `templates` directory.

Here's an example server virtual host used for Nginx. Note that it uses some variables which we'll define later. 

Nginx virtual host file `serversforhackers.com.conf`:

```nginx
server {
    # Enforce the use of HTTPS
    listen 80 default_server;
    server_name *.{{ '{{' }} domain {{ '}}'  }};
    return 301 https://{{ '{{' }} domain {{ '}}'  }}$request_uri;
}

server {
    listen 443 default_server ssl;

    root /var/www/{{ '{{' }} domain {{ '}}'  }}/public;
    index index.html index.htm index.php;

    access_log /var/log/nginx/{{ '{{' }} domain {{ '}}'  }}.log;
    error_log  /var/log/nginx/{{ '{{' }} domain {{ '}}'  }}-error.log error;

    server_name {{ '{{' }} domain {{ '}}'  }};

    charset utf-8;

    include h5bp/basic.conf;

    ssl_certificate           {{ '{{' }} ssl_crt {{ '}}' }};
    ssl_certificate_key       {{ '{{' }} ssl_key {{ '}}' }};
    include h5bp/directive-only/ssl.conf;

    location /book {
        return 301 http://book.{{ '{{' }} domain {{ '}}'  }};
    }

    location / {
        try_files $uri $uri/ /index.php$is_args$args;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { log_not_found off; access_log off; }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;

        fastcgi_pass unix:/var/run/php5-fpm.sock;
        fastcgi_index index.php;

        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO       $fastcgi_path_info;
        fastcgi_param ENV production;
    }

    # Nginx status
    # Nginx Plus only
    #location /status {
    #    status;
    #    status_format json;
    #    allow 127.0.0.1;
    #    deny all;
    #}

    location ~ ^/(fpmstatus|fpmping)$ {
        access_log off;
        allow 127.0.0.1;
        deny all;
        include fastcgi_params;
        fastcgi_pass unix:/var/run/php5-fpm.sock;
    }
}
```

This is a fairly standard Nginx configuration for a PHP application. Of note, there are three Ansible variables used here:

* domain
* ssl_crt
* ssl_key

These three will be defined in the variables section.

### Variables

Before we look at the Tasks, let's look at variables. The `vars` directory contains a `main.yml` file which just lists variables we'll use. This provides a convenient place for us to change configuration-wide settings.

Here's what the `vars/main.yml` file might look like:

```yaml
---
domain: serversforhackers.com
ssl_key: /etc/ssl/sfh/sfh.key
ssl_crt: /etc/ssl/sfh/sfh.crt
```

These are three variables which we'll use in a few place in this Role. We saw it used in the template for the virtual host - we'll also see it used in the Tasks.

### Tasks

Let's finally see this all put together into a series of Tasks.

Inside of `tasks/main.yml`:

```yaml
---
- name: Add Nginx Repository
  apt_repository: repo='ppa:nginx/stable' state=present
  register: ppastable

- name: Install Nginx
  apt: pkg=nginx state=installed update_cache=true
  when: ppastable|success
  register: nginxinstalled
  notify:
    - Start Nginx

- name: Add H5BP Config
  when: nginxinstalled|success
  copy: src=h5bp dest=/etc/nginx owner=root group=root

- name: Disable Default Site
  when: nginxinstalled|success
  file: dest=/etc/nginx/sites-enabled/default state=absent

- name: Add SFH Site Config
  when: nginxinstalled|success
  register: sfhconfig
  template: src=serversforhackers.com.j2 dest=/etc/nginx/sites-available/{{ '{{' }} domain {{ '}}'  }}.conf owner=root group=root validate='service nginx configtest %s'

- name: Enable SFH Site Config
  when: sfhconfig|success
  file: src=/etc/nginx/sites-available/{{ '{{' }} domain {{ '}}'  }}.conf dest=/etc/nginx/sites-enabled/{{ '{{' }} domain {{ '}}'  }}.conf state=link


- name: Create Web root
  when: nginxinstalled|success
  file: dest=/var/www/{{ '{{' }} domain {{ '}}'  }}/public mode=775 state=directory owner=www-data group=www-data
  notify:
    - Reload Nginx

- name: Web Root Permissions
  when: nginxinstalled|success
  file: dest=/var/www/{{ '{{' }} domain {{ '}}'  }} mode=775 state=directory owner=www-data group=www-data recurse=yes
  notify:
    - Reload Nginx
```

This is a longer series of tasks, which makes for a more complete installation of Nginx. The tasks, in order of appearance, accomplish the following:

* Add the nginx/stable repository
* Install & start Nginx, register successful installation to trigger remaining tasks
* Add H5BP configuration
* Disable the default virtual host by removing the symlink to the `default` file from the `sites-enabled` directory
* Copy the included serversforhackers.com template and use Nginx's configtest to ensure the configuration is OK via the `validate` argument
* Enable the configuration by symlinking it to the `sites-enabled` directory
* Creates the web root
* Changes permission for the project root directory, which is one level above the web root

There's some new modules (and uses thereof), including copy, template, & file. By setting the arguments for each module, we can do some interesting things, including ensuring files are "absent" (delete them if they exist) via `state=absent`, or create a file as a symlink via `state=link` rather than copying the file. You should check the docs for each module to see what interesting and useful things you can accomplish with them.

### Running the Role

Before running the role, we need to tell Ansible where our roles are located. In my Vagrant server, they are located within `/vagrant/ansible/roles`. We can add this file path to the `/etc/ansible/ansible.cfg` file:

```config
roles_path    = /vagrant/ansible/roles
```

Assuming our `nginx` role is located at `/vagrant/ansible/roles/nginx`, we'll be all set to run this role!

> Remove the `ssl` dependency from `meta/main.yml` if you are following along here.

Let's create a "master" yaml file which defines the roles to use and what hosts to run them on:

Files `server.yml`:

```yaml
---
- hosts: all
  roles:
    - nginx
```

In my Vagrant example, I use the host "local" rather than "all".

Then we can run the role(s):

```bash
ansible-playbook -s server.yml
```

Or as I do on my local Vagrant machine to run a sudo, ask a password, and run as user `vagrant`:

```bash
$ ansible-playbook -s -k -u vagrant server.yml 
SSH password: 
Vault password: 

PLAY [all] ******************************************************************** 

GATHERING FACTS *************************************************************** 
ok: [127.0.0.1]

TASK: [ssl | Put Unencrypted Key File] **************************************** 
changed: [127.0.0.1]

TASK: [ssl | Put Unencrypted Cert File] *************************************** 
changed: [127.0.0.1]

TASK: [ssl | Create SFH SSL Directry] ***************************************** 
changed: [127.0.0.1]

TASK: [ssl | Upload Unencrypted Key File] ************************************* 
changed: [127.0.0.1]

TASK: [ssl | Upload Unencrypted Cert File] ************************************ 
changed: [127.0.0.1]

TASK: [ssl | Delete Unencrypted Key File] ************************************* 
changed: [127.0.0.1]

TASK: [ssl | Delete Unencrypted Cert File] ************************************ 
changed: [127.0.0.1]

TASK: [nginx | Add Nginx Repository] ****************************************** 
changed: [127.0.0.1]

TASK: [nginx | Install Nginx] ************************************************* 
changed: [127.0.0.1]

TASK: [nginx | Add H5BP Config] *********************************************** 
changed: [127.0.0.1]

TASK: [nginx | Disable Default Site] ****************************************** 
changed: [127.0.0.1]

TASK: [nginx | Add SFH Site Config] ******************************************* 
changed: [127.0.0.1]

TASK: [nginx | Enable SFH Site Config] **************************************** 
changed: [127.0.0.1]

TASK: [nginx | Create Web root] *********************************************** 
changed: [127.0.0.1]

TASK: [nginx | Web Root Permissions] ****************************************** 
ok: [127.0.0.1]

NOTIFIED: [nginx | Start Nginx] *********************************************** 
ok: [127.0.0.1]

NOTIFIED: [nginx | Reload Nginx] ********************************************** 
changed: [127.0.0.1]

PLAY RECAP ******************************************************************** 
127.0.0.1                  : ok=8   changed=7   unreachable=0    failed=0  
```

Awesome, we have Nginx installed now!

## Recap

Here's what we did:

* Installed Ansible
* Setup Ansible
* Ran idempotent commands on multiple servers simultaneously
* Created a basic Playbook to run multiple Tasks, using Handlers
* Abstracted the Tasks into a Role to keep everything Nginx-related organized
  * Saw how to set dependencies
  * Saw how to register Task "dependencies" and run other tasks only if they are successful
  * Saw how to use more templates, files and variables in our Tasks

That's a lot, and it will get you pretty far. However, there's much more to learn once you get started with Ansible.

> If this piqued your interest, the [Servers for Hackers eBook](http://book.serversforhackers.com) will go into more depth with Ansible and many other topics!

## Resources

* **Many** more example roles on [Servers for Hackers Github repo](https://github.com/Servers-for-Hackers).
* Using [Ansible Vault](http://docs.ansible.com/playbooks_vault.html) to encrypt secure data, making it more safe if your Playbooks or Roles end up in version control or otherwise shared
* The [Module Index](http://docs.ansible.com/modules_by_category.html)

There are a **lot** of useful things you can do with Ansible. Explore the [documentation](http://docs.ansible.com/)!
