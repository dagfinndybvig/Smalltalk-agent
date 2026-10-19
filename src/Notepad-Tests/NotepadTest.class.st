Class {
	#name : 'NotepadTest',
	#superclass : 'TestCase',
	#category : 'Notepad-Tests',
	#package : 'Notepad-Tests'
}

{ #category : 'tests' }
NotepadTest >> testAcceptWithFileSaves [
	| n f |
	f := FileLocator temp / 'notepad-test-accept.txt'.
	f ensureDelete.
	n := Notepad on: 'accepted'.
	n file: f.
	n textAccepted.
	self assert: f contents equals: 'accepted'.
	f ensureDelete
]

{ #category : 'tests - editor' }
NotepadTest >> testBindCtrlSOnTextArea [
	"Keyboard focus sits on the text area and only the focus
	morph's KM dispatcher is consulted for a real keystroke;
	bindCtrlSOn: is called from openView on the live text area
	(build-time bindings are wiped when Rubric opens the editor)."
	| n area |
	n := Notepad on: 'x'.
	area := RubScrolledTextMorph new textArea.
	n bindCtrlSOn: area.
	self assert: (area kmDispatcher directKeymaps commonEntries keymaps
		anySatisfy: [:entry | entry shortcut = (KMModifier ctrl + $s asKeyCombination)])
]

{ #category : 'tests' }
NotepadTest >> testBuildEditorAlwaysAccepts [
	| n m |
	n := Notepad on: 'x'.
	m := n buildEditor.
	self assert: m alwaysAccept.
	self assert: m text asString equals: 'x'
]

{ #category : 'tests - editor' }
NotepadTest >> testBuildEditorBindsCtrlS [
	"On Windows, Rubric's own Meta+S accept binding never matches a
	physical Ctrl+S (Meta != Ctrl there), so Notepad binds Ctrl+S on
	the editor morph itself."
	| n morph |
	n := Notepad on: 'x'.
	morph := n buildEditor.
	self assert: (morph kmDispatcher directKeymaps commonEntries keymaps
		anySatisfy: [:entry | entry shortcut = (KMModifier ctrl + $s asKeyCombination)])
]

{ #category : 'tests' }
NotepadTest >> testLabelStringWithFile [
	| n |
	n := Notepad new.
	n file: 'notes.txt' asFileReference.
	self assert: n labelString equals: 'Notepad - notes.txt'
]

{ #category : 'tests' }
NotepadTest >> testLabelStringWithoutFile [
	self assert: Notepad new labelString equals: 'Notepad'
]

{ #category : 'tests' }
NotepadTest >> testNewIsEmpty [
	self assert: Notepad new text isEmpty
]

{ #category : 'tests' }
NotepadTest >> testOnPresetText [
	self assert: (Notepad on: 'abc') text equals: 'abc'
]

{ #category : 'tests' }
NotepadTest >> testSaveToWritesFile [
	| n f |
	f := FileLocator temp / 'notepad-test-save.txt'.
	f ensureDelete.
	n := Notepad on: 'saved text'.
	n saveTo: f.
	self assert: f contents equals: 'saved text'.
	f ensureDelete
]

{ #category : 'tests - saving' }
NotepadTest >> testSaveToWritesTextContent [
	"editor text is a Text, not a String - saving must write its
	characters instead of failing with
	doesNotUnderstand: #isByteString (which leaves a 0-byte file
	and never sets the file ivar)."
	| n tmp |
	n := Notepad on: 'save me'.
	n text: 'save me' asText.
	tmp := FileLocator temp / 'notepad-test-save.txt'.
	n saveTo: tmp.
	self assert: tmp contents = 'save me'
]

{ #category : 'tests' }
NotepadTest >> testSaveUsesFile [
	| n f |
	f := FileLocator temp / 'notepad-test-file.txt'.
	f ensureDelete.
	n := Notepad on: 'abc'.
	n file: f.
	n save.
	self assert: f contents equals: 'abc'.
	f ensureDelete
]

{ #category : 'tests' }
NotepadTest >> testSaveWithoutFileErrors [
	self should: [ Notepad new save ] raise: Error
]

{ #category : 'tests' }
NotepadTest >> testTextRoundTrip [
	| n |
	n := Notepad new.
	n text: 'hello'.
	self assert: n text equals: 'hello'
]
