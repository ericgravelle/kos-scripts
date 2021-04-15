// ***************************************************************************
// Launches a probe into orbit, detaches it's payload and deorbits itself
//
// Copyright 2021 TLabs Technology Foundry
// ***************************************************************************

// SEE https://i.imgur.com/WEE4ddH.png for turnExponent and turnEnd
declare parameter targetAP is 100000, turnEnd is 50000, turnExponent is 0.6.

set currentPhase to 0.
set startingAltitude to SHIP:ALTITUDE.
lock currentAltitude to SHIP:ALTITUDE.
lock radioAltitude to ALT:RADAR.
lock verticleSpeed to SHIP:VERTICALSPEED.
lock fromTheStandAltitude to (currentAltitude - startingAltitude).

lock safePanels to SHIP:PARTSTAGGED("safeDeployPanel").
lock sourceTanks to SHIP:PARTSTAGGED("launcherTank").
lock destinationTanks to SHIP:PARTSTAGGED("probeTank").
lock launcherLights to SHIP:PARTSTAGGED("launcherLight").
lock stageDeltaV to SHIP:STAGEDELTAV(9999):CURRENT.
lock stageBurnTime to SHIP:STAGEDELTAV(9999):DURATION.

lock doAutoStaging to FALSE.

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

    for sp in launcherLights {
        if sp:HASMODULE("ModuleLightEva") {
            print sp:GETMODULE("ModuleLightEva").
            if sp:GETMODULE("ModuleLightEva"):HASACTION("turn light on") {
                sp:GETMODULE("ModuleLightEva"):DOACTION("turn light on", true).
            }
        } else if sp:HASMODULE("ModuleColoredLensLight") {
            if sp:GETMODULE("ModuleColoredLensLight"):HASACTION("turn light on") {
                sp:GETMODULE("ModuleColoredLensLight"):DOACTION("turn light on", true).
            }
        } else {
            print "WARNING - THESE PARTS ARE NOT MAPPED".
            print sp.
            print sp:ALLMODULES.
        }
    }
} else {
    print "ERROR: This program can only be from prelaunch from KSP".
    lock throttle to 0.
    lock currentPage to 99.
}

