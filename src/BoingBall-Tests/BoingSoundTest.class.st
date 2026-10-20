Class {
	#name : 'BoingSoundTest',
	#superclass : 'TestCase',
	#category : 'BoingBall-Tests',
	#package : 'BoingBall-Tests'
}

{ #category : 'as yet unclassified' }
BoingSoundTest >> testNotSilent [
	| wav |
	wav := BoingSound bounceWavFrequency: 180.
	self assert: ((wav copyFrom: 45 to: wav size) anySatisfy: [ :b | b > 64 ])
]

{ #category : 'as yet unclassified' }
BoingSoundTest >> testPitchesDiffer [
	| a b |
	a := BoingSound bounceWavFrequency: 180.
	b := BoingSound bounceWavFrequency: 260.
	self deny: a = b.
]

{ #category : 'as yet unclassified' }
BoingSoundTest >> testPlaySoundReturnsTrue [
	self assert: (BoingSound play: (BoingSound bounceWavFrequency: 180)) = 1
]

{ #category : 'as yet unclassified' }
BoingSoundTest >> testVariantPitchesDiffer [
	self assert: BoingBall bouncePitch < BlueBoingBall bouncePitch.
]

{ #category : 'as yet unclassified' }
BoingSoundTest >> testWavHasRiffHeader [
	| wav |
	wav := BoingSound bounceWavFrequency: 180.
	self assert: (wav copyFrom: 1 to: 4) = 'RIFF' asByteArray.
	self assert: (wav copyFrom: 9 to: 12) = 'WAVE' asByteArray.
	self assert: (wav copyFrom: 37 to: 40) = 'data' asByteArray.
]

{ #category : 'as yet unclassified' }
BoingSoundTest >> testWavSizesMatchHeader [
	| wav |
	wav := BoingSound bounceWavFrequency: 180.
	self assert: (wav unsignedLongAt: 5) = (wav size - 8).
	self assert: (wav unsignedLongAt: 41) = (wav size - 44).
	self assert: (wav unsignedLongAt: 25) = 22050.
	self assert: (wav unsignedLongAt: 17) = 16.
	self assert: (wav unsignedShortAt: 35) = 16.
]
