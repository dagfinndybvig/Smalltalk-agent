Class {
	#name : 'BoingSoundLibrary',
	#superclass : 'FFILibrary',
	#category : 'BoingBall',
	#package : 'BoingBall'
}

{ #category : 'as yet unclassified' }
BoingSoundLibrary >> macLibraryName [
	^ 'libwinmm.dylib'
]

{ #category : 'as yet unclassified' }
BoingSoundLibrary >> unix32LibraryName [
	^ 'libwinmm.so'
]

{ #category : 'as yet unclassified' }
BoingSoundLibrary >> unix64LibraryName [
	^ 'libwinmm.so'
]

{ #category : 'as yet unclassified' }
BoingSoundLibrary >> win32LibraryName [
	^ 'winmm.dll'
]
