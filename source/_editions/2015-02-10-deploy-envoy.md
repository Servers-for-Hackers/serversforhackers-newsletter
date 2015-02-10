---
title: Deployment with Envoy
topics: [Use Laravel's Envoy for Deployment]
description: We'll use Laravel's Envoy to deploy a PHP application to a production server. 
---

<script type="text/javascript" src="//cdn.sublimevideo.net/js/h4bb7ywv.js"></script>

We'll use Laravel's Envoy to deploy a PHP application to a production server. This will make a new release directory, clone the repository into it, run any needed build steps, and then finally swap the new code out with the older code, so that Nginx and PHP-FPM serve the new code..

<video id="119176265" class="sublime" poster="https://s3.amazonaws.com/serversforhackers/sfh-bumper-compressor.png" width="1280" height="720" title="Deployment with Envoy" data-uid="119176265" data-autoresize="fit" preload="none">
  <source src="http://player.vimeo.com/external/119176265.hd.mp4?s=def43afc3a02149647a7c8fc48321bb5" data-quality="hd" />
  <source src="http://player.vimeo.com/external/119176265.sd.mp4?s=31e775044fa899efad811f1615be224c" />
  <source src="http://player.vimeo.com/external/119176265.mobile.mp4?s=12cb0f92d63ec3ef8977ef2e4131b6d1" />
</video>

## Setup

The remote server is at IP address `104.236.85.162`. It has a user `deployer`, and I created a local SSH key pair to connect to it. That key pair is called `id_deployex`.

To generate this key pair, I used the following command:

```bash
ssh-keygen -t rsa -b 4096 -C "fideloper@gmail.com" -f id_deployex
```

To copy that to the remote/production server (since I'm on a Vagrant server, not my Mac, which may not have this command), I can use the following to copy the public key into the `deployer` user's `authorized_keys` file:

```bash
# Since not running on mac, we have this command
# This will ask for the user's password to log in with, and assumes
# the server allows password-based authentication
ssh-copy-id -o "PubkeyAuthentication no" deployer@104.236.85.162
```


On the remote (production) server, we create SSH key to use within GitHub as a Deploy Key. This lets us push/pull to the GitHub repository from the production server, which we'll use to deploy new code.

```bash
# Create key, by default named "id_rsa"
ssh-keygen -t rsa -b 4096 -C "fideloper@gmail.com"

# Echo out the public key, 
# so we can copy it and paste it into GitHub
cat ~/.ssh/id_rsa.pub
```

Then we can get to using Envoy with our Laravel application.

## Install Envoy Globally

```bash
# Install envoy globally. May need to ensure that
# the composer vendor/bin directory is in your PATH
# so the envoy command is found
composer global require "laravel/envoy=~1.0"

# fails, if the PATH variable is not set with composer's
# bin directory
which envoy


vim ~/.profile
```

If the `which envoy` test fails (if there's no output saying the path to the envoy command), edit `.profile`, `.bashrc` or whatever is appropriate for your system. Within this file, we'll append the following near the bottom. Adjust the file path as needed for your development server.

```bash
# Prepend the composer bin directory to your PATH
# This path is specific to my vagrant server
export PATH=/home/vagrant/.composer/vendor/bin:$PATH
```

Finally we can create an envoy file for our project:

```bash
cd /vagrant/app
vim Envoy.blade.php
```

Here's a sample we can use to test that Envoy can connect to our server:

```php
{% verbatim %}@servers(['web' => 'deploy-ex'])

<?php $whatever = 'hola, whatever'; ?>

@task('deploy', ['on' => 'web'])
    echo {{ $whatever }}
@endtask
{% endverbatim %}
```

To run that:

```bash
envoy run deploy
```

Now we'll employ a deployment strategy with Envoy:

```php
{% verbatim %}@servers(['web' => 'deploy-ex'])

<?php
$repo = 'git@github.com:Servers-for-Hackers/deploy-ex.git';
$release_dir = '/var/www/releases';
$app_dir = '/var/www/app';
$release = 'release_' . date('YmdHis');
?>

@macro('deploy', ['on' => 'web'])
    fetch_repo
    run_composer
    update_permissions
    update_symlinks
@endmacro

@task('fetch_repo')
    [ -d {{ $release_dir }} ] || mkdir {{ $release_dir }};
    cd {{ $release_dir }};
    git clone {{ $repo }} {{ $release }};
@endtask

@task('run_composer')
    cd {{ $release_dir }}/{{ $release }};
    composer install --prefer-dist;
@endtask

@task('update_permissions')
    cd {{ $release_dir }};
    chgrp -R www-data {{ $release }};
    chmod -R ug+rwx {{ $release }};
@endtask

@task('update_symlinks')
    ln -nfs {{ $release_dir }}/{{ $release }} {{ $app_dir }};
    chgrp -h www-data {{ $app_dir }};
@endtask
{% endverbatim %}
```

Run that and test it via:

```bash
envoy run deploy
```

A notable command is the creation of the symlink to make the new code files live. This is the `ln` command with the `-nfs` flags used:

* `-s` - Create a symbolic link.
* `-f` - Force the creation of the symlink even if a file, directory, or symlink already exists at that location (it will unlink, aka delete, the target directory!).
* `-n` - If the target directory or file is a symlink, don't follow it. Often used with the `-f` flag.

After testing that, we add new route to `app/Http/routes.php`, thus changing the code to simulate a real development-deployment cycle.

```php
Route::get('/test', function()
{
    Return Request::header();
});
```

Update the remote GitHub repository:

```bash
git add --all
git commit -m "added new test route"
git push origin master
```

Then we can re-run the deployment script and see if it worked:

```bash
envoy run deploy
```


## Notes and Resources

Here is the Envoy [Repository](https://github.com/laravel/envoy) and [Documentation](http://laravel.com/docs/5.0/ssh#envoy-task-runner)

Create the Laravel application within Vagrant:

```bash
cd /vagrant
composer create-project laravel/laravel app
```

Nginx Config on Vagrant and production server (the difference is only the `server_name` directive value).

```nginx
server {
    listen 80;

    root /vagrant/app/public;

    index index.html index.htm index.php app.php app_dev.php;

    # Make site accessible from ...
    server_name 192.168.22.45.xip.io vaprobash.dev;

    access_log /var/log/nginx/vagrant.com-access.log;
    error_log  /var/log/nginx/vagrant.com-error.log error;

    charset utf-8;

    location / {
        try_files $uri $uri/ /app.php?$query_string /index.php?$query_string;
    }

    location = /favicon.ico { log_not_found off; access_log off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    # pass the PHP scripts to php5-fpm
    # Note: .php$ is susceptible to file upload attacks
    # Consider using: "location ~ ^/(index|app|app_dev|config).php(/|$) {"
    location ~ .php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+.php)(/.+)$;
        # With php5-fpm:
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param LARA_ENV local; # Environment variable for Laravel
        fastcgi_param HTTPS off;
    }

    # Deny .htaccess file access
    location ~ /\.ht {
        deny all;
    }
}
```