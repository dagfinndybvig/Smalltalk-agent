Class {
	#name : 'SierpinskiCarpet',
	#superclass : 'Object',
	#instVars : [
		'cells'
	],
	#category : 'Fractals',
	#package : 'Fractals'
}

{ #category : 'geometry' }
SierpinskiCarpet class >> cellsAtLevel: anInteger [
	"Generate the cells programmatically: a cell belongs to the carpet
	unless some ternary digit position has both coordinates equal to 1."
	| size cells |
	size := 3 raisedTo: anInteger.
	cells := Set new.
	0 to: size - 1 do: [ :x |
		0 to: size - 1 do: [ :y |
			(self ternaryConflict: x and: y atLevel: anInteger)
				ifFalse: [ cells add: x @ y ] ] ].
	^ cells
]

{ #category : 'instance creation' }
SierpinskiCarpet class >> level: anInteger [
	"A SierpinskiCarpet of the given recursion level: a 3^n x 3^n grid
	where every sub-block has its middle third removed. The carpet has
	8^n live cells."
	^ self new initializeCells: (self cellsAtLevel: anInteger)
]

{ #category : 'geometry' }
SierpinskiCarpet class >> ternaryConflict: x and: y atLevel: n [
	| px py p |
	p := 1.
	n timesRepeat: [
		px := (x // p) \\ 3.
		py := (y // p) \\ 3.
		(px = 1 and: [ py = 1 ]) ifTrue: [ ^ true ].
		p := p * 3 ].
	^ false
]

{ #category : 'converting' }
SierpinskiCarpet >> asGameOfLife [
	^ GameOfLife new withAll: cells
]

{ #category : 'accessing' }
SierpinskiCarpet >> cells [
	^ cells
]

{ #category : 'initialization' }
SierpinskiCarpet >> initializeCells: aCollection [
	cells := aCollection
]

{ #category : 'views' }
SierpinskiCarpet >> openCarpetView [
	"Render the carpet to a Form sized to fill the Pharo world and open
	it in a plain window. No zooming or fitting - the pixels are exact."
	| side usable pitch form window |
	side := (cells collect: #x) max + 1.
	usable := (World extent x - 12) @ (World extent y - 72).
	pitch := ((usable x min: usable y) // side) max: 1.
	form := Form extent: side * pitch @ (side * pitch) depth: 32.
	form fillColor: Color white.
	cells do: [ :p |
		form
			fill: ((p x * pitch) @ (p y * pitch) extent: pitch @ pitch)
			fillColor: Color black ].
	window := SystemWindow new.
	window setLabel: 'Sierpinski carpet'.
	window addMorph: (ImageMorph new form: form) frame: (0 @ 0 corner: 1 @ 1).
	window extent: (side * pitch) @ (side * pitch) + (12 @ 48).
	window openInWorld.
	window position: ((World extent x - window extent x) // 2) @ 18.
	^ window
]
