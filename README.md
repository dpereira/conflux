Conflux [![Build status](https://travis-ci.org/dpereira/conflux.svg?branch=master)](https://travis-ci.org/dpereira/conflux)
=======

A [Synergy](http://synergy-project.org/) server for mobile devices.

Supported OSes:
---------------

 - iOS: in progress.
 - Android: planned.
 - Windows Phone: planned.

Leveraging a Personal Hotspot:
------------------------------

Using Conflux in an iOS device running a Personal Hotspot is a very straightforward way to extend the connectivity possibilities between a Synergy client and the Conflux/Synergy server, making it possible to connect them via Bluetooth, USB, or even wireless directly, without requiring access points.

To do so via bluetooth, follow these steps:

1. Enable bluetooth in your iOS device.

<div style="text-align:center">
<img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%201.PNG" width=200x/>
</div>

2. Enable bluetooth in the device running the Synergy client.
3. Enable the Personal Hotspot in your iOS device.
4. Pair both devices.
5. Start Conflux in your iOS device. It will begin listening for connections.
6. In the device running the client, connect to the Personal Hotspot by clicking in the /Connect to Network/ menu entry for the iOS in the bluetooth settings.
7. Find out your default gateway ip address. In OSX or Linux systems, you can do so via /route/, /traceroute/ or /ifconfig/ commands. If you have more interfaces active then the one used for the Personal Hotspot, pay attention to retrieve the gateway for correct one.
8. In the Synergy client settings, type in the IP address of the default gateway you've just retrieved, and click /Apply/.
9. Client and server should connect, and you should see the /Ready.../ label in the Conflux application change to the name of your client device.

These steps can be addapted to USB and direct wireless connections by modifying the steps 1-4 to whatever is needed to ensure both devices have a direct network data link between each other.
