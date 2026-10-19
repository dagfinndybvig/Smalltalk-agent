Class {
	#name : 'TwinDragonTest',
	#superclass : 'TestCase',
	#category : 'Fractals-Tests',
	#package : 'Fractals-Tests'
}

{ #category : 'tests' }
TwinDragonTest >> testBothCurvesStartAtOrigin [
	| twin |
	twin := TwinDragon order: 8.
	self assert: twin curveOne first equals: 0 @ 0.
	self assert: twin curveTwo first equals: 0 @ 0.
]

{ #category : 'tests' }
TwinDragonTest >> testCounts [
	self assert: (TwinDragon order: 8) curveOne size equals: 129.
	self assert: (TwinDragon order: 10) curveTwo size equals: 513.
]

{ #category : 'tests' }
TwinDragonTest >> testGoldenOrderThree [
	| twin |
	twin := TwinDragon order: 3.
	self assert: twin curveOne equals: { 0 @ 0. 1 @ 0. 1 @ 1. 0 @ 1. 0 @ 2 } asArray.
	self assert: twin curveTwo equals: { 0 @ 0. -1 @ 0. -1 @ -1. 0 @ -1. 0 @ -2 } asArray
]

{ #category : 'tests' }
TwinDragonTest >> testSecondIsFirstNegated [
	| twin one two |
	twin := TwinDragon order: 8.
	one := twin curveOne. two := twin curveTwo.
	1 to: one size do: [ :i |
		self assert: (two at: i)
			equals: ((one at: i) x negated) @ ((one at: i) y negated) ]
]
