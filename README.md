## IMPORTANT
**You really, really, really should not use this as a reference for anything. The code is terrible and will make you throw up. This also apparently does not work on iOS 6, and I no longer support it.**

# Aptdate - banner notifications for Cydia package updates

## Internals
* `aptdated`, a LaunchDaemon that runs every half hour (but only performs actions based on the user's set schedule). Grabs the CydiaUpdates RSS feed, then compares versions with what's currently installed. 

    (Clearly this could be done with better method than a few command line calls, but that's what it does for now.)
* the Aptdate BulletinBoard provider itself, which receives a notification from `aptdated` with the update list
* Aptdate scans through this array and presents a banner for the _last_ package in the list

    (That's not a typo, it _does_ only shows a banner for the last package that aptitude prints out. While this could be done better, presenting multiple notifications at once is not pretty.)
* an optional NC widget that displays statistics (last check date, data used) and allows for a manual refresh

## License
[GPL](http://gnu.org/copyleft/gpl.html). 
Daemon-to-tweak logic based on [`sbserver` by innoying](http://github.com/innoying/iOS-sbutils). 
Icons are [CC-BY](http://creativecommons.org/licenses/by/3.0), from [Jigsoar Icons](http://jigsoaricons.com). 
