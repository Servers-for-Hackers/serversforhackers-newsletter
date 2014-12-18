---
title: Logrotate & Application Logfiles
descr: Keep growing log files under control with logrotate!
---

If you have a web application that writes to a logfile, you should know how to manage it. Log files can grow unchecked, taking up resources.

Logrotate is a utility which scans directories with logfiles. It can move the file, compress it, and create a new file for an application to write to. It can also delete logfiles after it reaches an age threshold, and even run scripts before and after it rotates logs.

## Configuration

In Debian and Ubuntu, logrotate configuration files can be placed inside of the `/etc/logrotate.d` directory. They don't require any specific file extension.

Usually logrotate runs once per day. This means that any time intervals defined should be at least one day.

## An Example

Let's see an example for a fictional application. Let's place a new configuration file at `/etc/logrotate.d/some-app`.

This will rotate our fictional application's logs:

```conf
/var/www/some-app/app/storage/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 660 www-data www-data
    sharedscripts
    dateext
    dateformat -web01-%Y-%m-%d-%s
    prerotate
        if [ -d /etc/logrotate.d/httpd-prerotate ]; then \
            run-parts /etc/logrotate.d/httpd-prerotate; \
        fi; \
    endscript
    postrotate
        /usr/bin/aws s3 sync /var/www/some-app/app/storage/logs/*.gz s3://app_logs
    endscript
}
```

Let's go over this and see what the configuration is doing.

### daily

If this application expects a large amount of traffic, the configuration rotates logs daily. The application logs are likely to grow quickly. We can also define `monthly` and other settings.

### missingok

If no `*.log` files are found, don't raise an error.

### rotate 7

Keep only the last 7 days of logs in the server. We can keep this small if we also move the logs off of the server as backup.

### compress

Compress (gzip) rotated log files. There are some related directives you can use as well:

### delaycompress 

Delays compression until 2nd time around rotating. As a result, you'll have one current log file, one older log file which remains uncompressed, and then a series of compressed logs. 

This is useful if a process (such as Apache) cannot be told to immediately close the log file for writing. It makes the old file available for writing until the next rotation.

If used, you'll see log files like this:

* access.log
* access.log.1
* access.log.1.gzip

You can see that `access.log.1` has been rotated out but is not yet compressed.

### notifempty

Don't rotate empty log files.

### create 660 appuser www-data

Logs for this application are not being written to the `/var/log` directory. Additionally, new log files in this example are owned by user `www-data`. Assuming the application is run as user `www-data` as well, this setting ensures that the application can continue to write to the log files which logrotate manages.

We set the file permissions to 660, which lets the user and group read and write to the log files. This is best if you rely on group permissions so multiple users (perhaps a deployment user and the web application user of group `www-data`) can write to files as needed.

### sharedscripts

Run a `postrotate` script after *all* logs are rotated. If this directive is not set, it will run `postrotate` scripts after *each* matching file is rotated.

### dateext

Logs by default get a number appended to their filename. This option appends a date instead.

A related directive:

#### dateformat

This is the format of the date appended to the log filename. 

In this example - `dateformat -web01-%Y-%m-%d-%s`, Logrotate will also add "web01", "web02" (and so on) to the log file name so we know which webserver the log came from. This is recommended if you are logging on multiple web servers, likely behind a load balancer. Knowing what server the logs came from may be useful.

This naming scheme isn't dynamic but instead is hardcoded as "web01" and so forth - naming them correctly would be a exercise left to you (to do via automation or manually). Note that with log aggregators, this may not be a needed addition.

### prerotate

Run scripts *before* log rotating begins. Just like with `postrotate`, the end of the script is denoted with the `endscript` directive.

This `prerotate` directive is saying to find any executable scripts within `/etc/logrotate.d/httpd-prerotate` (if the directory exists) and run them, giving us an avenue to run any scripts prior to rotation simply by putting them into the `/etc/logrotate.d/httpd-prerotate` directory.

### postrotate

Here we're simply backing up the log files to an Amazon S3 bucket. This uses [AWS's command line tool](http://aws.amazon.com/cli/), which is fairly easy to setup and use (install via Python's package manager Pip).

This script simply calls the S3 tool and "syncs" the log directory to the give S3 bucket. The "sync" command will keep the directories in sync, similar to the rsync utility.

This way we can allow Logrotate to delete old log files without losing any logs, as they are backed up to S3.

## More

This is covered in more details in the Servers for Hackers eBook!

However, here are some good resources you can read up on:

* [Logrotate man page](http://linuxcommand.org/man_pages/logrotate8.html), outlining the many options available.
* [Digital Ocean on logrotate](https://www.digitalocean.com/community/tutorials/how-to-manage-log-files-with-logrotate-on-ubuntu-12-10)


