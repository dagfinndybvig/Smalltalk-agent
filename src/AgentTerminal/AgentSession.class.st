Class {
	#name : 'AgentSession',
	#superclass : 'Object',
	#instVars : [
		'model',
		'messages',
		'iterations',
		'maxIterations'
	],
	#category : 'AgentTerminal',
	#package : 'AgentTerminal'
}

{ #category : 'tools' }
AgentSession >> addString: role content: aString [
	messages add: (Dictionary new at: 'role' put: role; at: 'content' put: aString; yourself)
]

{ #category : 'private' }
AgentSession >> apiKey [
	^ OSEnvironment current at: 'MISTRAL_API_KEY' ifAbsent: [ self error: 'MISTRAL_API_KEY is not set in the environment' ]
]

{ #category : 'api' }
AgentSession >> ask: aString [
	self log: 'USER: ', aString.
	self addString: 'user' content: aString.
	^ self runLoop
]

{ #category : 'tools' }
AgentSession >> evalTool: code [
	^ [ (self class compiler evaluate: code) printString ]
		on: Error
		do: [ :e |
			'ERROR: ', e description, String cr,
			([ (e signalerContext stack copyUpTo: 12) printString ] on: Error do: [ '' ]) ]
]

{ #category : 'tools' }
AgentSession >> executeToolCall: call [
	| name args result |
	name := (call at: 'function') at: 'name'.
	args := NeoJSONReader fromString: ((call at: 'function') at: 'arguments').
	result := [ self performTool: name with: args ]
		on: Error
		do: [ :e | 'TOOL ERROR: ', e description ].
	self log: 'RESULT: ', result printString.
	self messages add: (Dictionary new
		at: 'role' put: 'tool';
		at: 'tool_call_id' put: (call at: 'id');
		at: 'content' put: result;
		yourself)
]

{ #category : 'initialization' }
AgentSession >> initialize [
	super initialize.
	model := 'mistral-small-latest'.
	messages := OrderedCollection new.
	iterations := 0.
	maxIterations := 25.
	self messages add: (Dictionary new at: 'role' put: 'system'; at: 'content' put: self systemPrompt; yourself)
]

{ #category : 'logging' }
AgentSession >> log: aString [
	Transcript crShow: aString
]

{ #category : 'accessing' }
AgentSession >> messages [
	^ messages
]

{ #category : 'tools' }
AgentSession >> methodSourceTool: className method: methodName [
	| cls |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'No such class: ', className ].
	(cls includesSelector: methodName asSymbol)
		ifTrue: [ ^ cls sourceCodeAt: methodName asSymbol ].
	(cls class includesSelector: methodName asSymbol)
		ifTrue: [ ^ (cls class sourceCodeAt: methodName asSymbol) printString, ' (class side)' ].
	^ 'No such method: ', className, '>>', methodName
]

{ #category : 'tools' }
AgentSession >> performTool: name with: args [
	name = 'eval' ifTrue: [ ^ self evalTool: (args at: 'code') ].
	name = 'run_tests' ifTrue: [ ^ self runTestsTool: (args at: 'class_name') ].
	name = 'get_method_source' ifTrue: [ ^ self methodSourceTool: (args at: 'class_name') method: (args at: 'method_name') ].
	^ 'Unknown tool: ', name
]

{ #category : 'api' }
AgentSession >> request [
	| body client |
	body := NeoJSONWriter toString: (Dictionary new
		at: 'model' put: model;
		at: 'messages' put: messages;
		at: 'tools' put: self toolsSpec;
		at: 'tool_choice' put: 'auto';
		yourself).
	client := ZnClient new
		url: 'https://api.mistral.ai/v1/chat/completions';
		headerAt: 'Authorization' put: 'Bearer ' , self apiKey;
		contents: body;
		contentType: ZnMimeType applicationJson;
		contentReader: [ :entity | NeoJSONReader fromString: entity contents ];
		yourself.
	^ client post
]

{ #category : 'running' }
AgentSession >> runLoop [
	| response message content |
	iterations := iterations + 1.
	iterations > maxIterations ifTrue: [ self error: 'Max iterations exceeded' ].
	response := self request.
	message := (response at: 'choices') first at: 'message'.
	content := message at: 'content' ifAbsent: [ nil ].
	(message at: 'tool_calls' ifAbsent: [ nil ])
		ifNil: [
			self messages add: message.
			self log: 'AGENT: ', (content ifNil: [ String empty ]).
			^ content ifNil: [ String empty ] ].
	self messages add: message.
	(message at: 'tool_calls') do: [ :call |
		self log: 'TOOL: ', ((call at: 'function') at: 'name') ].
	(message at: 'tool_calls') do: [ :call | self executeToolCall: call ].
	^ self runLoop
]

{ #category : 'tools' }
AgentSession >> runTestsTool: className [
	| cls result |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'No such class: ', className ].
	result := cls suite run.
	^ result printString
]

{ #category : 'private' }
AgentSession >> systemPrompt [
	^ 'You are a coding agent operating INSIDE a live Pharo 13 Smalltalk image. You change the system by evaluating Smalltalk code via the eval tool. You MAY issue several tool calls in one turn. Pharo 13 rules: class creation is only the fluid API - Object << #Name slots: ... ; package: ...; install - and the class does not exist until install is sent; the old subclass selectors were removed. An eval is compiled entirely before it runs, so define a class in one eval and use it in a later one. String literals are single-quoted; an empty string is two single quotes; double quotes are comments. To install methods use compile: with the source as a single-quoted string: instance side example: GameOfLife compile: ''greet ^ 42''. Class side example: GameOfLife class compile: ''blinker ^ self new withAll: { 0 @ 1. 1 @ 1. 2 @ 1 }''. Double every single quote that belongs inside the method source. If the result of an eval is not a simple object, end it with a symbol like #done. The GameOfLife package with tests is loaded in this image.'
]

{ #category : 'tools' }
AgentSession >> toolsSpec [
	^ NeoJSONReader fromString: '[{"type":"function","function":{"name":"eval","description":"Evaluate Smalltalk code in the live image. Returns the result printString. Errors come back with description and stack.","parameters":{"type":"object","properties":{"code":{"type":"string","description":"Smalltalk code to evaluate"}},"required":["code"]}}},{"type":"function","function":{"name":"run_tests","description":"Run the SUnit test suite of a TestCase subclass in the live image.","parameters":{"type":"object","properties":{"class_name":{"type":"string"}},"required":["class_name"]}}},{"type":"function","function":{"name":"get_method_source","description":"Return the source code of a method of a class in the live image - instance side first, then class side.","parameters":{"type":"object","properties":{"class_name":{"type":"string"},"method_name":{"type":"string"}},"required":["class_name","method_name"]}}}]'
]
