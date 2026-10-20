Class {
	#name : 'BoingBall',
	#superclass : 'Object',
	#instVars : [
		'morph',
		'shadow',
		'process',
		'position',
		'velocity',
		'radius',
		'phase'
	],
	#classVars : [
		'Current',
		'FormCache'
	],
	#category : 'BoingBall',
	#package : 'BoingBall'
}

{ #category : 'as yet unclassified' }
BoingBall class >> flushFormCache [
	"Drop all cached rotation forms; the next tick re-renders them."
	FormCache := Dictionary new.
	^ #flushed
]

{ #category : 'as yet unclassified' }
BoingBall class >> formRadius: r phase: p [
	"Answer a cached rendered form for this radius and phase index
	(0-23); render lazily on first request."
	FormCache ifNil: [ FormCache := Dictionary new ].
	^ FormCache
		at: { r. p }
		ifAbsentPut: [ self renderBallRadius: r phase: p * (Float pi * 2.0 / 24.0) ]
]

{ #category : 'as yet unclassified' }
BoingBall class >> isRunning [
	^ Current notNil
]

{ #category : 'as yet unclassified' }
BoingBall class >> renderBallRadius: r phase: phaseRadians [
	"Render one rotation phase of the classic red-and-white checkered
	boing ball: a unit sphere lit from the upper left, 8 longitude and
	8 latitude bands, the phase shifts the longitude seam. Pixels
	outside the disc stay transparent."
	| form half invBand |
	half := r asFloat.
	invBand := 4.0 / Float pi.
	form := Form extent: (2 * r) @ (2 * r) depth: 32.
	0 to: 2 * r - 1 do: [ :y |
		0 to: 2 * r - 1 do: [ :x |
			| u v d z lon lat i j raw shade base |
			u := (x - half) / half.
			v := (y - half) / half.
			d := (u * u) + (v * v).
			d <= 1.0
				ifTrue: [
					z := (1.0 - d) sqrt.
					lon := (u / (z max: 1.0e-9)) arcTan.
					lat := v arcSin.
					i := ((lon + phaseRadians) * invBand) floor.
					j := (lat * invBand) floor.
					raw := 0.55 + (0.45 * ((u * -0.35) + (v * -0.5) + (z * 0.79))).
					shade := (raw max: 0.0) min: 1.0.
					(i + j) even
						ifTrue: [ base := Color red ]
						ifFalse: [ base := Color white ].
					form
						colorAt: x @ y
						put: (Color r: base red * shade g: base green * shade b: base blue * shade) ] ] ].
	^ form
]

{ #category : 'as yet unclassified' }
BoingBall class >> start [
	"Stop any running ball and open a fresh one bouncing across the
	desktop. Answers #boing."
	self stop.
	Current := self new start.
	^ #boing
]

{ #category : 'as yet unclassified' }
BoingBall class >> stop [
	"Stop the running ball, if any. Answers #stopped."
	Current ifNotNil: [ Current stop. Current := nil ].
	^ #stopped
]

{ #category : 'as yet unclassified' }
BoingBall >> start [
	"Open the ball on the desktop and fork the animation loop at
	background priority so the UI process stays responsive. The
	trajectory is the authentic Boing one: constant velocity, sharp
	reflections off the edges, no gravity."
	| extent |
	self stop.
	extent := World extent.
	radius := ((extent y / 12) rounded max: 30) min: 90.
	shadow := EllipseMorph new
		borderWidth: 0;
		color: (Color black alpha: 0.3);
		lock.
	morph := ImageMorph new
		form: (self class formRadius: radius phase: 0);
		lock.
	World addMorph: shadow.
	World addMorph: morph.
	position := (extent x / 3.0) @ (extent y / 4.0).
	velocity := 2 @ 1.4.
	phase := 0.
	process := [ [ true ] whileTrue: [ self step. (Delay forMilliseconds: 16) wait ] ]
		forkAt: Processor userBackgroundPriority.
	^ self
]

{ #category : 'as yet unclassified' }
BoingBall >> step [
	"Advance one tick and reflect off the floor, walls and ceiling.
	The trajectory is a blend: mostly straight diagonals with a small
	gravity term (0.08) drooping each segment into the floor bounce.
	The shadow sits on the floor line under the ball, wider and darker
	as the ball gets closer to the floor. The spin advances one
	quarter-step per tick to match the slow flight."
	| extent floorY leftX rightX h shadowWidth |
	extent := World extent.
	velocity := velocity x @ (velocity y + 0.08).
	position := position + velocity.
	floorY := extent y - radius - 2.
	leftX := radius.
	rightX := extent x - radius.
	position y > floorY
		ifTrue: [
			position := position x @ (2 * floorY - position y).
			velocity := velocity x @ velocity y abs negated ].
	position y < radius
		ifTrue: [
			position := position x @ (2 * radius - position y).
			velocity := velocity x @ velocity y abs ].
	position x < leftX
		ifTrue: [
			position := (2 * leftX - position x) @ position y.
			velocity := velocity x abs @ velocity y ].
	position x > rightX
		ifTrue: [
			position := (2 * rightX - position x) @ position y.
			velocity := velocity x abs negated @ velocity y ].
	phase := (phase + 1) \\ 96.
	morph form: (self class formRadius: radius phase: (phase / 4) floor).
	morph position: position - (radius @ radius).
	h := ((floorY - position y) / (extent y * 0.75)) max: 0.0.
	h := h min: 1.0.
	shadowWidth := (radius * 2.0 * (1.0 - (h * 0.6))) rounded max: 8.
	shadow
		bounds: ((position x - (shadowWidth / 2)) @ (floorY + radius - 6)
			extent: shadowWidth @ ((shadowWidth / 4) rounded max: 4));
		color: (Color black alpha: (0.35 * (1.0 - h))).
]

{ #category : 'as yet unclassified' }
BoingBall >> stop [
	"Remove the morphs and terminate the animation process."
	process ifNotNil: [ process terminate ].
	process := nil.
	morph ifNotNil: [ morph delete ].
	morph := nil.
	shadow ifNotNil: [ shadow delete ].
	shadow := nil.
	^ #stopped
]
