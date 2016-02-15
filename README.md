Conflux
=======

[![Build status](https://travis-ci.org/dpereira/conflux.svg?branch=master)](https://travis-ci.org/dpereira/conflux) [![License](https://img.shields.io/badge/license-GPLv2-blue.svg)](https://github.com/dpereira/conflux/blob/master/LICENSE.md)
 
A [Synergy](http://synergy-project.org/)-compatible server for mobile devices.

Conflux is a virtual KVM server that allows you to remotely control multiple Synergy-enabled computers through your mobile, by transforming it into a fully functional touchpad-and-keyboard.

Supported OSes:
---------------

 - iOS
  - In progress.
  - v0.2 released.

 - Android
  - Planned.

 - Windows Phone
  - Planned.

Usage:
------

By default, Conflux displays the touchpad view. To switch to the keyboard view, use the link in the top-right edge of the navigation bar. Supported touchpad gestures:

 - Sliding the touchpad with one finger will move the Synergy client screen mouse pointer accordingly.
 - A single tap will translate into a single mouse left-click in the client screen.
 - A single tap with two fingers will translate into a single right-click in the client screen.
 - Double tapping will translate into a double left-click in the client screen.
 - Long pressing with one finger will initiate a mouse drag movement; it will select whatever is under the mouse pointer in the client screen. The mobile phone will vibrate to indicate that the dragging has begun. After that, moving the touching finger in any direction will drag any selected item in the client screen. To finish the drag and perform a "drop", release the finger touching the mobile screen.
 - Sliding two fingers simultaneously will trigger a vertical mouse wheel scroll; horizontal mouse wheel scrolling is still not implemented.

Limitations:
------------

These are temporary limitations, and it is planned to remove them as soon as possible.

 - Only tested with Synergy 1.7 clients, in Windows and Mac OSX.
 - No support for SSL; clients must be configured to disable the support, or they won't be able to connect to the Conflux server.
 - The only keyboard mapping works best with en-US keyboard layout, and even in it not every character from the iOS keyboard are properly translated, event though all the ones needed for standard usage are.


Conflux + Personal Hotspot:
---------------------------

Using Conflux in an iOS device running a Personal Hotspot is a very straightforward way to extend the connectivity possibilities between a Synergy client and the Conflux/Synergy server, making it possible to connect them via Bluetooth, USB, or even wireless directly, without requiring access points or a previously configured network infrastructure.

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

These steps can be adapted to USB and direct wireless connections by modifying the steps 1-4 to whatever is needed to ensure both devices have a direct network data link between each other.
