Class {
	#name : 'BoingSound',
	#superclass : 'Object',
	#classInstVars : [
		'cache'
	],
	#category : 'BoingBall',
	#package : 'BoingBall'
}

{ #category : 'as yet unclassified' }
BoingSound class >> bounceWavFrequency: f0 [
	"Answer the cached in-memory WAV for this base frequency;
	synthesize on first request. The cache is load-bearing: PlaySound
	with SND_MEMORY needs the bytes alive until playback ends, and
	the cache pins them for the life of the session."
	cache ifNil: [ cache := Dictionary new ].
	^ cache at: f0 ifAbsentPut: [ self synthesizeFrequency: f0 ]
]

{ #category : 'as yet unclassified' }
BoingSound class >> play: sound [
	"Fire and forget: flags 5 = SND_ASYNC (1) + SND_MEMORY (4).
	PlaySound stops any currently playing sound first, which is the
	right behaviour for overlapping bounces."
	^ BoingSoundLibrary uniqueInstance
		ffiCall: #(int PlaySound(void *sound, void * 0, int 5))
]

{ #category : 'as yet unclassified' }
BoingSound class >> putUint16: v at: i in: wav [
	wav at: i put: (v bitAnd: 255).
	wav at: i + 1 put: ((v bitShift: -8) bitAnd: 255)
]

{ #category : 'as yet unclassified' }
BoingSound class >> putUint32: v at: i in: wav [
	wav at: i put: (v bitAnd: 255).
	wav at: i + 1 put: ((v bitShift: -8) bitAnd: 255).
	wav at: i + 2 put: ((v bitShift: -16) bitAnd: 255).
	wav at: i + 3 put: ((v bitShift: -24) bitAnd: 255)
]

{ #category : 'as yet unclassified' }
BoingSound class >> synthesizeFrequency: f0 [
	"Synthesize the classic boing: a sine sweeping down one octave
	from f0 over 0.35 seconds with a quadratic decay, 16-bit mono
	at 22050 Hz."
	| sr n pcm phase |
	sr := 22050.0.
	n := (sr * 0.35) rounded.
	pcm := ByteArray new: n * 2.
	phase := 0.0.
	0 to: n - 1 do: [ :i |
		| t freq amp v |
		t := i / sr.
		freq := f0 * (0.5 raisedTo: (t / 0.35) asFloat).
		phase := phase + ((Float pi * 2 * freq) / sr).
		amp := 1.0 - (i / n asFloat).
		amp := amp * amp * 0.9.
		v := (amp * 30000 * ((phase sin) + (0.3 * ((phase * 2) sin)))) rounded.
		pcm at: (i * 2) + 1 put: (v bitAnd: 255).
		pcm at: (i * 2) + 2 put: ((v bitShift: -8) bitAnd: 255) ].
	^ self wavFromPcm: pcm sampleRate: sr
]

{ #category : 'as yet unclassified' }
BoingSound class >> wavFromPcm: pcm sampleRate: sr [
	"Prepend a canonical 44-byte RIFF/WAVE header to 16-bit mono PCM."
	| wav |
	wav := ByteArray new: 44 + pcm size.
	wav replaceFrom: 1 to: 4 with: 'RIFF' asByteArray startingAt: 1.
	self putUint32: 36 + pcm size at: 5 in: wav.
	wav replaceFrom: 9 to: 12 with: 'WAVE' asByteArray startingAt: 1.
	wav replaceFrom: 13 to: 16 with: 'fmt ' asByteArray startingAt: 1.
	self putUint32: 16 at: 17 in: wav.
	self putUint16: 1 at: 21 in: wav.
	self putUint16: 1 at: 23 in: wav.
	self putUint32: sr rounded at: 25 in: wav.
	self putUint32: (sr rounded) * 2 at: 29 in: wav.
	self putUint16: 2 at: 33 in: wav.
	self putUint16: 16 at: 35 in: wav.
	wav replaceFrom: 37 to: 40 with: 'data' asByteArray startingAt: 1.
	self putUint32: pcm size at: 41 in: wav.
	wav replaceFrom: 45 to: wav size with: pcm startingAt: 1.
	^ wav
]
