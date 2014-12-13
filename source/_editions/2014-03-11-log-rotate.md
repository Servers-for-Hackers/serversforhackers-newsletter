---
title: Managing Logs with Logrotate
topics: [Managing Logs with Logrotate]
description: Logs can be growing out of control in your server! Learn how to manage your server logs.
---

Server software often logs events and errors to log files. For the most part, systems typically can take care of managing log files so they do not eventually eat up available hard drive space. Not all do this successfully, however.

Compounding this, many application frameworks have their own logging in place. Few manage the deletion or compression of their log files. In cases such as this, you should set up rotating logs and a log backup. 

Logrotate is there to do this for you. It is available and used on most linux systems.

## What does Logrotate do?

Logrotate helps to manage your log files. It can periodically read, minimize, back up, creates new log files, and basically anything you may ever want to do with them. This is usually used to to help prevent any single log file from getting unwieldy in size. It is commonly also used to  delete old log files so as not to fill your server's hard drive.

Many apps setup Logrotate for you. For instance, installing Apache in Ubuntu adds the file `/etc/logrotate.d/apache2`, which is a configuration files used by Logrotate to rotate all apache access and error logs.

## Configuring Logrotate

In stock Ubuntu, any config file you put into `/etc/logrotate.d` is going to run once per day. Logs are typically rotated once per day or less (Apache default in Ubuntu is in fact weekly).

### Default Apache

Let's look over [Apache's default](https://gist.github.com/3982619) in Ubuntu - `/etc/logrotate.d/apache2`.

    /var/log/apache2/*.log {
            weekly
            missingok
            rotate 52
            compress
            delaycompress
            notifempty
            create 640 root adm
            sharedscripts
            postrotate
                /etc/init.d/apache2 reload > /dev/null
            endscript
            prerotate
                if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
                        run-parts /etc/logrotate.d/httpd-prerotate; \
                fi; \
            endscript
    }

This will rotate any files in **/var/log/apache2** that end in ".log". This is why, when we [create a new Apache virtual host](http://fideloper.com/ubuntu-prod-vhost), we typically put the logs in `/var/log/apache2`. Logrotate will automatically manage the log files!

Let's go through the options.

* **weekly**: Rotate logs once per week. Available options are daily, weekly, monthly, and yearly.
* **missingok**: If no *.log files are found, don't freak out
* **rotate 52**: Keep 52 files before deleting old log files (Thats a default of 52 weeks, or one years worth of logs!)
* **compress**: Compress (gzip) log files
    * **delaycompress**: Delays compression until 2nd time around rotating. As a result, you'll have one current log, one older log which remains uncompressed, and then a series of compressed logs. [More info on its specifics](http://serverfault.com/questions/292513/when-to-use-delaycompress-option-in-logrotate).
    * **compresscmd**: Set which command to used to compress. Defaults to gzip.
    * **uncompresscmd:** Set the command to use to uncompress. Defaults to gunzip.
* **notifempty**: Don't rotate empty files
* **create 640 root adm**: Create new log files with set permissions/owner/group, This example creates  file with user `root` and group `adm`. In many systems, it will be `root` for owner and group.
* **sharedscripts**: Run postrotate script *after* all logs are rotated. If this is not set, it will run *postrotate* after each matching file is rotated.
* **postrotate**: Scripts to run after rotating is done. In this case, Apache is reloaded so it writes to the newly created log files. Reloading Apache (gracefully) lets any current connection finish before reloading and setting the new log file to be written to.
* **prerotate**: Run before log rotating begins

> Note: There are more options. Check them out [here](http://linuxcommand.org/man_pages/logrotate8.html).

Here's what I have for a PHP application in production, which uses Mongolog to create log files in addition to the default Apache logger.

    /var/www/my-app/application/logs/*.log {
        daily
        missingok
        rotate 7
        compress
        delaycompress
        notifempty
        create 660 appuser www-data
        sharedscripts
        dateext
        dateformat -web01-%Y-%m-%d-%s
        postrotate
            /etc/init.d/apache2 reload > /dev/null
            /usr/bin/s3cmd sync /var/www/my-app/application/logs/*.gz s3://app_logs
        endscript
        prerotate
            if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
                run-parts /etc/logrotate.d/httpd-prerotate; \
            fi; \
        endscript
    }

Note that we specify the directory where the log files are written to from the application. The other items to note in the above Logrotate configuration:

* **daily**: This writes daily, since we expect a decent amount of traffic. 
* **rotate 7**: Keep only the last 7 days of logs in the server.
* **create 660 appuser www-data**: New log files are owned by `appuser`, which is and example username of the user used to deploy files to the server. The log files are in group `www-data`, the same group that Apache typically runs as. The permissions (660) allow both owner *and* users of the same group to write to the file (`appuser` and Apache user `www-data` can then write to and edit these files). This let's the PHP app write to the log files!
* **dateext**: Logs by default get a number appended to their filename. This option appends a date instead.
    * **dateformat**: The format of the date appended to the log filename you want. These logs also add web01, web02 (and so on) to the log file name so we know which webserver the log came from. This is recommended if you are [logging on multiple web servers behind a load balancer](http://fideloper.com/web-app-load-balancing) and will combine the logs at a later date.
* **postrotate**: Note that I'm saving log files to Amazon S3 using the [s3cmd](http://s3tools.org/s3cmd) CLI tool. Using 'sync' is similar to rsync - It will overwrite files in S3 with newer files. This is especially why differentiating log file names between web01, web02, etc is necessary. This is some magic right here - Both giving you off-site backups to your log files, and not taking up unnecessary server space.

## Resources

* Note that two important and/or useful items in this article: Creating the log files with the correct permissions and saving log files to Amazon S3 for off-site backup.
* [Logrotate man page](http://linuxcommand.org/man_pages/logrotate8.html), outlining the many options available.
* [Logrotate config for various commons services](http://tuxers.com/main/log-rotation-for-a-good-nights-sleep/)

Note the example on how to upload log files to Amazon S3 automatically when each log is rotated. This is a good solution to back up logs for later analysis, but not the most elegant.

Not explicitly stated is that Logrotate runs on a daily cron job. Usually you can find a the `logrotate` script run at `/etc/cron.daily/logrotate`. Many OSes come with scripts which can be run regularly, simply by being placed in the correct directory, such as `/etc/cron.hourly`, `/etc/cron.daily`, `/etc/cron.weely` and `/etc/cron.monthly`.

Here are some more resources:

* [Log Rotate Explanation from Rackspace](http://www.rackspace.com/knowledge_center/article/understanding-logrotate-part-1)
* [Digital Ocean on Logrotate for Ubuntu](https://www.digitalocean.com/community/articles/how-to-manage-log-files-with-logrotate-on-ubuntu-12-10)
* [Run Logrotate manually](http://stackoverflow.com/questions/2117771/is-it-possible-to-run-one-logrotate-check-manually) instead of via CRON
* Finally, [Log Resources for Distributed Environments](http://fideloper.com/web-app-load-balancing) (scroll to the bottom)