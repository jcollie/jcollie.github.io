---
layout:     post
title:      "NixOS Binary Cache 2022"
date:       2022-04-26 21:35:48 -0500
categories: nixos
---

Set up [`minio`](https://github.com/minio/minio) somewhere. I'm not going to include setup instructions for `minio` but you'll need to ensure that Minio is accessible via `https` using a trusted certificate. [Let's Encrypt](https://letsencrypt.org/) will be helpful here.

You'll need to generate a password for the minio root user. There are many ways but I like using `pwgen`.

```shell
$ pwgen 32 1
```

That generates a 32 character random string, which is probably good enough. Any method that you prefer generates a strong password is fine.

You'll also need to generate a password for the `nixbuilder` user we'll create later on our `minio` instance.

Install the [`minio` command line client `mc`](https://github.com/minio/mc). Create or edit `~/.mc/config.json`.

```json
{
	"version": "10",
	"aliases": {
		"s3": {
			"url": "https://s3.example.org",
			"accessKey": "<minio root user>",
			"secretKey": "<minio root password>",
			"api": "s3v4",
			"path": "auto"
		}
	}
}
```
Create a file called `nix-cache-write.json` with the following contents.

```json
{
    "Id": "AuthenticatedWrite",
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AuthenticatedWrite",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts",
                "s3:PutObject"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::nix-cache",
                "arn:aws:s3:::nix-cache/*"
            ],
            "Principal": "nixbuilder"
        }
    ]
}
```

Create a file called `nix-cache-info` with the following contents:

```
StoreDir: /nix/store
WantMassQuery: 1
Priority: 40
```

Then run these commands to configure `minio` for anonymous reads and authenticated writes:

```shell
$ mc mb s3/nix-cache
$ mc admin user add s3 nixbuilder <nixbuilder password>
$ mc admin policy add s3 nix-cache-write nix-cache-write.json
$ mc admin policy set s3 nix-cache-write user=nixbuilder
$ mc policy set download s3/nix-cache
$ mc cp ./nix-cache-info s3/nix-cache/nix-cache-info
```

This command will be useful to watch traffic on your `minio` server to see what's happening.

```shell
$ mc admin trace s3
```

Edit `~/.config/nix/nix.conf` and add this line. Enabling the `nix-command` experimental feature appears to be necessary because the older commands don't appear to work fully.

```
extra-experimental-features = nix-command flakes
```

Generate a secret and public key for signing store paths. The key name is arbitrary but the NixOS developers highly recommend using the domain name of the cache followed by an integer. If the key ever needs to be revoked or regenerated the trailing integer can be incremented.


```shell
$ nix key generate-secret --key-name s3.example.org-1 > ~/.config/nix/secret.key
$ nix key convert-secret-to-public < ~/.config/nix/secret.key > ~/.config/nix/public.key
```

Edit `~/.config/nix/nix.conf` and add this line:
```
secret-key-files = ~/.config/nix/secret.key
```

Add these lines to `/etc/nix/nix.conf`. The public key can be found in `~/.config/nix/public.key`.

```
substituters = https://s3.example.org/nix-cache/ https://cache.nixos.org/
trusted-public-keys = s3.example.org-1:<your public key> cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
trusted-users = <your username>
```

The URLs in `substituters` and keys in `trusted-public-keys` must be listed in the same order.

Restart `nix-daemon.service`.

Create or edit `~/.aws/credentials` and add this section.

```ini
[nixbuilder]
aws_access_key_id=nixbuilder
aws_secret_access_key=<nixbuilder password>
```

Sign some paths in the local store.

```shell
$ nix store sign --recursive --key-file ~/.config/nix/secret.key <store path>
```

Copy those paths to the cache.

```shell
$ nix copy --to 's3://nix-cache?profile=nixbuilder&endpoint=s3.example.org' <store path>
```

If you are watching the `minio` status with `mc admin trace s3` you should see
