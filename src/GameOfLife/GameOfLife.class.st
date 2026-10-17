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
GameOfLife class >> gosperGun [
	"Bill Gosper, 1970: the first known glider gun. True period 30:
	fires one glider every 30 generations, forever. Coordinates from
	the canonical RLE (conwaylife.com/wiki/Gosper_glider_gun)."
	^ self new withAll: {
		24@0.
		22@1. 24@1.
		12@2. 13@2. 20@2. 21@2. 34@2. 35@2.
		11@3. 15@3. 20@3. 21@3. 34@3. 35@3.
		0@4. 1@4. 10@4. 16@4. 20@4. 21@4.
		0@5. 1@5. 10@5. 14@5. 16@5. 17@5. 22@5. 24@5.
		10@6. 16@6. 24@6.
		11@7. 15@7.
		12@8. 13@8. }
]

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
GameOfLife >> openGunView [
	| canvas boxes extent origin gun |
	extent := 50.
	origin := extent // 2.
	canvas := RSCanvas new.
	canvas color: Color veryLightGray.
	boxes := Dictionary new.
	origin negated to: (extent - origin) do: [ :gx |
		origin negated to: (extent - origin) do: [ :gy |
			| box |
			box := RSBox new
				size: 16;
				color: Color white.
			box position: (gx * 20) @ (gy negated * 20).
			canvas add: box.
			boxes at: gx @ gy put: box ] ].
	gun := GameOfLife gosperGun translatedBy: (origin negated + (extent - 36 // 2)) @ (origin negated + (extent - 9 // 2)).
	gun paintBoxes: boxes.
	canvas open.
	[ | life |
		life := gun.
		500 timesRepeat: [
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
GameOfLife >> translatedBy: aPoint [
	^ self class new withAll: (liveCells collect: [ :p | p + aPoint ])
]

{ #category : 'as yet unclassified' }
GameOfLife >> withAll: aCollection [
	liveCells := aCollection asSet
]
