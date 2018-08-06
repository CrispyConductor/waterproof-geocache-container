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

// O-ring groove dimensions in both container and cap
oRingGrooveWidth = 1.5;
oRingGrooveDepth = 1;

use <threads.scad>

$fa = 3;
$fs = 0.2;

compartmentRadius = compartmentDiameter / 2;

containerOuterHeight = compartmentHeight + floorThick + containerThreadLength;
containerOuterRadius = compartmentRadius + 2 * wallThick;
containerInnerRadius = compartmentRadius;

containerThreadOuterDiameter = containerInnerRadius * 2 + containerThreadPitch * 0.3125 * 2;

module Container() {
    difference() {
        // Main outer cylinder
        cylinder(r=containerOuterRadius, h=containerOuterHeight);
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
