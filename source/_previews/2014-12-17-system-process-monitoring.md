---
title: System Process Monitoring
descr: How to keep your processes running on your servers!
---

As some point you'll likely find yourself writing a script which needs to run all the time - a "long running process". These are scripts that should continue to run even if there's an error and should should restart when the system reboots.

These can be simple scripts or full-fledged applications.

To ensure our processes are always running, we need something to watch them. Such tools are Process Watchers.

Popular third-party tools for are Monit, Supervisord and Circus. However, every system comes with it's own built-in system as well.

Here we'll take a look at Upstart, which can be found on Debian and Ubuntu systems (until Systemd takes over).

## Upstart

Upstart is (for now) the system used by Debian and Ubuntu to handle process initialization and management. Configurations for Upstart are found in `/etc/init` directory. Upstart configuration files end in the `.conf` extension.

> Debian and, eventually, Ubuntu will be moving to Systemd. Systemd isn't covered here, but is in the Servers for Hackers book!

An example (fake) configuration found at `/etc/init/faux-service.conf` might be as follows:

```conf
start on filesystem and net-device-up IFACE=lo
stop on runlevel [016]

respawn

exec /path/to/some/faux-script --foo=bar
```

This configuration for a fake script will start the process on boot, after the file system and localhost (lo) network have been initialized. It will stop at runlevel `[016]`, essentially saying when the system shuts down (0), in single-user mode (1) or when the system reboots (6).

You can find more on [Linux run levels in this IBM article](http://www.ibm.com/developerworks/library/l-lpic1-v3-101-3/).

The `respawn` directive will tell Upstart to respawn the process if it dies unexpectedly.

Finally the `exec` directive is a command used to run the process. Here we run the `faux-script` process.

T> Many programs try to run as daemons (in the background). Processes managed by Upstart generally should run in the *foreground*, allowing Upstart to monitor it.
T>
T> That being said, Upstart *can* track certain processes which run as Daemons. See documentation on the use of the `expect` directive for more information.

Upstart uses the `initctl` command to control processes. We can run commands such as:

```bash
# List available services
sudo initctl list

# Start and Stop faux-service
sudo initctl start faux-service
sudo initctl stop faux-service

# Restart and Reload faux-service
sudo initctl restart faux-service
sudo initctl reload faux-service

# Get the processes status (running or not running)
sudo initctl status faux-service
```

Ubuntu also has shortcuts for these - you can use the `start`, `stop`, `restart`, `reload` and `status` commands directly:

```bash
sudo start faux-service
sudo stop faux-service
sudo restart faux-service
sudo reload faux-service
sudo status faux-service
```

## The Service Command

You may have noticed that in many tutorials, you were told to control a process using the `service` command, such as the following:

```bash
sudo service apache2 start

sudo service nginx reload
```

Because Ubuntu (and other distributions) has transitioned between process monitors such as SysVinit and Upstart, the `service` command was created. This command is a common interface for many process monitors. You can control SysV and Upstart processes using the same set of commands.

## Another Example

Here's an example of another example of an Upstart script, which can show you some more options:

```conf
description "Consul agent"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

script
  if [ -f "/etc/service/consul" ]; then
    # Gives us the CONSUL_FLAGS variable
    . /etc/service/consul
  fi

  # Make sure to use all our CPUs, because Consul can block a scheduler thread
  export GOMAXPROCS=`nproc`

  # Get the public IP
  BIND=`ifconfig eth0 | grep "inet addr" | awk '{ print substr($2,6) }'`

  exec /usr/local/bin/consul agent \
    -config-dir="/etc/consul.d" \
    -bind=$BIND \
    ${CONSUL_FLAGS} \
    >>/var/log/consul.log 2>&1
end script
```

This is a script which keeps Consul running. [Consul](https://consul.io/) is a service discovery application made by HashiCorp. Luckily, we don't need to care about that to understand this example!

he focus here is that we are using Upstart to make sure Consul starts on system boot, and respawns if it fails.

Here's what's going on:

* `description` - Give this a human-readable description
* `start on runelevel [2345]` - Instead of starting on "filesystem" and a specific network device, we can specify run levels here as well. Here we're starting when "multi-user" mode starts, instead of when the system boots.
* `stop on ...` - same as before, stop when we shut down, restart, etc
* `respawn` - Respawn if it fails on an error
* `script ... end script` - We can make a multi-line script that gets run, rather than a one-liner. This is run in `sh` instead of `bash`, and so may not function exactly like you think.
* `. /etc/service/consul` - This is sourcing a file. We can't use the `source` command, however, since `sh` doesn't have it. Instead we use the `.` notation to source the file. This is a good way to set environment variables.
* `export GOMAXPROCS=`nproc` - Here we set an environment variable without sourcing a file
* `BIND=...` - Create a variable, locally scoped to this script. This happens to get the ipv4 IP address of of the eth0 network interface (as listed with the `ifconfig` command)
* `exec ...` - The command to run to start consul. Note that we can make it a multi-line command just like we can in bash scripts, by escaping the return character with a backslash. This also outputs all output (err and otherwise) to a log file.

Once this file is saved at `/etc/init/consul.conf`, you'll be able to start using it! I prefer the `service` suite of commands:

```shell
# Check it's status
$ sudo service consul status

# Start the service
$ sudo service consul start
```








