---
title: Mailcatcher
topics: [Mailcatcher]
description: Install Mailcatcher to test email
draft: true
---

<a name="mailcatcher" id="mailcatcher"></a>
## Mailcatcher

Handling email in code is hard.

Stuff here: http://dor.ky/install-mailcatcher-on-laravel-homestead/
and here: https://github.com/fideloper/Vaprobash/blob/master/scripts/mailcatcher.sh

```
sudo apt-get update

# Install Basics
# build-essential needed for "make" command
sudo apt-get install -y build-essential software-properties-common \
                        vim curl wget tmux

# Install PHP
sudo add-apt-repository -y ppa:ondrej/php5-5.6
sudo apt-get update
sudo apt-get install -y php5 php5-fpm php5-mcrypt php5-mysql \
                        php5-pgsql php5-sqlite php5-curl

# Install Mailcatcher Dependencies (sqlite, ruby)
sudo apt-get install -y libsqlite3-dev ruby1.9.1-dev

# Install Mailcatcher as a gem
sudo gem install mailcatcher
```

Then we can setup an Upstart script so it starts on boot:

File: `/etc/init/mailcatcher.conf`:

```
description "Mailcatcher"

start on runlevel [2345]
stop on runlevel [!2345]

respawn

exec /usr/bin/env $(which mailcatcher) --foreground --http-ip=0.0.0.0
```

Be sure to run this in the foreground. Mailcatcher daemonizes by default. Upstart either needs to be told to `expect daemon` or for us to run mailcatcher in the foreground. The latter is simpler.

Now you should be able to:

```
sudo service mailcatcher status
sudo service mailcatcher start
```

If you use PHP, add `catchmail` as the sendmail path, so we can use the mail() method natively.

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

ANSIBLE ROLE???!!