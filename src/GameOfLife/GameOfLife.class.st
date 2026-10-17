Class {
	#name : 'GameOfLife',
	#superclass : 'Object',
	#instVars : [
		'liveCells'
	],
	#category : 'GameOfLife',
	#package : 'GameOfLife'
}

{ #category : 'as yet unclassified' }
GameOfLife >> drawOn: canvas [
	liveCells do: [ :p |
		canvas add: (RSBox new
			size: 18;
			color: Color black;
			position: (p x * 22) @ (p y negated * 22)) ]
]

{ #category : 'as yet unclassified' }
GameOfLife >> generations: anInteger [
	| current |
	current := self.
	anInteger timesRepeat: [ current := current nextGeneration ].
	^ current
]

{ #category : 'as yet unclassified' }
GameOfLife >> initialize [
	super initialize.
	liveCells := Set new
]

{ #category : 'as yet unclassified' }
GameOfLife >> isAliveAt: aPoint [
	^ liveCells includes: aPoint
]

{ #category : 'as yet unclassified' }
GameOfLife >> liveCells [
	^ liveCells
]

{ #category : 'as yet unclassified' }
GameOfLife >> liveNeighborsOf: aPoint [
	^ (self neighborsOf: aPoint) count: [ :each | liveCells includes: each ]
]

{ #category : 'as yet unclassified' }
GameOfLife >> neighborOffsets [
	^ { -1 @ -1. 0 @ -1. 1 @ -1. -1 @ 0. 1 @ 0. -1 @ 1. 0 @ 1. 1 @ 1 }
]

{ #category : 'as yet unclassified' }
GameOfLife >> neighborsOf: aPoint [
	^ self neighborOffsets collect: [ :each | aPoint + each ]
]

{ #category : 'as yet unclassified' }
GameOfLife >> nextGeneration [
	| candidates next |
	candidates := Set new.
	liveCells do: [ :cell |
		candidates add: cell.
		candidates addAll: (self neighborsOf: cell) ].
	next := Set new.
	candidates do: [ :point |
		| count |
		count := self liveNeighborsOf: point.
		(liveCells includes: point)
			ifTrue: [ (count = 2 or: [ count = 3 ]) ifTrue: [ next add: point ] ]
			ifFalse: [ count = 3 ifTrue: [ next add: point ] ] ].
	^ self class new withAll: next
]

{ #category : 'as yet unclassified' }
GameOfLife >> openEvolutionView [
	| canvas boxes origin extent |
	extent := 30.
	origin := extent // 2.
	canvas := RSCanvas new.
	canvas color: Color veryLightGray.
	boxes := Dictionary new.
	origin negated to: (extent - origin) do: [ :gx |
		origin negated to: (extent - origin) do: [ :gy |
			| box |
			box := RSBox new
				size: 18;
				color: Color white.
			box position: (gx * 22) @ (gy negated * 22).
			canvas add: box.
			boxes at: gx @ gy put: box ] ].
	self paintBoxes: boxes.
	canvas open.
	[ | life |
		life := self.
		300 timesRepeat: [
			(Delay forMilliseconds: 250) wait.
			life := life nextGeneration.
			life paintBoxes: boxes.
			canvas signalUpdate ] ] fork
]

{ #category : 'as yet unclassified' }
GameOfLife >> openView [
	| canvas |
	canvas := RSCanvas new.
	canvas color: Color white.
	self drawOn: canvas.
	^ canvas open
]

{ #category : 'as yet unclassified' }
GameOfLife >> paintBoxes: boxes [
	boxes keysAndValuesDo: [ :point :box |
		box color: ((liveCells includes: point)
			ifTrue: [ Color black ]
			ifFalse: [ Color white ]) ]
]

{ #category : 'as yet unclassified' }
GameOfLife >> withAll: aCollection [
	liveCells := aCollection asSet
]
