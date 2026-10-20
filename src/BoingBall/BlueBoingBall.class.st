Class {
	#name : 'BlueBoingBall',
	#superclass : 'BoingBall',
	#category : 'BoingBall',
	#package : 'BoingBall'
}

{ #category : 'as yet unclassified' }
BlueBoingBall class >> bouncePitch [
	"A fourth and a bit above the red ball."
	^ 260
]

{ #category : 'as yet unclassified' }
BlueBoingBall class >> primaryColor [
	"Blue-theme variant of the classic boing ball."
	^ Color blue
]

{ #category : 'as yet unclassified' }
BlueBoingBall class >> startPosition: extent [
	"Enter from the corner opposite the red ball: right side, low."
	^ (extent x * 2.0 / 3.0) @ (extent y * 3.0 / 4.0)
]

{ #category : 'as yet unclassified' }
BlueBoingBall class >> startVelocity [
	"Mirror the red ball: enter moving left."
	^ -2 @ 1.4
]
