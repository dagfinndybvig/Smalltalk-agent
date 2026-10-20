Class {
	#name : 'BlueBoingBallTest',
	#superclass : 'TestCase',
	#category : 'BoingBall-Tests',
	#package : 'BoingBall-Tests'
}

{ #category : 'as yet unclassified' }
BlueBoingBallTest >> testCenterIsOpaqueBlue [
	| form c |
	form := BlueBoingBall renderBallRadius: 20 phase: 0.
	c := form colorAt: 20 @ 20.
	self deny: c isTransparent.
	self assert: c blue > 0.8.
	self assert: c green < 0.1.
]

{ #category : 'as yet unclassified' }
BlueBoingBallTest >> testCheckerHasBlueAndWhite [
	| form hasBlue hasWhite |
	form := BlueBoingBall renderBallRadius: 24 phase: 0.
	hasBlue := false.
	hasWhite := false.
	0 to: 47 do: [ :y | 0 to: 47 do: [ :x |
		| c |
		c := form colorAt: x @ y.
		c isTransparent ifFalse: [
			(c blue > 0.7 and: [ c red < 0.2 ]) ifTrue: [ hasBlue := true ].
			(c blue > 0.7 and: [ c red > 0.7 ]) ifTrue: [ hasWhite := true ] ] ] ].
	self assert: hasBlue.
	self assert: hasWhite.
]

{ #category : 'as yet unclassified' }
BlueBoingBallTest >> testCornersAreTransparent [
	| form |
	form := BlueBoingBall renderBallRadius: 20 phase: 0.
	self assert: (form colorAt: 0 @ 0) isTransparent.
	self assert: (form colorAt: 39 @ 39) isTransparent.
	self assert: (form colorAt: 0 @ 39) isTransparent.
	self assert: (form colorAt: 39 @ 0) isTransparent.
]

{ #category : 'as yet unclassified' }
BlueBoingBallTest >> testFormCacheIndependentFromRedBall [
	| a b |
	a := BoingBall formRadius: 12 phase: 3.
	b := BlueBoingBall formRadius: 12 phase: 3.
	self deny: a == b.
	self deny: a bits = b bits.
]

{ #category : 'as yet unclassified' }
BlueBoingBallTest >> testFormCacheReturnsSameInstance [
	| a b |
	a := BlueBoingBall formRadius: 12 phase: 3.
	b := BlueBoingBall formRadius: 12 phase: 3.
	self assert: a == b.
]

{ #category : 'as yet unclassified' }
BlueBoingBallTest >> testPhasesDiffer [
	| a b |
	a := BlueBoingBall renderBallRadius: 16 phase: 0.
	b := BlueBoingBall renderBallRadius: 16 phase: 1.2.
	self deny: a bits = b bits.
]

{ #category : 'as yet unclassified' }
BlueBoingBallTest >> testRenderIsDeterministic [
	| a b |
	a := BlueBoingBall renderBallRadius: 16 phase: 0.3.
	b := BlueBoingBall renderBallRadius: 16 phase: 0.3.
	self assert: a bits = b bits.
]

{ #category : 'as yet unclassified' }
BlueBoingBallTest >> testStartsOppositeRedBall [
	| e |
	e := 1200 @ 900.
	self assert: (BlueBoingBall startPosition: e) x > (BoingBall startPosition: e) x.
	self assert: (BlueBoingBall startPosition: e) y > (BoingBall startPosition: e) y.
	self assert: BlueBoingBall startVelocity x < 0.
	self assert: BoingBall startVelocity x > 0.
]
