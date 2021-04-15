// Performs a simple launch, orbit, circulize, deploy cargo, deorbit and land
print "Waiting for unpack".
wait until ship:unpacked.

lock cpuActiveLights to SHIP:PARTSTAGGED("cpuActiveLight").

clearscreen.
switch to 0.
print "CPU now connected to KSP and is ready".

// Check if we're in a prelaunch phase, tells us it's time to launch
if SHIP:STATUS = "PRELAUNCH" {
    print "Executing automated launch".
    lights off.

    // Turn on the CPU Active Warning Lights
    for sp in cpuActiveLights {
        if sp:HASMODULE("ModuleLight") {
            if sp:GETMODULE("ModuleLight"):HASACTION("turn light on") {
                sp:GETMODULE("ModuleLight"):DOACTION("turn light on", true).
            }
        }
    }

    // Execute main launch script
    run once "probelaunch"(150000,50000,0.6).
    wait 5.

    // Turn on the CPU Active Warning Lights
    for sp in cpuActiveLights {
        if sp:HASMODULE("ModuleLight") {
            if sp:GETMODULE("ModuleLight"):HASACTION("turn light off") {
                sp:GETMODULE("ModuleLight"):DOACTION("turn light off", true).
            }
        }
    }
}