WHEN throttle > 0 AND doAutoStaging THEN {
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

        lock doAutoStaging to FALSE.

        SET X TO 10.
        UNTIL X = 0 {
            print "AUTO-LAUNCHING IN " + X + " SECONDS.  PRESS CTRL-C TO ABORT.".
            set X to X - 1.
            wait 1.0.
        }

        lock steering to UP.
        lock throttle to 1.
        stage.
        set currentPhase to 1.
        lock doAutoStaging to TRUE.
    // Ship has launched and beginning the gravity turn
    } else if currentPhase = 1 {
        // Can't remember where I stole this formula from
        if fromTheStandAltitude > 250 {
            set targetPitch to 90 * (1 - (currentAltitude / turnEnd) ^ turnExponent).
        } else {
        set targetPitch to 90.
        }

        lock steering to heading (90, targetPitch).

        if currentAltitude > turnEnd or OBT:APOAPSIS > targetAP {
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
            lock steering to SHIP:PROGRADE.
            lock throttle to 0.
            lock targetVel to (SQRT(CONSTANT:G * OBT:BODY:MASS / (OBT:APOAPSIS + OBT:BODY:RADIUS)) - SHIP:VELOCITY:ORBIT:MAG) * 1.05.

            // Wait until the ship is out of atmosphere
            set KUNIVERSE:TIMEWARP:MODE to "PHYSICS".
            set KUNIVERSE:TIMEWARP:WARP to 4.
            wait until SHIP:ALTITUDE > 60000.

            set KUNIVERSE:TIMEWARP:WARP to 3.
            // Do maths to figure out TWR vs time to AP, so we give enough time for the manuever node
            until ETA:APOAPSIS < 90 {
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
            set KUNIVERSE:TIMEWARP:WARP to 0.
            wait until KUNIVERSE:TIMEWARP:ISSETTLED.

        // Extending solar panels not facing probe launcher.
            print "Extending minimum safe solar panels".
            for sp in safePanels {
                if sp:HASMODULE("SolarBatteryModule") {
                    if sp:GETMODULE("SolarBatterModule"):HASACTION("extend panel") {
                        sp:GETMODULE("SolarBatteryModule"):DOACTION("extend panel", true).

                    }
                } else if sp:HASMODULE("ModuleDeployableSolarPanel") {
                    if sp:GETMODULE("ModuleDeployableSolarPanel"):HASACTION("extend panel") {
                        sp:GETMODULE("ModuleDeployableSolarPanel"):DOACTION("extend panel", true).

                    }
                } else if sp:HASMODULE("ModuleDeployableAntenna") {
                    if sp:GETMODULE("ModuleDeployableAntenna"):HASACTION("extend antenna") {
                        sp:GETMODULE("ModuleDeployableAntenna"):DOACTION("extend antenna", true).

                    }
                }
                wait 0.25.
            }

            print "Adding circulaization maneuver node".
            set burnAt to time:seconds + ETA:APOAPSIS.
            set circNode to NODE( burnAt, 0, 0, targetVel ).
            ADD circNode.

            RUN "autonode.ks".

            clearscreen.
            print "DEPLOYING PAYLOAD".
            print "----------------------------------------".

            // Disable autostaging
            lock doAutoStaging to FALSE.

        // Point to prograde
            print "STEERING TO PROGRADE".
            lock steering to SHIP:PROGRADE.
            wait until VANG(SHIP:PROGRADE:VECTOR, SHIP:FACING:FOREVECTOR) < 0.10.

            // Transfer remaining fuel to the probes.
            print "TRANSFERING FUEL TO PROBES".
            set oxidizerTransfer to TRANSFERALL("OXIDIZER", sourceTanks, destinationTanks).
            set liquidFuelTransfer to TRANSFERALL("LIQUIDFUEL", sourceTanks, destinationTanks).

            set oxidizerTransfer:ACTIVE to TRUE.
            set liquidFuelTransfer:ACTIVE to TRUE.

            wait until NOT oxidizerTransfer:ACTIVE AND NOT liquidFuelTransfer:ACTIVE.
            print "FUEL TRANSFER COMPLETE".

            // Prep the rest of the systems
            panel on.
            lights on.

        // Detach the probes and clear them.
            print "DETACHING PAYLOAD".
            stage.
            wait 0.5.

            print "THRUSTING FORWARD AT 10%".
            set throttle to 0.1.
            wait 3.0.

        // Now steer away from the payload as we'll burn retrograde after this and don't need to get ran over
            print "CLEARING FROM PAYLOAD TRAJECTORY".
            lock steering to SHIP:PROGRADE + V(0,-10,-10).
            wait 3.5.
            set throttle to 0.

            clearscreen.
            print "DEORBITING".
            print "----------------------------------------".

        // Now point towards retrograde
            print "STEERING TO RETROGRADE".
            lock steering to RETROGRADE.
            wait until VANG(SHIP:RETROGRADE:VECTOR, SHIP:FACING:FOREVECTOR) < 0.25.

        // Burn until AP drops below 30000, we'll let gravity and atmosphere take over after
            print "BEGINNING DEORBIT BURN".
            set throttle to 1.
            wait until OBT:PERIAPSIS < 30000 OR stageDeltaV < 5.
            set throttle to 0.
            print "FINISHED DEORBIT BURN".

        // Coasting to edge of atmosphere
            print "COASTING TO EDGE OF ATMOSPHERE".
            set KUNIVERSE:TIMEWARP:MODE to "PHYSICS".
            set KUNIVERSE:TIMEWARP:WARP to 3.
            wait until radioAltitude < 52500.


        // Now let's wait until we're to perform drogue shoot deployment
            set KUNIVERSE:TIMEWARP:WARP to 2.
            print "WAITING TO DEPLOY DROGUE CHUTES".
            wait until radioAltitude < 10000.
            set KUNIVERSE:TIMEWARP:WARP to 0.
            wait until KUNIVERSE:TIMEWARP:ISSETTLED.
            print "DEPLOYING DROGUE CHUTES".
            stage.

            wait 2.5.
            set KUNIVERSE:TIMEWARP:WARP to 1.
            wait 2.5.
            print "UNLOCKING STEERING".
            unlock steering.

        // Let's now down the the main chute deployment
            print "WAITING TO DEPLOY MAIN CHUTES".
            wait until radioAltitude < 5000.

            if verticleSpeed < 200 {
                set KUNIVERSE:TIMEWARP:WARP to 0.
                wait until KUNIVERSE:TIMEWARP:ISSETTLED.
                print "VERTICAL SPEED IS ABOVE SAFE LIMIT, PERFORMING POWERED SLOW DOWN".
                set throttle to 0.5.
                wait until verticleSpeed > -150 OR stageDeltaV < 5.
                set throttle to 0.
                print "SAFE VERTICLE SPEED REACHED FOR MAIN CHUTES".
                set KUNIVERSE:TIMEWARP:WARP to 1.
            }

            lock throttle to 0.
            print "DEPLOYING MAIN CHUTES".
            stage.

            wait 5.

            print "LANDING APPROACH STABLE".
            wait until radioAltitude < 100.
            set KUNIVERSE:TIMEWARP:WARP to 0.
            wait until KUNIVERSE:TIMEWARP:ISSETTLED.
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
print "CONTROL RELEASED".
