AutoWebDocSync
==================

AutoWebDocSync is a ruby-based tool to synchronize document files on the web like PDF with your local directory for MacOS. The scripts use `launchctl` command of MacOSX that loads and unloads the setting files which has schedules when to run scripts. It is similar to cron on the Linux system. See [launchctl](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man1/launchctl.1.html) for the details.

Originally, I created this project because I wanted to check and download the latest AWS documents automatically every day, so as a default, AWS pdf documents will be downloaded to your local directory, and keep checking every 2 hours. 

Moreover, this project supports running your original scripts by putting your script on the `script` directory and writing a setting file. 


## Requirements

- MacOSX
- Ruby-1.9.3 or later
- (optional) terminal-notifier
  - "terminal-notifier" enables scripts to notify messages through the Notification Center of MacOSX.
   - You can receive a notification when downloading a latest document with "terminal-notifier".
  - To install "terminal-notifier", just run `brew install terminal-notifier` through home brew.
  - See [terminal-notifier](https://github.com/alloy/terminal-notifier) for the details.


## Getting Started

As a default setting, AWS pdf documents will be downloaded to the `$HOME/Documents/aws-docs` directory, and keep checking every 2 hours.  

- Download this project.

```
git clone https://github.com/mmasashi/autowebdocsync
```

- Move to the project home directory and run the following command.

```
cd autowebdocsync
bin/launchctlall.rb load
```


Run the following command to check the registered settings.

- `bin/launchctlall.rb list`

Run the following command to unload the registered settings.

- `bin/launchctlall.rb unload` 


Run the following command to create or update plist files for launchctl. It's usuful for debugging scripts.

- `bin/launchctlall.rb update`


## Files and Directories

```
bin
  +- launchctlall.rb  # load, unload and check the setting.
conf
  +- settings.yml     # setting file for launchctlall.rb command
lib                   # common ruby libary
plist                 # auto generated setting files for launchctl
script                # script files
script_conf           # auto generated setting files for each script
script_log            # log files of scripts
```

## Configurations

- Configuration file path is `confs/settings.yml`


### Basic

- `default:` The part that you can put default settings for all.
- `script ` The part that you write a setting for each group. 

- `name`(required) ID of each script. This item must belong to each script and be unique.
- `script_name` The script name which you want to run.
  - This parameter should be changed only when you want to put your own script. 
- `enabled` If false, the setting will not be registered.
- `launchctl_parameters` The parameters of the settings for `launchctl`.
  - See [launchd.plist](https://developer.apple.com/library/mac/documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html#//apple_ref/doc/man/5/launchd.plist) for the details.


### AutoWebDocSync

- `log_level` Log level. debug, info(default), warn or error.
- `sync_dir_path` The directory path to put the downloaded file.
- `web_doc_base_url`(optional) The url of the base directory of documents. 
- `web_doc_file_names` The file name or url list of documents.


## License

This project is liscensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0.html) and powered by [Hapyrus Inc](http://hapyrus.com).
