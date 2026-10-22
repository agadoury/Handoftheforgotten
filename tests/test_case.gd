class_name TestCase
extends RefCounted
## Base for tests run by tests/run_tests.gd. Every method named test_* is a test.
## A stand-in until GUT is added (see DESIGN.md); the method names already follow GUT's style.

var failures: PackedStringArray = []
var tree: SceneTree
## Nodes a test added to the tree; freed after it.
var _owned: Array[Node] = []


func add_to_tree(node: Node) -> void:
	tree.root.add_child(node)
	_owned.append(node)


func after_each() -> void:
	for node in _owned:
		node.queue_free()
	_owned.clear()


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func assert_almost_eq(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		failures.append("%s: expected %.6f, got %.6f" % [message, expected, actual])
