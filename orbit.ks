// ***************************************************************************
// Performs a simple launch and circuliazation
//
// Copyright 2021 TLabs Technology Foundry
// ***************************************************************************

// SEE https://i.imgur.com/WEE4ddH.png
declare parameter targetAP is 100000, turnEnd is 50000, turnExponent is 0.6.

set currentPhase to 0.
set startingAltitude to SHIP:ALTITUDE.
lock stageDeltaV to SHIP:STAGEDELTAV(9999):CURRENT.
lock stageBurnTime to SHIP:STAGEDELTAV(9999):DURATION.

clearscreen.

// Setup for Launch, get the trays stowed and seatbacks up
if SHIP:STATUS = "PRELAUNCH" {
    print "Ship is now preparing for launch".
    SAS OFF.
    RCS OFF.
    lights OFF.
    gear OFF.
    panels OFF.
    lock throttle to 0.
} else {
    print "ERROR: This program can only be from prelaunch from KSP".
    lock throttle to 0.
    set currentPage to 99.
}

WHEN throttle > 0 AND currentPhase < 99 THEN {
    if stageBurnTime < 0.9 {
        print "STAGING NOW".
        wait 1.
        stage.
        preserve.
    } else {
        wait 0.25.
        preserve.
    }
}

until currentPhase = 99 {

    // Ship is sitting on the launchpad
    if currentPhase = 0 {
        clearscreen.
        print "LAUNCH PHASE".
        print "-------------".
        lock steering to UP.
        lock throttle to 1.
        stage.
        set currentPhase to 1.
    // Ship has launched and beginning the gravity turn
    } else if currentPhase = 1 {
        set currentAltitude to SHIP:ALTITUDE - startingAltitude.

        // Can't remember where I stole this formula from
        set targetPitch to 90 * (1 - (currentAltitude / turnEnd) ^ turnExponent).

        lock steering to heading (90, targetPitch).

        if SHIP:ALTITUDE > turnEnd or OBT:APOAPSIS > targetAP {
            print "TURN FINISHED".
            set currentPhase to 2.
        } else {
            clearscreen.
            print "GRAVITY TURN PHASE".
            print "----------------------------------------".
            print "        Altitude: " + ROUND(ROUND(SHIP:ALTITUDE), 2) + "m".
            print "     Pitching to: " + ROUND(targetPitch, 2) + "°".
            print "      Current AP: " + ROUND(OBT:APOAPSIS) + "m / " + targetAp + "m".
            print "Current Velocity: " + ROUND(VELOCITY:ORBIT:MAG) + "m/s".
            print "        Stage ΔV: " + ROUND(SHIP:STAGEDELTAV(99999):CURRENT, 2) + "m/s".
            print " Stage Burn Time: " + ROUND(SHIP:STAGEDELTAV(99999):DURATION, 1) + "s".
            wait 0.1.
        }

    // Ship has finished gravity turn, time to coast and circulaize
    } else if currentPhase = 2 {
        if OBT:APOAPSIS >= targetAP {

            lock throttle to 0.
            lock targetVel to (SQRT(CONSTANT:G * OBT:BODY:MASS / (OBT:APOAPSIS + OBT:BODY:RADIUS)) - SHIP:VELOCITY:ORBIT:MAG) * 1.05.

            until ETA:APOAPSIS < 60 {
                clearscreen.
                print "COASTING TO AP".
                print "----------------------------------------".
                print "             Altitude: " + ROUND(ROUND(SHIP:ALTITUDE), 2) + " m".
                print "           Current AP: " + ROUND(OBT:APOAPSIS) + "m / " + targetAp + "m".
                print "           Time to AP: " + ROUND(OBT:ETA:APOAPSIS,1) + "s".
                print "Estimated required ΔV: " + ROUND(targetVel, 2) + "m/s".
                print "     Current Velocity: " + ROUND(VELOCITY:ORBIT:MAG) + "m/s".
                print "             Stage ΔV: " + ROUND(SHIP:STAGEDELTAV(99999):CURRENT, 2) + "m/s".
                print "      Stage Burn Time: " + ROUND(SHIP:STAGEDELTAV(99999):DURATION, 1) + "s".
                wait 0.25.
            }.

            print "Adding circulaization maneuver node".

            set burnAt to time:seconds + ETA:APOAPSIS.
            set circNode to NODE( burnAt, 0, 0, targetVel ).
            ADD circNode.

            RUN "autonode.ks".

            set currentPhase to 99.

        }
    }

}

unlock steering.
unlock throttle.
SAS OFF.
RCS OFF.
lights ON.
gear OFF.
//panels ON.

print "CONTROL RELEASED".
