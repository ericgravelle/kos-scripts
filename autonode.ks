// ***************************************************************************
// Executes a manuever node
//
// Copyright 2021 TLabs Technology Foundry
// ***************************************************************************

lock stageDeltaV to SHIP:STAGEDELTAV(9999):CURRENT.
lock stageBurnTime to SHIP:STAGEDELTAV(9999):DURATION.

//WHEN throttle > 0 THEN {
//    if stageBurnTime < 0.9 {
//        print "STAGING NOW".
//        wait 1.
//        stage.
//        preserve.
//    } else {
//        wait 0.25.
//        preserve.
//    }
//}

if HASNODE {
    clearscreen.
    print "Setting up a known state".
    set kuniverse:timewarp:warp to 0.
    wait until KUNIVERSE:TIMEWARP:ISSETTLED.
    SAS OFF.
    RCS OFF.
    lock throttle to 0.

    set currentNode to NEXTNODE.

    set maxAcc to SHIP:MAXTHRUST / SHIP:MASS.
    set burnDuration to currentNode:DELTAV:MAG / maxAcc.
    lock steering to currentNode.

    print "Steering towards burn vector".
    wait until VANG(currentNode:BURNVECTOR, SHIP:FACING:FOREVECTOR) < 0.25.

    print "Timewarping to maneuver node".
    set KUNIVERSE:TIMEWARP:MODE to "RAILS".
    KUNIVERSE:TIMEWARP:WARPTO(TIME:SECONDS + currentNode:ETA - (burnDuration/2) - 30).

    print "Waiting to arrive at burn initiation".
    wait until currentNode:ETA <= (burnDuration/2).

    set tset to 0.
    lock throttle to tset.
    set done to False.
    set dv0 to currentNode:DELTAV.

    until done {

    //throttle is 100% until there is less than 1 second of time left to burn
    //when there is less than 1 second - decrease the throttle linearly
        set tset to MIN( currentNode:DELTAV:MAG / maxAcc, 1 ).

        clearscreen.
        print "MANEUVER NODE EXECUTION".
        print "----------------------------------------".
        print "    Stage DeltaV: " + ROUND(SHIP:STAGEDELTAV(99999):CURRENT, 2) + " s".
        print " Stage Burn Time: " + ROUND(SHIP:STAGEDELTAV(99999):DURATION, 1) + " s".

    //here's the tricky part, we need to cut the throttle as soon as our nd:deltav and initial deltav start facing opposite directions
    //this check is done via checking the dot product of those 2 vectors
        if VDOT(dv0, currentNode:DELTAV) < 0 {
            print "End burn".
            lock throttle to 0.
            break.
        }

    //we have very little left to burn, less then 0.1m/s
        if currentNode:DELTAV:MAG < 0.1 {
            print "Finalizing burn".

        //we burn slowly until our node vector starts to drift significantly from initial vector
        //this usually means we are on point
            wait until VDOT(dv0, currentNode:DELTAV) < 0.5.

            lock throttle to 0.
            print "End burn".
            set done to True.
        }
        wait 0.1.
    }

    unlock steering.
    set throttle to 0.
    unlock throttle.
    remove currentNode.
}
