## Disk health check/ report script

I have on my 2 HP Proliant setups SAS disks under HP Raid and also some SATA disks. I wanted to have simple script which checks health data weekly and sends details to my Telegram via self-hosted Apprise.

I have been using this script on my main Proxmox server as well as on my secondary backup server which is OpenMediaVault with Snapraid & MergerFS.

You need to have smartctl installed for SATA SMART info and ssacli for HP SAS disks.
Adjust your disk info at the beginning of script and also Apprise URL at the end of script.
