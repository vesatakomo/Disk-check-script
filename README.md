##Disk health check/ report script

I have on my HP Proliant SAS disks under HP Raid and also some SATA disks. I wanted to have simple script which checks health data and sends details to my Telegram via self-hosted Apprise.

You need to have smartctl installed for SATA SMART info and ssacli for HP SAS disks.
Adjust your disk info at the beginning of script and also Apprise URL at the end of script.
