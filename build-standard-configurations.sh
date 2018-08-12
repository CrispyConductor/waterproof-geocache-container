#!/bin/bash

OPENSCAD=openscad-nightly

function buildConfiguration {
	SIZENAME="$1"
	DIAMETER="$2"
	HEIGHT="$3"
	NUMSEALS="$4"
	CAPTOPHEIGHT="$5"
	INCLUDECLIPS="$6"

	FN="allparts-${SIZENAME}-${NUMSEALS}seal"
	if [ "$INCLUDECLIPS" = "no" ]; then FN="${FN}-noclips"; fi

	echo "Building $FN"
	$OPENSCAD -o "${FN}.stl" -D "part=\"all\"" -D "compartmentDiameter=$DIAMETER" -D "compartmentHeight=$HEIGHT" -D "numORings=$NUMSEALS" -D "capTopHeight=$CAPTOPHEIGHT" -D "includeClips_str=\"$INCLUDECLIPS\"" waterproof-geocache-container.scad
}

buildConfiguration small 25 30 2 10 yes
buildConfiguration small 25 30 1 10 yes
buildConfiguration small 25 30 2 10 no
buildConfiguration small 25 30 1 10 no
buildConfiguration medium 50 70 2 20 yes
buildConfiguration medium 50 70 1 20 yes
buildConfiguration medium 50 70 2 20 no
buildConfiguration medium 50 70 1 20 no
buildConfiguration large 75 100 2 20 yes
buildConfiguration large 75 100 1 20 yes
buildConfiguration large 75 100 2 20 no
buildConfiguration large 75 100 1 20 no


