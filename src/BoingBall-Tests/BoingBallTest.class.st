Class {
	#name : 'BoingBallTest',
	#superclass : 'TestCase',
	#category : 'BoingBall-Tests',
	#package : 'BoingBall-Tests'
}

{ #category : 'as yet unclassified' }
BoingBallTest >> testCenterIsOpaqueRed [
	| form c |
	form := BoingBall renderBallRadius: 20 phase: 0.
	c := form colorAt: 20 @ 20.
	self deny: c isTransparent.
	self assert: c red > 0.8.
	self assert: c green < 0.1.
]

{ #category : 'as yet unclassified' }
BoingBallTest >> testCheckerHasRedAndWhite [
	| form hasRed hasWhite |
	form := BoingBall renderBallRadius: 24 phase: 0.
	hasRed := false.
	hasWhite := false.
	0 to: 47 do: [ :y | 0 to: 47 do: [ :x |
		| c |
		c := form colorAt: x @ y.
		c isTransparent ifFalse: [
			(c red > 0.7 and: [ c green < 0.2 ]) ifTrue: [ hasRed := true ].
			(c red > 0.7 and: [ c green > 0.7 ]) ifTrue: [ hasWhite := true ] ] ] ].
	self assert: hasRed.
	self assert: hasWhite.
]

{ #category : 'as yet unclassified' }
BoingBallTest >> testCornersAreTransparent [
	| form |
	form := BoingBall renderBallRadius: 20 phase: 0.
	self assert: (form colorAt: 0 @ 0) isTransparent.
	self assert: (form colorAt: 39 @ 39) isTransparent.
	self assert: (form colorAt: 0 @ 39) isTransparent.
	self assert: (form colorAt: 39 @ 0) isTransparent.
]

{ #category : 'as yet unclassified' }
BoingBallTest >> testFormCacheReturnsSameInstance [
	| a b |
	a := BoingBall formRadius: 12 phase: 3.
	b := BoingBall formRadius: 12 phase: 3.
	self assert: a == b.
]

{ #category : 'as yet unclassified' }
BoingBallTest >> testPhasesDiffer [
	| a b |
	a := BoingBall renderBallRadius: 16 phase: 0.
	b := BoingBall renderBallRadius: 16 phase: 1.2.
	self deny: a bits = b bits.
]

{ #category : 'as yet unclassified' }
BoingBallTest >> testRenderIsDeterministic [
	| a b |
	a := BoingBall renderBallRadius: 16 phase: 0.3.
	b := BoingBall renderBallRadius: 16 phase: 0.3.
	self assert: a bits = b bits.
]
