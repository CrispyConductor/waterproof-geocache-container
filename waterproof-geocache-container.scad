/* [Global] */

// Part to print.  Desiccant cap is only needed if including desiccant pocket.
part = "all"; // [container:Container,cap:Cap for Container,desiccantcap:Cap for Desiccant Pocket,all:All Parts]

/* [Main] */

// Diameter of inner compartment
compartmentDiameter = 25;

// Height of inner compartment
compartmentHeight = 30;

// Number of concentric o-ring seals
numORings = 2; // [1, 2, 3, 4]

// Whether or not to include external cap clips.  These can help prevent the lid from backing off due to vibration, but increase the unused size of the container.
includeClips_str = "yes";

// Whether or not to include a cavity in the cap for desiccant to be added
includeDesiccantPocket_str = "yes"; // [yes, no]
includeDesiccantPocket = includeDesiccantPocket_str == "yes";

// Thickness/height of the top of the cap
capTopHeight = 7;


/* [Screw Thread] */

// Extra clearance to add to the diameter of threaded connections
extraThreadDiameterClearance = 0.6;

// Metric thread pitch for main container thread
containerThreadPitch = 3;

// Minimum number of screw threads engaged
containerThreadNumTurnsMin = 5;


/* [O-Rings] */

// Series number for o-rings to use.  Larger numbers are larger o-rings.
oRingSeries = 1; // [0, 1, 2, 3, 4]

// Whether to include raised protrusions that dig into the o-rings.  This can increase the sealing ability on 3d-printed objects, but may cause additional wear to the o-rings.
useORingBites_str = "yes"; // [yes, no]
useORingBites = useORingBites_str == "yes";

// Whether to include retaining clips for the o-rings.  These help the o-rings not fall out when opened, but may cause additional wear.
useORingRetainers_str = "yes"; // [yes, no]
useORingRetainers = useORingRetainers_str == "yes";

// Amount of space to leave on each side of the o-ring grooves
oRingGrooveMinBufferWidth = 2;

// Clearance gap between lid and container to use for o-ring gland calculations
oRingSurfaceClearance = 0;

// Height of the raised surface to dig into the o-ring
oRingBiteHeight = 0.2;


/* [Labels] */

// Whether or not to include a label for the desiccant cavity
includeDesiccantLabel_str = "yes"; // [yes, no]
includeDesiccantLabel = includeDesiccantLabel_str == "yes";

// Whether or not to include the o-ring numbers on the inner bottom of the container
includeORingLabel_str = "yes"; // [yes, no]
includeORingLabel = includeORingLabel_str == "yes";

// Text on top of cap
topLabel = "GEOCACHE CONTAINER";

// Text on bottom of container
bottomLabel = "GEOCACHE CONTAINER";

// Text on side of container
sideLabel = "GEOCACHE CONTAINER";


/* [Clips] */

// Number of external cap clips
numClips_cfg = 6;
numClips = includeClips_str == "yes" ? numClips_cfg : 0;

// Angle of deflection for the clips when container is opened and closed.  Higher values result in a more positive lock, but can make the clips prone to breaking off.
clipDeflectionAngle = 3.5;

// Thickness of the clip arm
clipArmThick = 3;

// Desired width of the clip arm
maxClipWidth = 10;

// Minimum length of the clip arm, to the start of the clip protrusion.
clipArmMinLength = 15;

// Gap between clips and outer container wall
clipArmContainerClearance = 0.6;

// Minimum number of thread turns that must be engaged before the clips touch the container body.
minThreadEngagementBeforeClips = 1;


/* [Misc] */

// Thickness of the container wall
wallThick = 3;

// Minimum thickness of any part of the container top overhang, measured from the bottom of the deepest o-ring groove
containerTopMinThick = 2;

// Minimum thickness of the wall of the desiccant pocket/main screw
desiccantPocketWallThick = 2;

// Number of thread turns for the desiccant pocket cap
desiccantThreadNumTurns = 2;


/* [Hidden] */

$fa = 3;
$fs = 0.2;

use <threads.scad>
use <oring.scad>
use <knurl.scad>
use <rotate_extrude.scad>
use <write/Write.scad>

// Thickness of the container floor
floorThick = wallThick;

compartmentRadius = compartmentDiameter / 2;

containerOuterRadius = compartmentRadius + 2 * wallThick;
containerInnerRadius = compartmentRadius;

containerThreadOuterDiameter = containerInnerRadius * 2 + containerThreadPitch * 0.3125 * 2;

clipWidth = min(maxClipWidth, 2*PI*containerOuterRadius/numClips/2, 2*PI*containerOuterRadius/20);

