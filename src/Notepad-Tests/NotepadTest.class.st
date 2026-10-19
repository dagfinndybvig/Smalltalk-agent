Class {
	#name : 'NotepadTest',
	#superclass : 'TestCase',
	#category : 'Notepad-Tests',
	#package : 'Notepad-Tests'
}

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
