Class {
	#name : 'GreenBoingBall',
	#superclass : 'BoingBall',
	#category : 'BoingBall',
	#package : 'BoingBall'
}

{ #category : 'as yet unclassified' }
GreenBoingBall class >> bouncePitch [
	"The highest of the three variants."
	^ 320
]

{ #category : 'as yet unclassified' }
GreenBoingBall class >> primaryColor [
	"Green-theme variant of the boing ball."
	^ Color green
]

{ #category : 'as yet unclassified' }
GreenBoingBall class >> startPosition: extent [
	"Enter top-center and drop straight down: a pure vertical bounce
	that crosses the paths of the diagonal variants."
	^ (extent x / 2.0) @ (extent y / 8.0)
]

{ #category : 'as yet unclassified' }
GreenBoingBall class >> startVelocity [
	^ 0 @ 1.8
]
