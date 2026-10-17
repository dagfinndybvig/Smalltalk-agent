"""Generate AgentSession compile payloads for the in-image agent.

Produces demo/agent-00..04 payloads: the AgentSession class, a
tool-calling loop against an OpenAI-compatible chat completions API
(default: Mistral), and three native tools (eval, run_tests,
get_method_source). The API key is read at call time from the
MISTRAL_API_KEY environment variable via OSEnvironment - it is never
stored in the image.
"""
import json
from pathlib import Path

OUT = Path(__file__).resolve().parent / "demo"


def st_str(s):
    """Encode method source as a Smalltalk string literal."""
    return "'" + s.replace("'", "''") + "'"


create = (
    "Object << #AgentSession slots: { #model. #messages. #iterations. #maxIterations }; "
    "package: 'AgentTerminal'; install. #created"
)

initialize = """initialize
	super initialize.
	model := 'mistral-small-latest'.
	messages := OrderedCollection new.
	iterations := 0.
	maxIterations := 25.
	self messages add: (Dictionary new at: 'role' put: 'system'; at: 'content' put: self systemPrompt; yourself)"""

messages_accessor = """messages
	^ messages"""

system_prompt = """systemPrompt
	^ 'You are a coding agent operating INSIDE a live Pharo 13 Smalltalk image. You change the system by evaluating Smalltalk code via the eval tool. You MAY issue several tool calls in one turn. Pharo 13 rules: class creation is only the fluid API - Object << #Name slots: ... ; package: ...; install - and the class does not exist until install is sent; the old subclass selectors were removed. An eval is compiled entirely before it runs, so define a class in one eval and use it in a later one. String literals are single-quoted; an empty string is two single quotes; double quotes are comments. To install methods use compile: with the source as a single-quoted string: instance side example: GameOfLife compile: ''greet ^ 42''. Class side example: GameOfLife class compile: ''blinker ^ self new withAll: { 0 @ 1. 1 @ 1. 2 @ 1 }''. Double every single quote that belongs inside the method source. If the result of an eval is not a simple object, end it with a symbol like #done. The GameOfLife package with tests is loaded in this image.'"""

log = """log: aString
	Transcript crShow: aString"""

add_string = """addString: role content: aString
	messages add: (Dictionary new at: 'role' put: role; at: 'content' put: aString; yourself)"""

tools_spec = """toolsSpec
	^ NeoJSONReader fromString: '[{"type":"function","function":{"name":"eval","description":"Evaluate Smalltalk code in the live image. Returns the result printString. Errors come back with description and stack.","parameters":{"type":"object","properties":{"code":{"type":"string","description":"Smalltalk code to evaluate"}},"required":["code"]}}},{"type":"function","function":{"name":"run_tests","description":"Run the SUnit test suite of a TestCase subclass in the live image.","parameters":{"type":"object","properties":{"class_name":{"type":"string"}},"required":["class_name"]}}},{"type":"function","function":{"name":"get_method_source","description":"Return the source code of a method of a class in the live image - instance side first, then class side.","parameters":{"type":"object","properties":{"class_name":{"type":"string"},"method_name":{"type":"string"}},"required":["class_name","method_name"]}}}]'"""

api_key = """apiKey
	^ OSEnvironment current at: 'MISTRAL_API_KEY' ifAbsent: [ self error: 'MISTRAL_API_KEY is not set in the environment' ]"""

request = """request
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
	^ client post"""

ask = """ask: aString
	self log: 'USER: ', aString.
	self addString: 'user' content: aString.
	^ self runLoop"""

run_loop = """runLoop
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
	^ self runLoop"""

execute_tool_call = """executeToolCall: call
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
		yourself)"""

perform_tool = """performTool: name with: args
	name = 'eval' ifTrue: [ ^ self evalTool: (args at: 'code') ].
	name = 'run_tests' ifTrue: [ ^ self runTestsTool: (args at: 'class_name') ].
	name = 'get_method_source' ifTrue: [ ^ self methodSourceTool: (args at: 'class_name') method: (args at: 'method_name') ].
	^ 'Unknown tool: ', name"""

eval_tool = """evalTool: code
	^ [ (self class compiler evaluate: code) printString ]
		on: Error
		do: [ :e |
			'ERROR: ', e description, String cr,
			([ (e signalerContext stack copyUpTo: 12) printString ] on: Error do: [ '' ]) ]"""

run_tests_tool = """runTestsTool: className
	| cls result |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'No such class: ', className ].
	result := cls suite run.
	^ result printString"""

method_source_tool = """methodSourceTool: className method: methodName
	| cls |
	cls := Smalltalk globals at: className asSymbol ifAbsent: [ ^ 'No such class: ', className ].
	(cls includesSelector: methodName asSymbol)
		ifTrue: [ ^ cls sourceCodeAt: methodName asSymbol ].
	(cls class includesSelector: methodName asSymbol)
		ifTrue: [ ^ (cls class sourceCodeAt: methodName asSymbol) printString, ' (class side)' ].
	^ 'No such method: ', className, '>>', methodName"""

class_ask = """ask: aString
	^ self new ask: aString"""

payloads = {
    "agent-00-create.json": create,
    "agent-01-core.json":
        f"AgentSession compile: {st_str(initialize)}. "
        + f"AgentSession compile: {st_str(system_prompt)}. "
        + f"AgentSession compile: {st_str(log)}. "
        + f"AgentSession compile: {st_str(add_string)}. "
        + f"AgentSession compile: {st_str(messages_accessor)}. #agentCore1",
    "agent-02-api.json":
        f"AgentSession compile: {st_str(tools_spec)}. "
        + f"AgentSession compile: {st_str(api_key)}. "
        + f"AgentSession compile: {st_str(request)}. #agentCore2",
    "agent-03-loop.json":
        f"AgentSession compile: {st_str(ask)}. "
        + f"AgentSession compile: {st_str(run_loop)}. "
        + f"AgentSession compile: {st_str(execute_tool_call)}. "
        + f"AgentSession compile: {st_str(perform_tool)}. #agentCore3",
    "agent-04-tools.json":
        f"AgentSession compile: {st_str(eval_tool)}. "
        + f"AgentSession compile: {st_str(run_tests_tool)}. "
        + f"AgentSession compile: {st_str(method_source_tool)}. "
        + f"AgentSession class compile: {st_str(class_ask)}. #agentCore4",
}

for name, code in payloads.items():
    (OUT / name).write_text(json.dumps({"code": code}), encoding="utf-8")
    print(f"wrote demo/{name}")
