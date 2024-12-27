# macOS Low Power Mode script
Script which allows a standard user to change the Low Power Mode settings as a standard user

## The issue
A requirement for many companies is to prevent users to run their own Mac as an admin user. However, standard user accounts in macOS are not allowed to change the Low Power Mode settings in System Settings.

## The solution
As a result, I tried to create a script that, when called from Jamf's Self Service, can provide the same feature that you find in the Low Power settings, allowing a standard user to change the Low Power mode to :
- Never
- Only on Power Adapter
- Only on Battery
- Always.

This was tested on macOS 15 Sequoia, and runs fine on Intel and Apple Silicon Macs.

The script requires SwiftDialog (https://github.com/swiftDialog/swiftDialog), and will attempt to download the tool in its latest version if it's missing.

## How to use the script

There are at this time two versions of the script, in French and English (American). Feel free to adapt it to other languages. Add the script in Jamf Pro, and create a new policy that just runs this script.

## Why the need to reboot?
I did not manage to find a way to relauch the proper service that takes care of this setting. Rebooting just after modifying the setting does apply it. If you find the right service to relaunch, please feel free to provide some feedback.
