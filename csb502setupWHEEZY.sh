#!/bin/bash

set -e
#TODO: these writes are for wheezy, make jessie vesrion

if [[ $EUID -ne 0 ]]; then
    echo "must be run as root. try: sudo $0"
	exit 1
fi
# TODO, make backup
# setup dallas 1-wire temp sensor
grep -q '^w1-gpio' /etc/modules && sed -i 's/^w1-gpio.*/w1-gpio pullup=1/' /etc/modules || echo 'w1-gpio pullup=1' >> /etc/modules
grep -q '^w1-therm' /etc/modules && sed -i 's/^w1-therm.*/w1-therm strong_pullup=1/' /etc/modules || echo 'w1-therm strong_pullup=1' >> /etc/modules
grep -q '^dtoverlay=w1-gpio' /boot/config.txt && sed -i 's/^dtoverlay=w1-gpio.*/dtoverlay=w1-gpio,gpiopin=23,pullup=on/' /boot/config.txt || echo 'dtoverlay=w1-gpio,gpiopin=23,pullup=on' >> /boot/config.txt

#enable i2c1, alias i2c_arm
grep -q '^i2c-dev' /etc/modules && sed -i 's/^i2c-dev.*/i2c-dev/' /etc/modules || echo 'i2c-dev' >> /etc/modules
grep -q '^dtparam=i2c_arm' /boot/config.txt && sed -i 's/^dtparam=i2c_arm.*/dtparam=i2c_arm=on/' /boot/config.txt || grep -q '^dtparam=i2c1' /boot/config.txt && sed -i 's/^dtparam=i2c1.*/dtparam=i2c_arm=on/' /boot/config.txt || echo 'dtparam=i2c_arm=on' >> /boot/config.txt

# setup rtc
grep -q '^rtc-ds1307' /etc/modules || echo 'rtc-ds1307' >> /etc/modules
grep -q '^sudo hwclock -s' /etc/rc.local && sed -i 's/^sudo hwclock -s.*/hwclock -s/' /etc/rc.local || grep -q '^hwclock -s' /etc/rc.local || sed -i '/exit 0/ ihwclock -s' /etc/rc.local
grep -q '^echo ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device' /etc/rc.local || sed -i '/^hwclock -s/ iecho ds1307 0x68 > /sys/class/i2c-adapter/i2c-1/new_device' /etc/rc.local



read -r -p "Would you like to setup Wifi network name and password? [y/N] " response
case $response in
    [yY][eE][sS]|[yY]) 
        echo -n "Enter the network name (ESSID, case sensitive):" 
		read -r essid
		echo -n "Enter the network password (case sensitive):"
		read -r wifipass
	
		echo 'network={' >> /etc/wpa_supplicant/wpa_supplicant.conf
		echo '    ssid="The_ESSID_from_earlier"' >> /etc/wpa_supplicant/wpa_supplicant.conf
		echo '    psk="Your_wifi_password"' >> /etc/wpa_supplicant/wpa_supplicant.conf
		echo '}' >> /etc/wpa_supplicant/wpa_supplicant.conf
        ;;
    *)
        echo "OK, not configuring network name/pass"
        ;;
esac

echo -n "Enter the network name (ESSID, case sensitive):" 
read essid
echo -n "Enter the network password (case sensitive):"
read wifipass

#remove old entry for network={...}

sed -i /^network=/,/}/d /etc/wpa_supplicant/wpa_supplicant.conf

echo 'network={' >> /etc/wpa_supplicant/wpa_supplicant.conf
echo '    ssid="$essid"' >> /etc/wpa_supplicant/wpa_supplicant.conf
echo '    psk="$wifipass"' >> /etc/wpa_supplicant/wpa_supplicant.conf
echo '}' >> /etc/wpa_supplicant/wpa_supplicant.conf



sync
echo
echo "Configuration Complete! Please Reboot..."
echo

exit 0


