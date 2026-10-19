Class {
	#name : 'Notepad',
	#superclass : 'Object',
	#instVars : [
		'text',
		'file',
		'editor'
	],
	#category : 'Notepad',
	#package : 'Notepad'
}

{ #category : 'instance creation' }
Notepad class >> on: aString [
	^ self new initializeText: aString
]

{ #category : 'views' }
Notepad class >> open [
	^ self new openView
]

{ #category : 'accessing' }
Notepad >> file [
	^ file
]

{ #category : 'accessing' }
Notepad >> file: aFileReference [
	file := aFileReference
]

{ #category : 'initialization' }
Notepad >> initialize [
	super initialize.
	text := ''
]

{ #category : 'initialization' }
Notepad >> initializeText: aString [
	super initialize.
	text := aString
]

{ #category : 'views' }
Notepad >> openView [
	"Open a wrapped Rubric editor on the text. Ctrl+S (accept) updates
	the model and, when a file is set, saves to it."
	| window |
	editor := RubScrolledTextMorph new.
	editor beWrapped.
	editor setText: text.
	editor textArea announcer
		when: RubTextAccepted
		send: #textAccepted
		to: self.
	window := SystemWindow new.
	window setLabel: 'Notepad', (file ifNotNil: [ ' - ', file basename ] ifNil: [ '' ]).
	window addMorph: editor frame: (0 @ 0 corner: 1 @ 1).
	window extent: 500 @ 400.
	window openInWorld.
	window position: 60 @ 60.
	^ window
]

{ #category : 'saving' }
Notepad >> save [
	file ifNil: [ self error: 'No file set: use saveTo: first' ].
	^ self saveTo: file
]

{ #category : 'saving' }
Notepad >> saveTo: aFileReference [
	aFileReference writeStreamDo: [ :stream | stream nextPutAll: text ].
	file := aFileReference.
	^ aFileReference
]

{ #category : 'accessing' }
Notepad >> text [
	^ text
]

{ #category : 'accessing' }
Notepad >> text: aString [
	text := aString
]

{ #category : 'views' }
Notepad >> textAccepted [
	text := editor text.
	file ifNotNil: [ self save ]
]