// Returns O-ring information for the given o-ring number (starting at 0)
// Return format: [ ORingData, GlandData, BiteData, RetainerData ]
function GetContainerORingInfo(oringNum) =
    let (desiredID =
        (oringNum <= 0)
        ? (containerInnerRadius + containerThreadPitch/2 + oRingGrooveMinBufferWidth) * 2
        : GetContainerORingInfo(oringNum - 1)[1][1] + 2 * oRingGrooveMinBufferWidth
    )
    let (oring = GetNextLargestORingByGlandID(desiredID, series=oRingSeries, clearance=oRingSurfaceClearance, biteHeight=oRingBiteHeight, numBites=useORingBites?2:0))
    let (bite = GetORingBiteParameters(oring, oRingBiteHeight, useORingBites?2:0))
    let (gland = GetORingGlandParameters(oring, clearance=oRingSurfaceClearance, bite=bite))
    let (retainer = GetORingRetainerParameters(oring))
    [ oring, gland, bite, retainer ];

// Calculate the thickness of the top part of the container from the maximum depth of any of the O-ring grooves
containerTopThick_ord = max([ for (i = [0 : numORings - 1]) GetContainerORingInfo(i)[1][2] ]) + containerTopMinThick;
containerTopThick = (numClips > 0) ? max(containerTopThick_ord, clipArmMinLength) : containerTopThick_ord;

capThreadLengthOffset = -1;

clipProtrusion = (containerTopThick * tan(clipDeflectionAngle) + clipArmContainerClearance / cos(clipDeflectionAngle)) / (1 - tan(clipDeflectionAngle));
clipArmLengthOffset = -clipProtrusion * (3/4);

clipPointHeight = 1;
clipArmFullLength = containerTopThick + 2 * clipProtrusion + clipPointHeight - clipArmContainerClearance + clipArmLengthOffset;

// Minimal number of threads on cap screw 
containerThreadNumTurns_clips = (clipArmFullLength - capThreadLengthOffset) / containerThreadPitch + 1 + minThreadEngagementBeforeClips;

containerThreadNumTurns = max(containerThreadNumTurnsMin, numClips > 0 ? containerThreadNumTurns_clips : 0);
containerThreadLength = containerThreadNumTurns * containerThreadPitch;
containerOuterHeight = compartmentHeight + floorThick + containerThreadLength;

containerTopChamferSize = numClips > 0 ? clipProtrusion : 0;

// Calculate the radius of the top part of the container from the OD of the largest O-ring groove
containerTopRadius_ord = GetContainerORingInfo(numORings - 1)[1][1] / 2 + oRingGrooveMinBufferWidth + containerTopChamferSize;
containerTopRadius_clip = containerOuterRadius + clipProtrusion;
// Use the larger of the two minimum radii
containerTopRadius = max(containerTopRadius_ord, numClips > 0 ? containerTopRadius_clip : 0);

// Print out o-ring info
for (i = [0 : numORings - 1])
    echo(ORingToStr(GetContainerORingInfo(i)[0]));

function getAllORingInfoString(fromIdx = 0) =
    (fromIdx < numORings - 1) ?
    str(GetContainerORingInfo(fromIdx)[0][0], "-", getAllORingInfoString(fromIdx+1)) :
    str(GetContainerORingInfo(fromIdx)[0][0]);

module Container() {
    topOverhangSupportZ = containerOuterHeight-containerTopThick-(containerTopRadius-containerOuterRadius);
    difference() {
        union() {
            // Main outer cylinder
            cylinder(r=containerOuterRadius, h=containerOuterHeight);
            // Container top overhang
            translate([0, 0, containerOuterHeight - containerTopThick])
                cylinder(h=containerTopThick, r=containerTopRadius);
            // Support for overhang
            translate([0, 0, topOverhangSupportZ])
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
                ORingGland(GetContainerORingInfo(i)[1], bite=useORingBites?GetContainerORingInfo(i)[2]:undef, retainer=useORingRetainers?GetContainerORingInfo(i)[3]:undef);
        // Outer chamfer
        containerTopChamferHeight = containerTopThick * 0.75;
        if (containerTopChamferSize > 0)
            translate([0, 0, containerOuterHeight])
                rotate_extrude()
                    translate([containerTopRadius, 0])
                        polygon([
                            [0, 0],
                            [-containerTopChamferSize, 0],
                            [0, -containerTopChamferHeight]
                        ]);
        // Bottom label
        if (len(bottomLabel) > 0)
            writecylinder(
                text = bottomLabel,
                where = [0, 0, 0],
                radius = containerOuterRadius,
                height = containerOuterHeight,
                face = "bottom",
                h = containerOuterRadius / 5,
                space = 1.5
            );
        // Side label
        if (len(sideLabel) > 0)
            writecylinder(
                text = sideLabel,
                where = [0, 0, 0],
                radius = containerOuterRadius,
                height = topOverhangSupportZ,
                h = containerOuterRadius / 5,
                space = 1.5,
                rotate = 15
            );
        // O-ring dash number label
        if (includeORingLabel)
            writecylinder(
                text = getAllORingInfoString(),
                where = [0, 0, 0],
                radius = containerInnerRadius,
                height = floorThick,
                face = "top",
                h = containerInnerRadius / 3,
                space = 1.5
            );
    };
};

capThreadLength = containerThreadLength + capThreadLengthOffset;
capThreadDiameter = containerThreadOuterDiameter-extraThreadDiameterClearance;
desiccantPocketHeight = capTopHeight + capThreadLength - floorThick;
desiccantThreadDiameter = capThreadDiameter - 2*containerThreadPitch - 2*desiccantPocketWallThick;
desiccantThreadLength = desiccantThreadNumTurns * containerThreadPitch;
desiccantCapHeight = desiccantThreadLength;
desiccantPocketCapShoulder = 1;
desiccantPocketInternalRadius = desiccantThreadDiameter/2-containerThreadPitch-desiccantPocketCapShoulder;

// Extra cap radius to add when clips are enabled
extraCapRadiusWithClips = 2;

capRadius = (numClips > 0) ? containerTopRadius + clipArmContainerClearance + clipArmThick + extraCapRadiusWithClips : containerTopRadius;

module Cap() {
    
