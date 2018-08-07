

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

useORingBites = true;

includeDessicantPocket = true;
dessicantPocketWallThick = 2;

$fa = 3;
$fs = 0.2;

use <threads.scad>
use <oring.scad>
use <knurl.scad>
use <rotate_extrude.scad>

compartmentRadius = compartmentDiameter / 2;

containerOuterHeight = compartmentHeight + floorThick + containerThreadLength;
containerOuterRadius = compartmentRadius + 2 * wallThick;
containerInnerRadius = compartmentRadius;

containerThreadOuterDiameter = containerInnerRadius * 2 + containerThreadPitch * 0.3125 * 2;

oRingSurfaceClearance = 0.2;

oRingBiteHeight = 0.2;

numClips = 6;
clipWidth = min(10, 2*PI*containerOuterRadius/numClips/2, 2*PI*containerOuterRadius/20);
clipArmThick = 2;
clipArmMinLength = 15; // length to the start of the clip protrusion; actually length is containerTopThick
clipArmContainerClearance = 0.6;
clipDeflectionAngle = 5;

// Returns O-ring information for the given o-ring number (starting at 0)
// Return format: [ ORingData, GlandData, BiteData ]
function GetContainerORingInfo(oringNum) =
    let (desiredID =
        (oringNum <= 0)
        ? (containerInnerRadius + containerThreadPitch/2 + oRingGrooveMinBufferWidth) * 2
        : GetContainerORingInfo(oringNum - 1)[1][1] + 2 * oRingGrooveMinBufferWidth
    )
    let (oring = GetNextLargestORingByGlandID(desiredID, series=oRingSeries, clearance=oRingSurfaceClearance, biteHeight=oRingBiteHeight, numBites=useORingBites?2:0))
    let (bite = GetORingBiteParameters(oring, oRingBiteHeight, useORingBites?2:0))
    let (gland = GetORingGlandParameters(oring, clearance=oRingSurfaceClearance, bite=bite))
    [ oring, gland, bite ];

// Calculate the thickness of the top part of the container from the maximum depth of any of the O-ring grooves
containerTopThick_ord = max([ for (i = [0 : numORings - 1]) GetContainerORingInfo(i)[1][2] ]) + containerTopMinThick;
containerTopThick = (numClips > 0) ? max(containerTopThick_ord, clipArmMinLength) : containerTopThick_ord;

clipProtrusion = (containerTopThick * tan(clipDeflectionAngle) + clipArmContainerClearance / cos(clipDeflectionAngle)) / (1 - tan(clipDeflectionAngle));

// Calculate the radius of the top part of the container from the OD of the largest O-ring groove
containerTopRadius_ord = GetContainerORingInfo(numORings - 1)[1][1] / 2 + oRingGrooveMinBufferWidth;
containerTopRadius_clip = containerOuterRadius + clipProtrusion - clipArmContainerClearance;
containerTopRadius = max(containerTopRadius_ord, containerTopRadius_clip);

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
                ORingGland(GetContainerORingInfo(i)[1], bite=useORingBites?GetContainerORingInfo(i)[2]:undef);
    };
};

capThreadLength = containerThreadLength - 1;
capThreadDiameter = containerThreadOuterDiameter-extraThreadDiameterClearance;
dessicantPocketHeight = capTopHeight + capThreadLength - floorThick;
dessicantThreadDiameter = capThreadDiameter - 2*containerThreadPitch - 2*dessicantPocketWallThick;
dessicantThreadNumTurns = 2;
dessicantThreadLength = dessicantThreadNumTurns * containerThreadPitch;
dessicantCapHeight = dessicantThreadLength;

module Cap() {
    extraCapRadiusWithClips = 2;
    capRadius = (numClips > 0) ? containerTopRadius + clipArmContainerClearance + clipArmThick + extraCapRadiusWithClips : containerTopRadius;
    
    difference() {
        union() {
            // Base
            cylinder(h=capTopHeight, r=capRadius);
             // Threads
            translate([0, 0, capTopHeight])
                metric_thread(
                    diameter=capThreadDiameter,
                    pitch=containerThreadPitch,
                    length=capThreadLength,
                    internal=false,
                    angle=45,
                    leadin=1
                );
        };
        
        // Dessicant pocket
        dessicantPocketZ = floorThick;
        dessicantPocketCapShoulder = 1;
        if (includeDessicantPocket)
            translate([0, 0, dessicantPocketZ])
                union() {
                    cylinder(r=dessicantThreadDiameter/2-containerThreadPitch-dessicantPocketCapShoulder, h=1000);
                    translate([0, 0, dessicantPocketHeight - dessicantThreadLength])
                        metric_thread(
                            diameter=dessicantThreadDiameter,
                            pitch=containerThreadPitch,
                            length=dessicantThreadLength + containerThreadPitch,
                            internal=true,
                            angle=45
                        );
                };
    };
    
    // Knurls
    knurl(capTopHeight, capRadius*2);
    // O-ring bites
    if (useORingBites)
        for (i = [0 : numORings-1])
            translate([0, 0, capTopHeight])
                ORingBite(GetContainerORingInfo(i)[2]);
    
    // Clip shroud and clips
    clipPointHeight = 1;
    clipShroudGapClearance = 1;
    clipArmFullLength = containerTopThick + 2 * clipProtrusion + clipPointHeight;
    clipArmOffsetX = containerTopRadius + clipArmContainerClearance;
    clipSpanAngle = clipWidth / (2 * PI * clipArmOffsetX) * 360;
    clipShroudGapSpanAngle = (clipWidth + 2 * clipShroudGapClearance) / (2 * PI * clipArmOffsetX) * 360;
    clipAngleSpacing = 360 / numClips;
    clipArmTopThick = clipArmThick / 2;
    clipBaseBevelHeight = min(extraCapRadiusWithClips, containerTopThick / 10);
    if (numClips > 0)
        translate([0, 0, capTopHeight])
            union() {
                difference() {
                    // Clip shroud, same thickness as clip arms
                    rotate_extrude()
                        translate([clipArmOffsetX, 0])
                            polygon([
                                [0, 0],
                                [clipArmThick + extraCapRadiusWithClips, 0],
                                [clipArmThick, clipBaseBevelHeight],
                                [clipArmThick, clipArmFullLength],
                                [0, clipArmFullLength]
                            ]);
                    // Gaps in the clip shroud
                    for (i = [0 : numClips - 1])
                        rotate([0, 0, i * clipAngleSpacing - clipShroudGapSpanAngle/2])
                            rotate_extrude2(angle=clipShroudGapSpanAngle)
                                square([1000, 1000]);
                };
                
                // Clips
                for (i = [0 : numClips - 1])
                    rotate([0, 0, i * clipAngleSpacing - clipSpanAngle/2])
                        rotate_extrude2(angle=clipSpanAngle)
                            translate([clipArmOffsetX, 0])
                                polygon([
                                    [0, 0],
                                    [clipArmThick + extraCapRadiusWithClips, 0],
                                    [clipArmThick, clipBaseBevelHeight],
                                    [clipArmTopThick, clipArmFullLength],
                                    [0, clipArmFullLength],
                                    [-clipProtrusion, clipArmFullLength - clipProtrusion],
                                    [-clipProtrusion, clipArmFullLength - clipProtrusion - clipPointHeight],
                                    [0, clipArmFullLength - 2*clipProtrusion - clipPointHeight]
                                ]);
            };
};

//Container();
Cap();
