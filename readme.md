V.0.0.0.27.02.23	early alpha
V.0.0.1.20.3.23 	termux
V.0.0.2.19.4.23		radio.net scraper

Use an (old) Android device as multimedia player with remote control through nodered running on a pi.

INSTALLATION ON RASPBERRY PI

This project was originally intended for a Raspberry Pi.
The Android device is connected via USB. Developer mode must be activated on the Android device.

When this is done, the code under /autoadb ensures that the Android device can be remotely controlled via ADB.

A total of four APKs should be installed on the device: VLC, Smart Tube, IPTV Extreme and a Daydream application (such as Lucid Clock).
The lock screen type MUST be disabled. The first time the Raspberry Pi tries to connect to the Android device, the MAC of the Pi must be confirmed.

A nodered server must be running on the Pi, which can then be used by any device in the network that has a browser.

http://XXX.XXX.XXX.XXX:1880/ui/

access the nodered server and run the remote control. The required flow for the nodered server is in the folder

nodered/flows.json

This flow must be imported into the noded system.

All components must be installed and configured by hand.
The Lissi system itself is installed with Git:

cd opt
sudo mkdir lissi
sudo chown root:nodered lissi
sudo chmod 770 lissi
git clone https://github.com/kdeiss/lissi






INSTALLATION ON ANDROID DEVICE

Later, an installation type was added where the nodered server is installed directly on the Android device.

In addition to the apps VLC, Smart Tube, IPTV Extreme and a Daydream application (e.g. Lucid Clock), the following apps must also be installed:

- Termux
- Termux:API
- Termux: boat

These apps are loaded at https://f-droid.org/de/packages/com.termux/

An installation script is available for this type of installation, which (unlike on the Raspi) carries out a complete installation of ALL required components.

Then in the Termux terminal:

apt install wget;
wget https://raw.githubusercontent.com/kdeiss/lissi/master/termux/setup/setup_lissi.sh;
bash ./setup_lissi.sh

This installation has a larger range of functions than the Raspian version. In order to be able to use this, the Termux Flow must be activated in Nodered.

Unfortunately, there is one but one big downside. This consists in the fact that under Termux ADB cannot be activated. Thus, after a boot, all functions based on ADB are missing.
And that's almost all of them!

For everything get to work, ADB must be restarted in TCP mode. This is usually done by the command on a device connected via USB:

adb tcpip 5555

Personally, I do this by briefly connecting the devices to a Raspi running AUTOADB when I restart (see installation method 1).
This executes the required command (adb tcpip 5555) automatically. After that, the Androd device can be removed from the USB and operated independently.
