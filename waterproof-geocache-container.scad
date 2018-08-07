

// Inner compartment dimensions
compartmentDiameter = 50;
compartmentHeight = 30;

// Thickness of the container wall
wallThick = 3;

// Thickness of the container floor
floorThick = wallThick;

// Metric thread pitch for main thread
containerThreadPitch = 3;

// Number of full turns of the thread
containerThreadNumTurns = 5;
containerThreadLength = containerThreadNumTurns * containerThreadPitch;

// Thickness of the top of the cap
capTopHeight = 10;

// Amount of space to leave on each side of the o-ring groove
oRingGrooveMinBufferWidth = 2;

// Series number for orings to use
oRingSeries = 1;

// Number of sealing rings
numORings = 2;

// Minimum thickness of any part of the container top overhang, measured from the bottom of the deepest o-ring groove
containerTopMinThick = 2;

// Extra clearance to add to the diameter of threaded connection
extraThreadDiameterClearance = 0.6;

$fa = 3;
$fs = 0.2;

use <threads.scad>
use <oring.scad>
use <knurl.scad>

compartmentRadius = compartmentDiameter / 2;

containerOuterHeight = compartmentHeight + floorThick + containerThreadLength;
containerOuterRadius = compartmentRadius + 2 * wallThick;
containerInnerRadius = compartmentRadius;

containerThreadOuterDiameter = containerInnerRadius * 2 + containerThreadPitch * 0.3125 * 2;

oRingSurfaceClearance = 0.4;

// Returns O-ring information for the given o-ring number (starting at 0)
// Return format: [ ORingData, GlandData ]
function GetContainerORingInfo(oringNum) =
    let (desiredID =
        (oringNum <= 0)
        ? (containerInnerRadius + containerThreadPitch/2 + oRingGrooveMinBufferWidth) * 2
        : GetContainerORingInfo(oringNum - 1)[1][1] + 2 * oRingGrooveMinBufferWidth
    )
    let (oring = GetNextLargestORingByID(desiredID, series=oRingSeries))
    let (gland = GetORingGlandParameters(oring, clearance=oRingSurfaceClearance))
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
            // Support for overhang
            translate([0, 0, containerOuterHeight-containerTopThick-(containerTopRadius-containerOuterRadius)])
                cylinder(r1=containerOuterRadius, r2=containerTopRadius, h=containerTopRadius-containerOuterRadius);
        };
        // Inner cutout
        translate([0, 0, floorThick])
            cylinder(r=containerInnerRadius, h=10000);
        // Top threads
        translate([0, 0, containerOuterHeight - containerThreadLength])
            metric_thread(
                diameter=containerThreadOuterDiameter,
                pitch=containerThreadPitch,
                length=containerThreadLength+containerThreadPitch,
                internal=true,
                angle=45
            );
        // Thread lead-in cone
        translate([0, 0, containerOuterHeight-containerThreadPitch])
            cylinder(r1=containerInnerRadius, r2=containerInnerRadius+containerThreadPitch, h=containerThreadPitch);
        // O-ring glands
        translate([0, 0, containerOuterHeight])
            for (i = [0 : numORings - 1])
                ORingGland(GetContainerORingInfo(i)[1]);
    };
};

module Cap() {
    // Base
    cylinder(h=capTopHeight, r=containerTopRadius);
    // Knurls
    knurl(capTopHeight, containerTopRadius*2);
    // Threads
    translate([0, 0, capTopHeight])
        metric_thread(
            diameter=containerThreadOuterDiameter-extraThreadDiameterClearance,
            pitch=containerThreadPitch,
            length=containerThreadLength-1,
            internal=false,
            angle=45,
            leadin=1
        );
};

//Container();
Cap();
