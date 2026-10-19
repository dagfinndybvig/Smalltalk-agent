Class {
	#name : 'SierpinskiCarpetTest',
	#superclass : 'TestCase',
	#category : 'Fractals-Tests',
	#package : 'Fractals-Tests'
}

{ #category : 'tests' }
SierpinskiCarpetTest >> testAsGameOfLife [
	| gol |
	gol := (SierpinskiCarpet level: 2) asGameOfLife.
	self assert: gol liveCells size equals: 64.
	self assert: (gol isAliveAt: 0 @ 0).
	self deny: (gol isAliveAt: 4 @ 4)
]

{ #category : 'tests' }
SierpinskiCarpetTest >> testLevelOneHasEightCells [
	self assert: (SierpinskiCarpet level: 1) cells size equals: 8
]

{ #category : 'tests' }
SierpinskiCarpetTest >> testLevelThreeHas512Cells [
	self assert: (SierpinskiCarpet level: 3) cells size equals: 512
]

{ #category : 'tests' }
SierpinskiCarpetTest >> testLevelTwoHas64Cells [
	self assert: (SierpinskiCarpet level: 2) cells size equals: 64
]

{ #category : 'tests' }
SierpinskiCarpetTest >> testLevelTwoHolesAreEmpty [
	| carpet |
	carpet := SierpinskiCarpet level: 2.
	"the central 3x3 block"
	3 to: 5 do: [ :x | 3 to: 5 do: [ :y |
		self deny: (carpet cells includes: x @ y) ] ].
	"the centre cell of each remaining 3x3 block"
	#(1 4 7) do: [ :x | #(1 4 7) do: [ :y |
		(x = 4 and: [ y = 4 ]) ifFalse: [
			self deny: (carpet cells includes: x @ y) ] ] ]
]
