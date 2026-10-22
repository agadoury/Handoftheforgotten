#!/bin/sh
# Checks the project the way the end of every phase requires: it loads with no script errors or
# warnings (warnings are promoted to errors for this run), and all tests pass headless.
#   GODOT=/path/to/godot tools/check.sh
set -u
GODOT="${GODOT:-/Applications/Godot.app/Contents/MacOS/Godot}"
cd "$(dirname "$0")/.." || exit 1

WARNINGS="unassigned_variable unassigned_variable_op_assign unused_variable unused_local_constant
unused_private_class_variable unused_parameter unused_signal shadowed_variable shadowed_variable_base_class
shadowed_global_identifier unreachable_code unreachable_pattern standalone_expression standalone_ternary
incompatible_ternary static_called_on_instance redundant_static_unload redundant_await assert_always_true
assert_always_false integer_division narrowing_conversion int_as_enum_without_cast int_as_enum_without_match
enum_variable_without_default deprecated_keyword confusable_identifier confusable_local_declaration
confusable_local_usage confusable_capture_reassignment inference_on_variant native_method_override
get_node_default_without_onready onready_with_export missing_await"
{
	echo "[debug]"
	for w in $WARNINGS; do echo "gdscript/warnings/$w=2"; done
} > override.cfg
trap 'rm -f override.cfg' EXIT

"$GODOT" --headless --path . --import > /dev/null 2>&1
load_log=$("$GODOT" --headless --path . --quit-after 10 2>&1)
shot_log=$("$GODOT" --headless --path . --quit-after 2 res://debug/shot.tscn -- --poses=res://debug/shot_poses_start.json --out=/tmp/hotf-check 2>&1)
problems=$(printf '%s\n%s\n' "$load_log" "$shot_log" | grep -E "SCRIPT ERROR|Parse Error|Compile Error" || true)
if [ -n "$problems" ]; then
	echo "Script errors or warnings:"
	echo "$problems"
	exit 1
fi
echo "Project loads with no script errors or warnings."
test_log=$("$GODOT" --headless --path . -s res://tests/run_tests.gd 2>&1)
status=$?
printf '%s\n' "$test_log" | grep -vE "^Godot Engine|^$"
exit $status
