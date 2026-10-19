Class {
	#name : 'TwinDragon',
	#superclass : 'Object',
	#instVars : [
		'curveOne',
		'curveTwo'
	],
	#category : 'Fractals',
	#package : 'Fractals'
}

{ #category : 'instance creation' }
TwinDragon class >> order: anInteger [
	"Two Heighway dragons joined tail to tail: the second is the first
	rotated 180 degrees around the shared starting point. The pair is
	the classic Davis-Knuth twindragon."
	| first |
	first := (DragonCurve dragonPointsAtOrder: anInteger) asArray.
	^ self new
		initializeFirst: first
		second: (first collect: [ :p | p x negated @ p y negated ] as: Array)
]

{ #category : 'accessing' }
TwinDragon >> curveOne [
	^ curveOne
]

{ #category : 'accessing' }
TwinDragon >> curveTwo [
	^ curveTwo
]

{ #category : 'drawing' }
TwinDragon >> drawCurve: aCurve on: canvas scale: scale offset: offset margin: margin color: aColor [
	1 to: aCurve size - 1 do: [ :i | | a b |
		a := (((aCurve at: i) * scale) + offset) rounded + margin.
		b := (((aCurve at: i + 1) * scale) + offset) rounded + margin.
		canvas line: a to: b width: 3 color: aColor ]
]

{ #category : 'initialization' }
TwinDragon >> initializeFirst: one second: two [
	curveOne := one.
	curveTwo := two
]

{ #category : 'views' }
TwinDragon >> openTwinDragonView [
	"Render both dragon curves to a Form at a comfortable size, centered.
	The first dragon in black, its twin in red."
	| margin usable box scale offset form canvas window all |
	all := curveOne, curveTwo.
	margin := 20.
	usable := ((World extent x - (2 * margin)) @ (World extent y - 72 - (2 * margin))) * 0.75.
	usable := usable x asInteger @ usable y asInteger.
	box := Rectangle encompassing: all.
	scale := ((usable x / box width) min: (usable y / box height)) max: 1.
	offset := box origin negated * scale.
	form := Form extent: (usable x + (2 * margin)) @ (usable y + (2 * margin)) depth: 32.
	form fillColor: Color white.
	canvas := FormCanvas on: form.
	self drawCurve: curveOne on: canvas scale: scale offset: offset margin: margin color: Color black.
	self drawCurve: curveTwo on: canvas scale: scale offset: offset margin: margin color: Color red.
	window := SystemWindow new.
	window setLabel: 'Twin dragon'.
	window addMorph: (ImageMorph new form: form) frame: (0 @ 0 corner: 1 @ 1).
	window extent: form extent + (12 @ 48).
	window openInWorld.
	window position: ((World extent x - window extent x) // 2) @ ((World extent y - window extent y) // 2).
	^ window
]
