#!/bin/bash

# Author:Guillaume Gète
# 26/12/2024

# Modifie le réglage du mode Économie d'énergie du Mac. 
# Vous pouvez utiliser ce script pour permettre à un utilisateur non-administrateur 
# de modifier ce réglage, par exemple en l'utilisant dans une règle Jamf dans Self Service.

# 1.0: Version initiale
# 1.1: Modification des réglages avec pmset pour éviter un redémarrage. Dialogues modifiés pour retirer la nécessité du reboot.


# L'utilitaire SwiftDialog doit être installé au préalable.
dialogPath="/usr/local/bin/dialog"


# Les lignes suivantes permettent d'installer le dernier PKG de SwiftDialog disponible.
# Si vous préférez garder le contrôle sur l'installation de SwiftDialog, modifiez ces lignes.

dialogPath="/usr/local/bin/dialog"
dialogURL=$(curl --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

if [ ! -e "$dialogPath" ]; then
	echo "L'outil dialog doit être installé au préalable."
	curl -L "$dialogURL" -o "/tmp/dialog.pkg"
	installer -pkg /tmp/dialog.pkg -target /
	
	if [ ! -e "$dialogPath" ]; then
		echo "Une erreur est survenue, dialog n'a pas pu être installé."
		exit 1
		elsel
		echo "L'outil dialog est disponible. On continue..."
	fi
else 
	echo "L'outil dialog est disponible. On continue..."
fi

# Chaînes de caractères utilisées pour définir chaque réglage d'économie d'énergie
neverLoc="Jamais"
onlyBatteryLoc="Seulement sur batterie"
onlyACLoc="Seulement sur adaptateur secteur"
alwaysLoc="Toujours"

# On a besoin du UUID Hardware du Mac, car le fichier de configuration est défini selon cet identifiant.
hardwareUUID=$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $(NF-1)}')

echo "Hardware UUID : $hardwareUUID"

# Chemin vers le fichier de préférences.
prefPath="/Library/Preferences/com.apple.PowerManagement.$hardwareUUID.plist"

if [ ! -f "$prefPath" ]; then
	echo "Impossible de modifier le fichier de préferences $prefPath, car il n'existe pas"
	exit 1
fi

echo "Fichier de préférence à modifier : $prefPath"

# On récupère l'état actuel du réglage d'économie d'énergie. 
# Ce dernier est défini selon l'utilisation du Mac sur secteur ou sur batterie uniquement.

batteryMode=$(/usr/libexec/PlistBuddy -c "Print Battery\ Power:LowPowerMode" "$prefPath")
echo "Mode actuel sur batterie : $batteryMode"

acMode=$(/usr/libexec/PlistBuddy -c "Print AC\ Power:LowPowerMode" "$prefPath")
echo "Mode actuel sur secteur : $acMode"

# Conversion de ces réglages en valeur binaire.

currentModeNumerical="$acMode$batteryMode"

# Selon la valeur, on peut déterminer le bon réglage dans l'interface.

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

echo "Mode actuel configuré : $currentMode"

# Affichage du dialogue et récupération du choix de l'utilisateur

energyChoice=$(dialog \
--selecttitle "Mode d'économie d'énergie :" \
--selectvalues "$neverLoc,$onlyBatteryLoc,$onlyACLoc,$alwaysLoc" \
--selectdefault "$currentMode" \
--small \
-m "Sélectionnez le mode d'économie d'énergie pour votre Mac :" \
-t "Mode d'économie d'énergie" \
--button1text "Modifier le réglage" \
-i sf=battery.100percent.circle,colour=orange,animation=pulse.bylayer | grep "SelectedIndex" | awk -F " : " '{print $NF}' )

echo "Choix d'économie d'énergie : $energyChoice"


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
-m "Le nouveau mode d'économie d'énergie sélectionné est : **$powerMode**. \n\nSouhaitez-vous l'appliquer ?" \
-t "Mode d'économie d'énergie" \
--button1text "Appliquer le réglage" \
--button2text "Annuler" \
-i sf=battery.100percent.circle,colour=orange,animation=pulse.bylayer

if [ $? = 2 ]; then
	exit 0
fi

# Application du nouveau réglage

pmset -b lowpowermode $newBatteryMode
pmset -c lowpowermode $newACMode

batteryMode=$(/usr/libexec/PlistBuddy -c "Print Battery\ Power:LowPowerMode" "$prefPath")
acMode=$(/usr/libexec/PlistBuddy -c "Print AC\ Power:LowPowerMode" "$prefPath")

echo "Mode actuel sur batterie : $batteryMode"
echo "Mode actuel sur secteur : $acMode"

dialog \
--small \
-t "Réglage modifié !" \
-m "Le mode d'économie d'énergie est désormais configuré sur : \n\n**$powerMode**." \
--button1text "OK" \
-i sf=battery.100percent.circle,colour=green,animation=pulse.bylayer

exit 0
