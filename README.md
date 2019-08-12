# happi
happi aims to expose the GPIO pins of a Raspberry Pi as HomeKit accessories via Apple's HomeKit Accessory Protocol.

# Roadmap
### 0.1 Project start
* device boot. ✅
* Wifi support. ✅
* TLV library. ✅
* SRP support. ✅
* Bonjour support. ✅
* nerves\_init\_gadget: Remove my custom init & bonjour setup in favor of nerves\_init\_gadget. ✅
### 0.2 Initial pairing support
* pair\_setup: Allow pairing of new iOS devices. Almost. Pairing fails at m5.
### 0.3 Full pairing support
* add\_pairing endpoint.
* pairings endpoint.
* identify endpoint.
### 0.4 Accessory support
* accessories endpoint.
* characteristics endpoint.
### 0.5 GPIO support

# Usage
Happi is not useful. At all. If you're so inclined you can run it on a raspberry pi and get to the point where pairing fails. It's very rewarding, I assure you.

## Setup
This is a fairly standard Elixir project dependent on the Nerves and Phoenix libraries. It's setup as a "poncho" project, which is a single repo that (in this case) contains 2 apps: `fw` (the Nerves app that allows the project to run on a Raspberri Pi) and `hap` (The HomeKit Accessory Protocol implementation.) To compile and run it you will need to have Elixir and Nerves set up.

There's a script in the top level directory that will set the required environment variables for you (because I got tired of copy-pasting them.) Run it with `source configure.sh` inside the project directory. Then do the standard `mix firmware` & `mix firmware.burn` and that stuff.

Once running you can ssh into the app at `happi.local` and muck around. Again: Keep your expectations low and you'll be happier.

# Acknowledgements
Special thanks to @fhunleth for his generous assistence bringing libsalty's make file into the Nerves world.