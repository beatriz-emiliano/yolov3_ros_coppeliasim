This is the Debian/Ubuntu release V4.3, 64bit

To launch CoppeliaSim, run FROM THE COMMAND LINE:

$ ./coppeliaSim.sh 

Issues you might run into:

1.  When trying to start CoppeliaSim, following message
    displays: "Error: could not find or correctly load
    the CoppeliaSim library"
    a) Make sure you started CoppeliaSim with
       "./coppeliaSim.sh" from the command line
    b) check what dependency is missing by using the
       file "libLoadErrorCheck.sh"

2.  You are using a dongle license key, but CoppeliaSim
    displays 'No dongle was found' at launch time.
    a) $ lsusb
    b) Make sure that the dongle is correctly plugged
       and recognized (VID:1bc0, PID:8100)
    c) $ sudo cp 92-SLKey-HID.rules /etc/udev/rules.d/
    d) Restart the computer
    e) $ ./coppeliaSim.sh

