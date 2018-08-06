

// Inner compartment dimensions
compartmentDiameter = 50;
compartmentHeight = 100;

// Thickness of the container wall
wallThick = 4;

// Thickness of the container floor
floorThick = wallThick;

// Metric thread pitch for main thread
containerThreadPitch = 2;

// Number of full turns of the thread
containerThreadNumTurns = 4;
containerThreadLength = containerThreadNumTurns * containerThreadPitch;

// Thickness of the top of the cap
capTopHeight = 10;

// Amount of space to leave on each side of the o-ring groove
oRingGrooveMinBufferWidth = 1.5;

// Series number for orings to use
oRingSeries = 1;

// Number of sealing rings
numORings = 2;

// Minimum thickness of any part of the container top overhang, measured from the bottom of the deepest o-ring groove
containerTopMinThick = 2;

$fa = 3;
$fs = 0.2;

use <threads.scad>
use <oring.scad>

compartmentRadius = compartmentDiameter / 2;

containerOuterHeight = compartmentHeight + floorThick + containerThreadLength;
containerOuterRadius = compartmentRadius + 2 * wallThick;
containerInnerRadius = compartmentRadius;

containerThreadOuterDiameter = containerInnerRadius * 2 + containerThreadPitch * 0.3125 * 2;

// Returns O-ring information for the given o-ring number (starting at 0)
// Return format: [ ORingData, GlandData ]
function GetContainerORingInfo(oringNum) =
    let (desiredID =
        (oringNum <= 0)
        ? (containerInnerRadius + containerThreadPitch/2 + oRingGrooveMinBufferWidth) * 2
        : GetContainerORingInfo(oringNum - 1)[1][1] + 2 * oRingGrooveMinBufferWidth
    )
    let (oring = GetNextLargestORingByID(desiredID, series=oRingSeries))
    let (gland = GetORingGlandParameters(oring))
    [ oring, gland ];

// Calculate the radius of the top part of the container from the OD of the largest O-ring groove
containerTopRadius = GetContainerORingInfo(numORings - 1)[1][1] / 2 + oRingGrooveMinBufferWidth;

// Calculate the thickness of the top part of the container from the maximum depth of any of the O-ring grooves
containerTopThick = max([ for (i = [0 : numORings - 1]) GetContainerORingInfo(i)[1][2] ]) + containerTopMinThick;

// Print out o-ring info
for (i = [0 : numORings - 1])
    echo(ORingToStr(GetContainerORingInfo(i)[0]));

module Container() {
    difference() {
        union() {
            // Main outer cylinder
            cylinder(r=containerOuterRadius, h=containerOuterHeight);
            // Container top overhang
            translate([0, 0, containerOuterHeight - containerTopThick])
                cylinder(h=containerTopThick, r=containerTopRadius);
        };
        // Inner cutout
        translate([0, 0, floorThick])
            cylinder(r=containerInnerRadius, h=10000);
        // Top threads
        translate([0, 0, containerOuterHeight - containerThreadLength])
            metric_thread(
                diameter=containerThreadOuterDiameter,
                pitch=containerThreadPitch,
                length=containerThreadLength,
                internal=true,
                angle=45,
                leadin=1
            );
        // O-ring glands
        translate([0, 0, containerOuterHeight])
            for (i = [0 : numORings - 1])
                ORingGland(GetContainerORingInfo(i)[1]);
    };
};

module Cap() {
    // Base
    cylinder(h=capTopHeight, r=containerOuterRadius);
    // Threads
    translate([0, 0, capTopHeight])
        metric_thread(
            diameter=containerThreadOuterDiameter,
            pitch=containerThreadPitch,
            length=containerThreadLength,
            internal=false,
            angle=45
        );
};

Container();
//Cap();
