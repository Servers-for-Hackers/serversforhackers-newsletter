---
title: Setting Up Mailcatcher
topics: [Mailcatcher]
description: Install and use Mailcatcher to test emails in your application.
---

<a name="mailcatcher" id="mailcatcher"></a>
## Mailcatcher

Handling email in applications can be hard.

Ensuring sent emails are designed, parsed and formatted correctly is a painstaking problem.

Mailcatcher is a program you can use to test sending email. It gives you the ability to inspect sent emails and their headers.

It is a simple SMTP server that can receive emails. It also gives you a nice web interface for inspecting sent emails.

We'll cover installing the dependencies for Mailcatcher. Then we'll install and set it up for easy use in our development environment. This includes use with PHP.

### Setup

The first thing we need to do is install some dependencies. As usual, I'll assume we're using Ubuntu 14.04. This process will work for Debian and likely older Ubuntu versions.

We'll install some Mailcatcher dependencies as well as PHP. Then we can install Mailcatcher.

```bash
# Update repositories
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
```

That does it for installing PHP and our dependencies. Next, we can install the Mailcatcher gem.

```bash
# Install Mailcatcher as a Ruby gem
sudo gem install mailcatcher
```

Once that's installed, you can start using Mailcatcher:

```bash
mailcatcher --foreground --http=0.0.0.0
```

This will run Mailcatcher in the foreground. You can exit it by hitting Ctrl+C.

Local scripts can then connect to SMTP at `localhost` port `1025`. Additionally, there's a web interface available at port `1080`. We bound the web interface to all network interfaces via the `--http=0.0.0.0` option.

### Start on Boot

We can setup Mailcatcher to start when our server starts. This lets us forget about having to turn on Mailcatcher whenever we start our development machine.

Rather than install a process monitor, we can use Upstart, which currently comes out of the box with Ubuntu. This will get replaced with Systemd eventually. For now, we can use Upstart.

Create and edit file `/etc/init/mailcatcher.conf`:

```
description "Mailcatcher"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

exec /usr/bin/env $(which mailcatcher) --foreground --http-ip=0.0.0.0
```

Let's cover what this Upstart configuration is doing.

This configuration file tells Upstart to start Mailcatcher at runlevel 2,3,4 and 5. We can see what various [runlevel's do here](http://en.wikipedia.org/wiki/Runlevel).

To explain the runlevels we'll use:

* `2` - Start when the GUI is ready (not applicable on a headless server), and with networking. We care more about the network being ready.
* `3-5` - These are unused in Ubuntu. They are the same as runlevel 2. These are useful to define if this configuration is used with other distributions.

Our configuration says to start when the above runlevels are reached and stop when the runlevels are absent.

The `respawn` directive tells Upstart to restart Mailcatcher if it fails.

Finally we set the command to start Mailcatcher. I used `/usr/bin/env` to find the environment's location of `mailcatcher`. This is useful as the location may change if Mailcatcher was installed using RVM or another environment manager for Ruby.

We configure Mailcatcher to run in the foreground with the `--foreground` option. Mailcatcher daemonizes by default. However, Upstart either needs to be told to `expect daemon` or to run the process in the foreground. The latter is simpler.

Once that file is created, you'll have a new `service` to control. You should be able to use to the following commands:

```
sudo service mailcatcher status
sudo service mailcatcher start
sudo service mailcatcher restart
sudo service mailcatcher stop
```

Run `sudo service mailcatcher start` to kick it off. Then you can head to the server's IP address at port `1080` to see the web interface!

![mailcatcher web interface](https://s3.amazonaws.com/serversforhackers/sfh_mailcatcher.png)

### Send Email in PHP

Let's setup PHP to be able to send email via the `mail()` function.

PHP needs the php.ini configuration `sendmail_path` set to the path of `sendmail`. Mailcatcher comes with the `catchmail` command, which can be used for this purpose.

We'll add a new configuration in PHP's `mods-available` directory. Then we'll enable that configuration for each of PHP's SAPIs.

> Each SAPI is just the context in which PHP is run. For example, on the command line, within PHP-FPM, or loaded in Apache.

Here's the process for configuring PHP:

```bash
# Add config to mods-available for PHP
# -f flag sets "from" header for us
echo "sendmail_path = /usr/bin/env $(which catchmail) -f test@local.dev" | sudo tee /etc/php5/mods-available/mailcatcher.ini

# Enable sendmail config for all php SAPIs (apache2, fpm, cli)
sudo php5enmod mailcatcher

# Restart Apache if using mod_php
sudo service apache2 restart

# Restart PHP-FPM if using FPM
sudo service php5-fpm restart
```

Note that we set the `-f` flag for `catchmail`. This tells Mailcatcher to set the "from" header to `test@local.dev` when email is sent.

We can then send email in PHP:

```php
if( mail('mail@serversforhackers.com', 'Feedback', 'This is so useful, thanks!') )
{
    echo "Mail Sent!";
}
```

That's it! Mailcatcher is now setup for development use.

## More Information

If you have questions on any of this, check out the [Servers for Hackers book](https://book.serversforhackers.com)!

The Servers for Hackers book covers configuring Upstart, Supervisord, Circus and other process monitors.