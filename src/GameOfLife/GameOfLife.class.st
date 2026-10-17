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
GameOfLife >> withAll: aCollection [
	liveCells := aCollection asSet
]
