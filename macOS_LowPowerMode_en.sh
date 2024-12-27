#!/bin/bash

# Author: Guillaume Gète
# 26/12/2024

# Change the Mac's Low Power mode setting. You can use this script 
# to allow a non-standard user to change this setting, i.e as a Jamf Policy in Self Service

# 1.0: initial release
# 1.1: modified settings with pmset to avoid reboot. Changed dialogs to remove the need for reboot.

# The SwiftDialog utility must be installed beforehand.
# https://api.github.com/repos/bartreardon/swiftDialog/releases/latest

dialogPath="/usr/local/bin/dialog"

# The next lines allow to install the latest SwiftDialog PKG available.
# If you prefer to keep control on your SwiftDialog install, change this appropriately.

dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

if [ ! -e "$dialogPath" ]; then
	echo "The SwiftDialog command line tool must be installed first."
	curl -L "$dialogURL" -o "/tmp/dialog.pkg"
	installer -pkg /tmp/dialog.pkg -target /
	
	if [ ! -e "$dialogPath" ]; then
		echo "An error occurred. The SwiftDialog tool could not be installed."
		exit 1
	else
		echo "SwiftDialog is installed. Moving on…"
	fi
else 
	echo "SwiftDialog is installed. Moving on…"
fi

# Strings used to define each energy-saving setting in System Settings > Battery
neverLoc="Never"
onlyBatteryLoc="Only on Battery"
onlyACLoc="Only on Power Adapter"
alwaysLoc="Always"

# We need the Mac's hardware UUID because the configuration file is defined using this identifier.
hardwareUUID=$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $(NF-1)}')

echo "Hardware UUID: $hardwareUUID"

# Path to the preferences file.
prefPath="/Library/Preferences/com.apple.PowerManagement.$hardwareUUID.plist"

if [ ! -f "$prefPath" ]; then
	echo "Cannot modify the preferences file $prefPath because it does not exist."
	exit 1
fi

echo "Preferences file to modify: $prefPath"

# Retrieve the current state of the energy-saving setting.
# This is defined based on whether the Mac is used on AC power or battery only.

batteryMode=$(/usr/libexec/PlistBuddy -c "Print Battery\ Power:LowPowerMode" "$prefPath")
echo "Current battery mode: $batteryMode"

acMode=$(/usr/libexec/PlistBuddy -c "Print AC\ Power:LowPowerMode" "$prefPath")
echo "Current AC mode: $acMode"

# Convert these settings into binary values.

currentModeNumerical="$acMode$batteryMode"

# Based on the value, determine the correct setting in the interface.

case $currentModeNumerical in
	00)
		currentMode="$neverLoc"
	;;
	01)
		currentMode="$onlyBatteryLoc"
	;;
	10)
		currentMode="$onlyACLoc"
	;;
	11)
		currentMode="$alwaysLoc"
	;;
esac

echo "Currently configured mode: $currentMode"

# Display the dialog and get the user's choice

energyChoice=$(dialog \
--selecttitle "Low Power Mode:" \
--selectvalues "$neverLoc,$onlyBatteryLoc,$onlyACLoc,$alwaysLoc" \
--selectdefault "$currentMode" \
--small \
-m "Select the Low Power Mode for your Mac:" \
-t "Low Power Mode" \
--button1text "Change Setting" \
-i sf=battery.100percent.circle,colour=orange,animation=pulse.bylayer | grep "SelectedIndex" | awk -F " : " '{print $NF}' )

echo "Energy-saving choice: $energyChoice"


case "$energyChoice" in
	0)
		newACMode=0
		newBatteryMode=0
		powerMode="$neverLoc"
	;;
	1)
		newACMode=0
		newBatteryMode=1
		powerMode="$onlyBatteryLoc"
	;;
	2)
		newACMode=1
		newBatteryMode=0
		powerMode="$onlyACLoc"
	;;
	3)
		newACMode=1
		newBatteryMode=1
		powerMode="$alwaysLoc"
	;;
esac

dialog \
--selectdefault "$currentMode" \
--small \
-m "The new selected Low Power Mode is: **$powerMode**. \n\nDo you want to apply it?" \
-t "Low Power Mode" \
--button1text "Apply Setting" \
--button2text "Cancel" \
-i sf=battery.100percent.circle,colour=orange,animation=pulse.bylayer

if [ $? = 2 ]; then
	exit 0
fi

# Apply the new setting

pmset -b lowpowermode $newBatteryMode
pmset -c lowpowermode $newACMode

batteryMode=$(/usr/libexec/PlistBuddy -c "Print Battery\ Power:LowPowerMode" "$prefPath")
acMode=$(/usr/libexec/PlistBuddy -c "Print AC\ Power:LowPowerMode" "$prefPath")

echo "Current battery mode: $batteryMode"
echo "Current AC mode: $acMode"

# Final dialog

dialog \
--small \
-t "Setting Modified!" \
-m "The energy-saving mode is now configured to: \n\n**$powerMode**" \
--button1text "OK" \
-i sf=battery.100percent.circle,colour=green,animation=pulse.bylayer

exit 0
