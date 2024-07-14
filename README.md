# ulb

ulb is the command line tool for Linux. Copy or move to `/usr/local/bin`, or list files of `/usr/local/bin`.

# Download

Download `.sh` file.

```
wget https://raw.githubusercontent.com/saihon/ulb/main/ulb.sh
```

Change file mode and move to somewhere

```
chmod 755 ulb.sh && sudo mv ulb.sh /usr/local/bin
```

# Usage

Copy. File mode change to 755 and copy it to `/usr/local/bin`

```
$ ulb.sh -c file
```

Move. File mode change to 755 and move it to `/usr/local/bin`

```
$ ulb.sh -m file
```

Remove. Remove file in `/usr/local/bin`
```
$ ulb.sh -r file
```

Show list files.
```
$ ulb.sh -l
```
