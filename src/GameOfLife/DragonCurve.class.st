Class {
	#name : 'DragonCurve',
	#superclass : 'Object',
	#instVars : [
		'points'
	],
	#category : 'GameOfLife',
	#package : 'GameOfLife'
}

{ #category : 'as yet unclassified' }
DragonCurve class >> dragonPointsAtOrder: anInteger [
	"Deterministic doubling: keep the curve, then append the whole
curve
	minus its last point, reversed and rotated 90 degrees around the
	curve endpoint."
	| last |
	last := 0 @ 0.
	^ (2 to: anInteger) inject: (OrderedCollection with: 0 @ 0 with: 1 @ 0)
		into: [ :points :m |
			| end |
			end := points last.
			points allButLast reversed do: [ :p |
				points add: (end x + (p y - end y)) @ (end y - (p x - end x)) ].
			points ]
]

{ #category : 'as yet unclassified' }
DragonCurve class >> order: anInteger [
	"A Heighway dragon curve. Order 1 is a single segment; every order
	doubles the segment count, so order n has 2^(n-1) segments and
	2^(n-1)+1 points."
	^ self new initializePoints: (self dragonPointsAtOrder: anInteger)
]

{ #category : 'as yet unclassified' }
DragonCurve >> initializePoints: aCollection [
	points := aCollection
]

{ #category : 'as yet unclassified' }
DragonCurve >> openDragonView [
	"Render the curve to a Form scaled to fill the Pharo world and open
	it in a plain window."
	| margin usable box scale offset form canvas window |
	points ifEmpty: [ ^ nil ].
	margin := 20.
	usable := (World extent x - (2 * margin)) @ (World extent y - 72 - (2 * margin)).
	box := Rectangle encompassing: points.
	scale := ((usable x / box width) min: (usable y / box height)) max: 1.
	offset := box origin negated * scale.
	form := Form extent: (usable x + (2 * margin)) @ (usable y + (2 * margin)) depth: 32.
	form fillColor: Color white.
	canvas := FormCanvas on: form.
	1 to: points size - 1 do: [ :i | | a b |
		a := (((points at: i) * scale) + offset) rounded + margin.
		b := (((points at: i + 1) * scale) + offset) rounded + margin.
		canvas line: a to: b width: 3 color: Color black ].
	window := SystemWindow new.
	window setLabel: 'Heighway dragon'.
	window addMorph: (ImageMorph new form: form) frame: (0 @ 0 corner: 1 @ 1).
	window extent: form extent + (12 @ 48).
	window openInWorld.
	window position: ((World extent x - window extent x) // 2) @ 18.
	^ window
]

{ #category : 'as yet unclassified' }
DragonCurve >> points [
	^ points asArray
]
