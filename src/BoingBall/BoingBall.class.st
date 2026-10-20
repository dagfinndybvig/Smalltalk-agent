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
	#classInstVars : [
		'current',
		'formCache'
	],
	#category : 'BoingBall',
	#package : 'BoingBall'
}

{ #category : 'as yet unclassified' }
BoingBall class >> bouncePitch [
	"Base frequency of this variant boing, in Hz."
	^ 180
]

{ #category : 'as yet unclassified' }
BoingBall class >> flushFormCache [
	"Drop all cached rotation forms; the next tick re-renders them."
	formCache := Dictionary new.
	^ #flushed
]

{ #category : 'as yet unclassified' }
BoingBall class >> formRadius: r phase: p [
	"Answer a cached rendered form for this radius and phase index
	(0-23); render lazily on first request. The cache lives on the
	concrete class, so theme variants keep independent forms."
	formCache ifNil: [ formCache := Dictionary new ].
	^ formCache
		at: { r. p }
		ifAbsentPut: [ self renderBallRadius: r phase: p * (Float pi * 2.0 / 24.0) ]
]

{ #category : 'as yet unclassified' }
BoingBall class >> isRunning [
	^ current notNil
]

{ #category : 'as yet unclassified' }
BoingBall class >> playBounce [
	"Play this variant boing without blocking."
	BoingSound play: (BoingSound bounceWavFrequency: self bouncePitch)
]

{ #category : 'as yet unclassified' }
BoingBall class >> primaryColor [
	"The check color paired with the secondary color."
	^ Color red
]

{ #category : 'as yet unclassified' }
BoingBall class >> renderBallRadius: r phase: phaseRadians [
	"Render one rotation phase of the checkered boing ball: a unit
	sphere lit from the upper left, 8 longitude and 8 latitude bands,
	the phase shifts the longitude seam. The two check colors come
	from primaryColor/secondaryColor, so theme variants just override
	those. Pixels outside the disc stay transparent."
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
						ifTrue: [ base := self primaryColor ]
						ifFalse: [ base := self secondaryColor ].
					form
						colorAt: x @ y
						put: (Color r: base red * shade g: base green * shade b: base blue * shade) ] ] ].
	^ form
]

{ #category : 'as yet unclassified' }
BoingBall class >> secondaryColor [
	^ Color white
]

{ #category : 'as yet unclassified' }
BoingBall class >> start [
	"Stop any running ball of this variant and open a fresh one
	bouncing across the desktop. Answers #boing."
	self stop.
	current := self new start.
	^ #boing
]

{ #category : 'as yet unclassified' }
BoingBall class >> startPosition: extent [
	"Initial ball center for a world of this extent. Variants override
	to enter from their own corner."
	^ (extent x / 3.0) @ (extent y / 4.0)
]

{ #category : 'as yet unclassified' }
BoingBall class >> startVelocity [
	"Initial velocity; positive x moves right. Variants override to
	mirror the entry direction."
	^ 2 @ 1.4
]

{ #category : 'as yet unclassified' }
BoingBall class >> stop [
	"Stop the running ball of this variant, if any. Answers #stopped."
	current ifNotNil: [ current stop. current := nil ].
	^ #stopped
]

{ #category : 'as yet unclassified' }
BoingBall >> start [
	"Open the ball on the desktop and fork the animation loop at
	background priority so the UI process stays responsive. Entry
	position and velocity come from the class-side startPosition:/
	startVelocity hooks, so theme variants can enter from their own
	corner."
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
	position := self class startPosition: extent.
	velocity := self class startVelocity.
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
	quarter-step per tick to match the slow flight. Each reflection
	plays this variant pitch boing."
	| extent floorY leftX rightX h shadowWidth bounced |
	extent := World extent.
	bounced := false.
	velocity := velocity x @ (velocity y + 0.08).
	position := position + velocity.
	floorY := extent y - radius - 2.
	leftX := radius.
	rightX := extent x - radius.
	position y > floorY
		ifTrue: [
			position := position x @ (2 * floorY - position y).
			velocity := velocity x @ velocity y abs negated.
			bounced := true ].
	position y < radius
		ifTrue: [
			position := position x @ (2 * radius - position y).
			velocity := velocity x @ velocity y abs.
			bounced := true ].
	position x < leftX
		ifTrue: [
			position := (2 * leftX - position x) @ position y.
			velocity := velocity x abs @ velocity y.
			bounced := true ].
	position x > rightX
		ifTrue: [
			position := (2 * rightX - position x) @ position y.
			velocity := velocity x abs negated @ velocity y.
			bounced := true ].
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
	bounced ifTrue: [ self class playBounce ]
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
