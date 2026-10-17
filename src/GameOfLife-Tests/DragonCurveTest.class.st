Class {
	#name : 'DragonCurveTest',
	#superclass : 'TestCase',
	#category : 'GameOfLife-Tests',
	#package : 'GameOfLife-Tests'
}

{ #category : 'as yet unclassified' }
DragonCurveTest >> testOrderOneIsASegment [
	self assert: (DragonCurve order: 1) points equals: { 0 @ 0. 1 @ 0 } asArray
]

{ #category : 'as yet unclassified' }
DragonCurveTest >> testOrderThreeGolden [
	self assert: (DragonCurve order: 3) points
		equals: { 0 @ 0. 1 @ 0. 1 @ 1. 0 @ 1. 0 @ 2 } asArray
]

{ #category : 'as yet unclassified' }
DragonCurveTest >> testPointCounts [
	self assert: (DragonCurve order: 8) points size equals: 129.
	self assert: (DragonCurve order: 10) points size equals: 513.
]

{ #category : 'as yet unclassified' }
DragonCurveTest >> testStepsAreUnitSteps [
	| pts |
	pts := (DragonCurve order: 10) points.
	1 to: pts size - 1 do: [ :i | | a b |
		a := pts at: i. b := pts at: i + 1.
		self assert: (a x - b x) abs + (a y - b y) abs equals: 1 ]
]
