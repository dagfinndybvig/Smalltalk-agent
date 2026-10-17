Class {
	#name : 'SierpinskiCarpet',
	#superclass : 'Object',
	#instVars : [
		'cells'
	],
	#category : 'GameOfLife',
	#package : 'GameOfLife'
}

{ #category : 'as yet unclassified' }
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

{ #category : 'as yet unclassified' }
SierpinskiCarpet class >> level: anInteger [
	"A SierpinskiCarpet of the given recursion level: a 3^n x 3^n grid
	where every sub-block has its middle third removed. The carpet has
	8^n live cells."
	^ self new initializeCells: (self cellsAtLevel: anInteger)
]

{ #category : 'as yet unclassified' }
SierpinskiCarpet class >> new [
    ^ super new initialize
]

{ #category : 'as yet unclassified' }
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

{ #category : 'as yet unclassified' }
SierpinskiCarpet >> asGameOfLife [
	^ GameOfLife new withAll: cells
]

{ #category : 'as yet unclassified' }
SierpinskiCarpet >> cells [
	^ cells
]

{ #category : 'as yet unclassified' }
SierpinskiCarpet >> display [
	| form |
	form := self render.
	(ImageMorph new image: form) openInWorld
]

{ #category : 'as yet unclassified' }
SierpinskiCarpet >> example [
    self new
        initializeLevel: 3
        size: 729;
        display
]

{ #category : 'as yet unclassified' }
SierpinskiCarpet >> initializeCells: aCollection [
	cells := aCollection
]

{ #category : 'as yet unclassified' }
SierpinskiCarpet >> initializeLevel: aLevel size: aSize [
    level := aLevel.
    size := aSize
]

{ #category : 'as yet unclassified' }
SierpinskiCarpet >> openCarpetView [
	"Draw the carpet and open it maximized, filling the screen."
	| pitch canvas window |
	pitch := 40.
	canvas := RSCanvas new.
	canvas color: Color white.
	cells do: [ :p |
		canvas add: (RSBox new
			size: pitch - 6;
			color: Color black;
			position: (p x * pitch) @ (p y negated * pitch)) ].
	window := canvas open.
	window maximize.
	^ window
]

{ #category : 'as yet unclassified' }
SierpinskiCarpet >> render [
    | form canvas |
    form := Form extent: size asPoint depth: 32.
    canvas := FormCanvas on: form.
    self renderAtLevel: 0 at: 0 @ 0 on: canvas.
    ^ form
]

{ #category : 'as yet unclassified' }
SierpinskiCarpet >> renderAtLevel: currentLevel at: origin on: canvas [
    | subSize rect |
    currentLevel = level
        ifTrue: [ 
            rect := origin extent: size asPoint / (3 raisedTo: level - currentLevel).
            canvas fillRectangle: rect color: Color black ]
        ifFalse: [ 
            subSize := size / (3 raisedTo: level - currentLevel).
            0 to: 2 do: [ :i |
                0 to: 2 do: [ :j |
                    (i = 1 and: [ j = 1 ]) 
                        ifFalse: [ 
                            self 
                                renderAtLevel: currentLevel + 1 
                                at: origin + (i * subSize @ (j * subSize)) 
                                on: canvas ] ] ] ]
]
