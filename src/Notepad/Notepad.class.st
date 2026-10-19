Class {
	#name : 'Notepad',
	#superclass : 'Object',
	#instVars : [
		'text',
		'file',
		'editor',
		'window'
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

{ #category : 'views' }
Notepad >> bindCtrlSOn: aMorph [
	"Bind Ctrl+S on a LIVE morph of the open editor. Called from
	openView after openInWorld: Rubric replaces the editing area when
	the morph is opened, so bindings installed in buildEditor on the
	text area are lost. Only the keyboard-focus morph's KM dispatcher
	is consulted for a real keystroke, and focus sits on the text
	area - hence this late binding. Needed on Windows because
	Rubric's own Meta+S accept shortcut never matches a physical
	Ctrl+S there (Meta != Ctrl)."
	aMorph bindKeyCombination: KMModifier ctrl + $s asKeyCombination toAction: [ self textAccepted. true ]
]

{ #category : 'views' }
Notepad >> buildEditor [
	"The Rubric editor for openView. alwaysAccept makes Ctrl+S work
	even when Rubric sees no unaccepted edits - without it the morph
	just flashes and never announces RubTextAccepted. The morph-level
	Ctrl+S binding covers the case where the outer morph holds
	keyboard focus; the text area gets its binding in openView via
	bindCtrlSOn: (Rubric wipes build-time text-area bindings on
	open). Needed on Windows: Rubric's own Meta+S accept shortcut
	never matches a physical Ctrl+S there (Meta != Ctrl)."
	| morph |
	morph := RubScrolledTextMorph new.
	morph beWrapped.
	morph alwaysAccept: true.
	morph setText: text.
	morph bindKeyCombination: KMModifier ctrl + $s asKeyCombination toAction: [ self textAccepted. true ].
	editor := morph.
	morph textArea announcer
		when: RubTextAccepted
		send: #textAccepted
		to: self.
	^ morph
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
Notepad >> labelString [
	^ 'Notepad', (file ifNotNil: [ ' - ', file basename ] ifNil: [ '' ])
]

{ #category : 'views' }
Notepad >> openView [
	"Open a wrapped Rubric editor on the text. Ctrl+S saves: to the
	set file, or via a save-as dialog when none is set."
	window := SystemWindow new.
	window setLabel: self labelString.
	window addMorph: self buildEditor frame: (0 @ 0 corner: 1 @ 1).
	window extent: 500 @ 400.
	window openInWorld.
	window position: 60 @ 60.
	self bindCtrlSOn: editor textArea.
	^ window
]

{ #category : 'saving' }
Notepad >> requestSaveFileReference [
	^ UIManager default
		chooseForSaveFileReference: 'Save Notepad as...'
		extensions: #( 'txt' )
		path: FileLocator documents
]

{ #category : 'saving' }
Notepad >> save [
	file ifNil: [ self error: 'No file set: use saveTo: first' ].
	^ self saveTo: file
]

{ #category : 'saving' }
Notepad >> saveAs [
	"Ask for a destination file, then save there. Does nothing when
	the dialog is cancelled."
	| chosen |
	chosen := self requestSaveFileReference.
	chosen ifNil: [ ^ nil ].
	^ self saveTo: chosen
]

{ #category : 'saving' }
Notepad >> saveTo: aFileReference [
	aFileReference writeStreamDo: [ :stream | stream nextPutAll: text ].
	file := aFileReference.
	self updateTitle.
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
	editor ifNotNil: [ text := editor text ].
	file ifNotNil: [ self save ] ifNil: [ self saveAs ]
]

{ #category : 'views' }
Notepad >> updateTitle [
	window ifNotNil: [ window setLabel: self labelString ]
]
