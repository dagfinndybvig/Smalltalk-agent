Class {
	#name : 'TwinDragonTest',
	#superclass : 'TestCase',
	#category : 'GameOfLife-Tests',
	#package : 'GameOfLife-Tests'
}

{ #category : 'as yet unclassified' }
TwinDragonTest >> testBothCurvesStartAtOrigin [
	| twin |
	twin := TwinDragon order: 8.
	self assert: twin curveOne first equals: 0 @ 0.
	self assert: twin curveTwo first equals: 0 @ 0.
]

{ #category : 'as yet unclassified' }
TwinDragonTest >> testCounts [
	self assert: (TwinDragon order: 8) curveOne size equals: 129.
	self assert: (TwinDragon order: 10) curveTwo size equals: 513.
]

{ #category : 'as yet unclassified' }
TwinDragonTest >> testGoldenOrderThree [
	| twin |
	twin := TwinDragon order: 3.
	self assert: twin curveOne equals: { 0 @ 0. 1 @ 0. 1 @ 1. 0 @ 1. 0 @ 2 } asArray.
	self assert: twin curveTwo equals: { 0 @ 0. -1 @ 0. -1 @ -1. 0 @ -1. 0 @ -2 } asArray
]

{ #category : 'as yet unclassified' }
TwinDragonTest >> testSecondIsFirstNegated [
	| twin one two |
	twin := TwinDragon order: 8.
	one := twin curveOne. two := twin curveTwo.
	1 to: one size do: [ :i |
		self assert: (two at: i)
			equals: ((one at: i) x negated) @ ((one at: i) y negated) ]
]
