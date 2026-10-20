Class {
	#name : 'GreenBoingBallTest',
	#superclass : 'TestCase',
	#category : 'BoingBall-Tests',
	#package : 'BoingBall-Tests'
}

{ #category : 'as yet unclassified' }
GreenBoingBallTest >> testCenterIsOpaqueGreen [
	| form c |
	form := GreenBoingBall renderBallRadius: 20 phase: 0.
	c := form colorAt: 20 @ 20.
	self deny: c isTransparent.
	self assert: c green > 0.8.
	self assert: c red < 0.1.
]

{ #category : 'as yet unclassified' }
GreenBoingBallTest >> testCheckerHasGreenAndWhite [
	| form hasGreen hasWhite |
	form := GreenBoingBall renderBallRadius: 24 phase: 0.
	hasGreen := false.
	hasWhite := false.
	0 to: 47 do: [ :y | 0 to: 47 do: [ :x |
		| c |
		c := form colorAt: x @ y.
		c isTransparent ifFalse: [
			(c green > 0.7 and: [ c red < 0.2 ]) ifTrue: [ hasGreen := true ].
			(c green > 0.7 and: [ c red > 0.7 ]) ifTrue: [ hasWhite := true ] ] ] ].
	self assert: hasGreen.
	self assert: hasWhite.
]

{ #category : 'as yet unclassified' }
GreenBoingBallTest >> testCornersAreTransparent [
	| form |
	form := GreenBoingBall renderBallRadius: 20 phase: 0.
	self assert: (form colorAt: 0 @ 0) isTransparent.
	self assert: (form colorAt: 39 @ 39) isTransparent.
	self assert: (form colorAt: 0 @ 39) isTransparent.
	self assert: (form colorAt: 39 @ 0) isTransparent.
]

{ #category : 'as yet unclassified' }
GreenBoingBallTest >> testFormCacheIndependentFromOtherVariants [
	| a b |
	a := GreenBoingBall formRadius: 12 phase: 3.
	b := BoingBall formRadius: 12 phase: 3.
	self deny: a == b.
	self deny: a bits = b bits.
]

{ #category : 'as yet unclassified' }
GreenBoingBallTest >> testFormCacheReturnsSameInstance [
	| a b |
	a := GreenBoingBall formRadius: 12 phase: 3.
	b := GreenBoingBall formRadius: 12 phase: 3.
	self assert: a == b.
]

{ #category : 'as yet unclassified' }
GreenBoingBallTest >> testPhasesDiffer [
	| a b |
	a := GreenBoingBall renderBallRadius: 16 phase: 0.
	b := GreenBoingBall renderBallRadius: 16 phase: 1.2.
	self deny: a bits = b bits.
]

{ #category : 'as yet unclassified' }
GreenBoingBallTest >> testPitchesAreDistinctAndOrdered [
	self assert: BoingBall bouncePitch < BlueBoingBall bouncePitch.
	self assert: BlueBoingBall bouncePitch < GreenBoingBall bouncePitch.
]

{ #category : 'as yet unclassified' }
GreenBoingBallTest >> testRenderIsDeterministic [
	| a b |
	a := GreenBoingBall renderBallRadius: 16 phase: 0.3.
	b := GreenBoingBall renderBallRadius: 16 phase: 0.3.
	self assert: a bits = b bits.
]

{ #category : 'as yet unclassified' }
GreenBoingBallTest >> testStartsTopCenterVertical [
	| e p |
	e := 1200 @ 900.
	p := GreenBoingBall startPosition: e.
	self assert: (BoingBall startPosition: e) x < p x.
	self assert: p x < (BlueBoingBall startPosition: e) x.
	self assert: p y < (BoingBall startPosition: e) y.
	self assert: GreenBoingBall startVelocity x = 0.
	self assert: GreenBoingBall startVelocity y > 0.
]
