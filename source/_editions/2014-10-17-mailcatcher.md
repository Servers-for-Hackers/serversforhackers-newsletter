---
title: Setting Up Mailcatcher
topics: [Mailcatcher]
description: Install and use Mailcatcher to test emails in your application.
---

<a name="mailcatcher" id="mailcatcher"></a>
## Mailcatcher

Handling email in applications can be hard.

While reading and receiving email programmatically is a bit of a tougher problem in my experience, sending emails of certain formats can sometimes be challening as well.

Mailcatcher is a program you can use to test sending email. It gives you the ability to inspect sent emails and their headers.

It is a simple SMTP server which can receive emails. It also gives you a nice web interface for inspecting sent emails.

Her we'll cover install the dependencies for Mailcatcher and setting it up for easy use in our development environment.

### Setup

First we'll install some dependencies. As usual, I'll assume we're using Ubuntu 14.04. This process will work for Debian and likely older Ubuntu servers as well.

Here are some basics to isntall. We'll install some dependencies as well as PHP. Then we can see how to make PHP's `mail()` function work with Mailcatcher.

Finally we'll install Mailcatcher, which is a Ruby gem.

```
sudo apt-get update

# Install Basics
# build-essential needed for "make" command
sudo apt-get install -y build-essential software-properties-common \
                        vim curl wget tmux

# Install PHP 5.6
sudo add-apt-repository -y ppa:ondrej/php5-5.6
sudo apt-get update
sudo apt-get install -y php5 php5-fpm php5-mcrypt php5-curl

# Install Mailcatcher Dependencies (sqlite, ruby)
sudo apt-get install -y libsqlite3-dev ruby1.9.1-dev

# Install Mailcatcher as a gem
sudo gem install mailcatcher
```

### Start on Boot

We can setup Mailcatcher to start when our server starts. Then we can forget about having to turn it on whenever we start our development machine.

Rather than install a process monitor, we can use Upstart, which currently comes out of the box with Ubuntu. This will get replaced with SystemD eventually. For now, we can use Upstart.

Create and edit file `/etc/init/mailcatcher.conf`:

```
description "Mailcatcher"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

exec /usr/bin/env $(which mailcatcher) --foreground --http-ip=0.0.0.0
```

This configuration file tells Mailcatcher to start at runlevel 2,3,4 and 5. We can see what those [runlevel's do here](http://en.wikipedia.org/wiki/Runlevel).

* `2` - Start with the GUI (N/A on a server), and with networking
* `3-5` - Unused in Ubuntu, same as runlevel 2. Useful to keep if used on on other distributions

Our setup say to start on the above runlevels are reached and stop when they are not reached.

The `respawn` directive tells Upstart to restart Mailcatcher if it fails.

Finally we set the commend to execute. Used `/usr/bin/env` to find the environment's location of `mailcatcher`. It could change if you install `mailcatcher` using RVM or another environment manager for Ruby.

Be sure to run this command in the foreground. Mailcatcher daemonizes by default. However, Upstart either needs to be told to `expect daemon` or to run the process in the foreground. The latter is simpler.

Once that file is created, you'll have a new `service` to control. You should be able to use to the following commands:

```
sudo service mailcatcher status
sudo service mailcatcher start
sudo service mailcatcher restart
sudo service mailcatcher stop
```

Run `sudo service mailcatcher start` to kick it off. Then you can head to the server's IP address at port `1080` (the default) to see the web interface.

### Send Email in PHP

PHP needs the `sendmail_path` configuration setup to the path to `sendmail` or a compatible program. Mailcatcher comes with the `catchmail` command, which can be used for this.

We can add a new configuration in PHP's `mods-available` directory, and then enable that configuration for each of PHP's SAPIs. Each SAPI is just the context in which PHP is run. For example, on the command line, within PHP-FPM, or loaded in Apache:

```
# Add config to mods-available for PHP
# -f flag sets "from" header for us
echo "sendmail_path = /usr/bin/env $(which catchmail) -f test@local.dev" | sudo tee /etc/php5/mods-available/mailcatcher.ini

# Enable sendmail config for all php SAPIs (apache2, fpm, cli)
sudo php5enmod mailcatcher

# Restart apache if using mod_php
sudo service apache2 restart

# Restart PHP-FPM if using FPM
sudo service php5-fpm restart
```

Note that this set the `-f` flag, telling Mailcatcher to set the "from" header to `test@local.dev` when email sent to Mailcatcher from PHP.

We can then send email in PHP:

```php
if( mail('mail@serversforhackers.com', 'Feedback', 'This is so useful, thanks!') )
{
    echo "Mail Sent!";
}
```

That's it! Mailcatcher is now setup for development use.