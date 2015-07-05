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

  <p align="center">
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%201.PNG" height=275x/>
  </p>

2. Enable bluetooth in the device running the Synergy client.
  <p align="center">
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%202.PNG" width=300x/>
  </p>

3. Enable the Personal Hotspot in your iOS device.
  <p align="center">
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%203a.PNG" height=275x/>
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%203b.PNG" height=275x/>
  </p>

4. Pair both devices.
  <p align="center">
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%204a.PNG" height=275x/>
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%204b.PNG" height=275x/>
  </p>

5. Start Conflux in your iOS device. It will begin listening for connections.
  <p align="center">
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%205.PNG" height=275x/>
  </p>

6. In the device running the client, connect to the Personal Hotspot by clicking in the _Connect to Network_ menu entry for the iOS in the bluetooth settings.
  <p align="center">
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%206.PNG" height=275x/>
  </p>

7. Find out your default gateway ip address. In OSX or Linux systems, you can do so via _route_, _traceroute_ or _ifconfig_ commands. If you have more interfaces active then the one used for the Personal Hotspot, pay attention to retrieve the gateway for correct one.
  <p align="center">
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%207.PNG" width=300x/>
  </p>

8. In the Synergy client settings, type in the IP address of the default gateway you've just retrieved, and click _Start_ or _Apply_.
  <p align="center">
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%208.PNG" height=275x/>
  </p>

9. Client and server should connect, and you should see the _Ready..._ label in the Conflux application change to the name of your client device.
  <p align="center">
  <img src="https://raw.githubusercontent.com/dpereira/conflux/master/doc/img/step%209.PNG" height=275x/>
  </p>

10. You can now use the default view as if it were a touchpad, and the mouse cursor in the client device should respond to your input. If you want to go to the keyboard and back again, use the navigation links in the navigation bar at the top of the application. Enjoy!

These steps can be addapted to USB and direct wireless connections by modifying the steps 1-4 to whatever is needed to ensure both devices have a direct network data link between each other.
