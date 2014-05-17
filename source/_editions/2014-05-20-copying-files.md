---
title: Copying Files
topics: [Copying Files (remotely)]

---

After an awesome week at Laracon, I have a short (but sweet) edition Servers for Hackers to share. During Laracon, many people expressed gratitude for SFH and [Vaprobash](https://github.com/fideloper/vaprobash). I'm still taken aback - that's so awesome. I'm so glad this content is found to be so useful!

<a name="copying_files" id="copying_files"></a>

## Copying Files

So there's quite a few ways of copying files using the command line. Of course we can copy files inside of our own computer, but often **we need to copy files across servers**! There's a few strategies for doing so, which we'll cover here in a little more detail.

### Locally Copying Files

I suspect this is a boring part of the newsletter - I'll cover it quickly. We can use the `cp` command:

Copy a file:

    $ cp /path/to/source/file.ext /path/to/destination/

    # Or rename it
    $ cp /path/to/source/file.ext /path/to/destination/new-filename.ext

To copy a directory, we copy recursively with the `-r` flag:

    $ cp -r /path/to/source/dir /path/to/destination
    # Result: /path/to/destination/dir exists!

### SCP: Secure Copy

Secure Copy is the `cp` command, but secure...and more importantly, with the ability to send files to remote servers. It can use SSH and so works just like it, except instead of logging into a server, we're just copying files.

Copy a file or a remote server:

    # Copy a file:
    $ scp /path/to/source/file.ext username@server-host.com:/path/to/destination/file.ext

    # Copy a directory:
    $ scp -r /path/to/source/dir username@server-host.com:/path/to/destination

This will attempt to connect to `server-host.com` as user `username`. It will ask you for a password if there's no SSH key setup (or if you don't have a password-less SSH key setup between the two computers). If the connection is authenticated, the file will be copied to the remote server.

Since this works just like SSH (using SSH, in fact), we can add flags normally used with the SSH command as well. For example, you can add the `-v` and/or `-vvv` to get various levels of verbosity in output about the connection attempt and file transfer.

You can also use the `-i` (identity file) flag to specify an SSH identity file to use:

    $ scp -i ~/.ssh/some_identity.pem /path/to/source/file.ext username@server:/path/to/destination/file.ext

Here's some other useful flags:

    (look up tecmint.com - 10 scp commands)