    difference() {
        union() {
            // Base
            cylinder(h=capTopHeight, r=capRadius);
            // Knurls
            knurl(capTopHeight, capRadius*2);
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
        
        // Desiccant pocket
        desiccantPocketZ = floorThick;
        if (includeDesiccantPocket)
            translate([0, 0, desiccantPocketZ])
                union() {
                    cylinder(r=desiccantPocketInternalRadius, h=1000);
                    translate([0, 0, desiccantPocketHeight - desiccantThreadLength])
                        metric_thread(
                            diameter=desiccantThreadDiameter,
                            pitch=containerThreadPitch,
                            length=desiccantThreadLength + containerThreadPitch,
                            internal=true,
                            angle=45
                        );
                };
                
        // Desiccant label
        if (includeDesiccantPocket && includeDesiccantLabel)
            writecylinder(
                text = "DESICCANT",
                where = [0, 0, 0],
                radius = capThreadDiameter/2 - containerThreadPitch,
                height = capThreadLength + capTopHeight,
                face = "top",
                h = desiccantPocketWallThick,
                middle = -desiccantPocketWallThick,
                space = 2
            );
        
        // Top label
        if (len(topLabel) > 0)
            writecylinder(
                text = topLabel,
                where = [0, 0, 0],
                radius = capRadius,
                height = capTopHeight,
                face = "bottom",
                h = capRadius / 5,
                space = 1.5
            );
    };
    
    // O-ring bites
    if (useORingBites)
        for (i = [0 : numORings-1])
            translate([0, 0, capTopHeight])
                ORingBite(GetContainerORingInfo(i)[2]);
    
    // Clip shroud and clips
    clipShroudGapClearance = 1;
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
                                square([capRadius+1, clipArmFullLength+1]);
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

module DesiccantCap() {
    perforationDiameter = 1.5;
    perforationSpacing = perforationDiameter * 3;
    difference() {
        // Body of cap
        metric_thread(
            diameter=desiccantThreadDiameter-extraThreadDiameterClearance,
            pitch=containerThreadPitch,
            length=desiccantCapHeight,
            internal=false,
            angle=45
        );
        // Slot for turning
        slotWidth = min(3, desiccantThreadDiameter/5);
        slotLength = (desiccantThreadDiameter - containerThreadPitch*2) * 0.6;
        slotDepth = desiccantCapHeight * 0.7;
        translate([-slotWidth/2, -slotLength/2, desiccantCapHeight-slotDepth])
            cube([slotWidth, slotLength, 1000]);
        // Perforations
        for (r = [desiccantPocketInternalRadius-perforationDiameter : -perforationSpacing : perforationSpacing/2]) {
            numPerforations = floor(2*PI*r / perforationSpacing);
            startAngle = rands(-360, 0, 1)[0];
            for (a = [startAngle : 360/numPerforations : startAngle+359])
                rotate([0, 0, a])
                    translate([r, 0, 0])
                        cylinder(r=perforationDiameter/2, h=1000);
        };
    };
};

module print_part() {
    if (part == "container")
        Container();
    else if (part == "cap")
        Cap();
    else if (part == "desiccantcap")
        DesiccantCap();
    else if (part == "all")
        union() {
            translate([-containerTopRadius-1, 0, 0])
                Container();
            translate([capRadius + 2, 0, 0])
                Cap();
            if (includeDesiccantPocket)
                translate([0, max(containerTopRadius + 1, capRadius + 2)+desiccantThreadDiameter/2, 0])
                    DesiccantCap();
        };
};

print_part();

//Container();
//Cap();
//DesiccantCap();
