# macOS Low Power Mode script
Script for macOS, which allows a standard user account to change the Low Power Mode settings when run from Jamf's Self Service

## The issue
A requirement for many companies is to prevent users to run their own Mac as an admin user. However, standard user accounts in macOS are not allowed to change the Low Power Mode settings in System Settings.

![Screen capture of macOS System Settings > Battery](https://github.com/guillaumegete/macoslowpowermode/blob/main/low_power_mode_settings.png)

## The solution
As a result, I tried to create a script which, when called from Jamf's Self Service, can provide the same feature that you find in the Low Power settings, allowing a standard user to change the Low Power mode to :
- Never
- Only on Power Adapter
- Only on Battery
- Always.

This was tested on macOS 15 Sequoia, and runs fine on Intel and Apple Silicon Macs.

The script requires SwiftDialog (https://github.com/swiftDialog/swiftDialog), and will attempt to download the tool in its latest version if it's missing.

## How to use the script

There are at this time two versions of the script, in French and English (American). Feel free to adapt it to other languages. Add the script in Jamf Pro, and create a new policy that just runs this script.

The following dialogs will be displayed to guide the user to change its Low Power Mode settings.

![Screen capture 1](https://github.com/guillaumegete/macoslowpowermode/blob/main/low_power_mode_1.png)
![Screen capture 2](https://github.com/guillaumegete/macoslowpowermode/blob/main/low_power_mode_2.png)
![Screen capture 3](https://github.com/guillaumegete/macoslowpowermode/blob/main/low_power_mode_3.png)
