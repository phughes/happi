# happi
happi aims to expose the GPIO pins of a Raspberry Pi as HomeKit accessories via Apple's HomeKit Accessory Protocol.

# Roadmap
### 0.1 Project start
* device boot. ✅
* Wifi support. ✅
* TLV library. ✅
* SRP support. ✅
* Bonjour support. ✅
### 0.2 Initial pairing support
* pair_setup: Allow pairing of new iOS devices. Almost. Pairing fails at m5.
### 0.3 Full pairing support
* add\_pairing endpoint.
* pairings endpoint.
* identify endpoint.
* nerves\_init\_gadget: Remove my custom init & bonjour setup in favor of nerves\_init\_gadget.
### 0.4 Accessory support
* accessories endpoint.
* characteristics endpoint.
### 0.5 GPIO support


# Acknowledgements
Special thanks to @fhunleth for his generous assistence bringing libsalty's make file into the Nerves world.