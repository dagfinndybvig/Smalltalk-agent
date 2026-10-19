Class {
	#name : 'GameOfLifeTest',
	#superclass : 'TestCase',
	#category : 'GameOfLife-Tests',
	#package : 'GameOfLife-Tests'
}

{ #category : 'tests' }
GameOfLifeTest >> testBlinkerOscillates [
	| next |
	next := (GameOfLife new withAll: { 0 @ 1. 1 @ 1. 2 @ 1 }) nextGeneration.
	self assert: next liveCells equals: { 1 @ 0. 1 @ 1. 1 @ 2 } asSet
]

{ #category : 'tests' }
GameOfLifeTest >> testBlockIsStillLife [
	| life |
	life := GameOfLife new withAll: { 1 @ 1. 2 @ 1. 1 @ 2. 2 @ 2 }.
	self assert: life nextGeneration liveCells equals: life liveCells
]

{ #category : 'tests' }
GameOfLifeTest >> testCellWithThreeNeighboursIsBorn [
	| life |
	life := GameOfLife new withAll: { 0 @ 0. 2 @ 0. 1 @ 1 }.
	self assert: (life nextGeneration isAliveAt: 1 @ 0)
]

{ #category : 'tests' }
GameOfLifeTest >> testDiamond [
	| pattern nextGen |
	pattern := GameOfLife diamond.
	
	"Check that the pattern has 4 cells"
	self assert: pattern liveCells size equals: 4.
	
	"Check that the pattern is a still life"
	nextGen := pattern generations: 3.
	self assert: nextGen liveCells equals: pattern liveCells
]

{ #category : 'tests' }
GameOfLifeTest >> testGenerationsReturnsStateAfterNGenerations [
	| life |
	life := GameOfLife new withAll: { 0 @ 1. 1 @ 1. 2 @ 1 }.
	self assert: (life generations: 2) liveCells equals: life liveCells
]

{ #category : 'tests' }
GameOfLifeTest >> testGosperGunFiresGliders [
	| gun after |
	gun := GameOfLife gosperGun.
	after := gun generations: 60.
	self assert: after liveCells size > (gun liveCells size + 5)
]

{ #category : 'tests' }
GameOfLifeTest >> testLonelyCellDies [
	| life |
	life := GameOfLife new withAll: { 5 @ 5 }.
	self assert: life nextGeneration liveCells isEmpty
]

{ #category : 'tests' }
GameOfLifeTest >> testOvercrowdedCellDies [
	| life |
	life := GameOfLife new withAll: { 0 @ 0. 0 @ 1. 0 @ 2. 1 @ 0. 1 @ 1 }.
	self deny: (life nextGeneration isAliveAt: 1 @ 1)
]

{ #category : 'tests' }
GameOfLifeTest >> testPufferTrainTravelsAndLeavesDebris [
	| train after |
	train := GameOfLife pufferTrain.
	after := train generations: 40.
	self assert: after liveCells size > train liveCells size.
	self assert: ((after liveCells collect: #x) max - (train liveCells collect: #x) max) >= 15
]
