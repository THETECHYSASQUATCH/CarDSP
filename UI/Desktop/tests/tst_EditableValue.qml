import QtQuick
import QtTest
import ".."

TestCase {
    name: "EditableValue"
    width: 300
    height: 100
    when: windowShown
    property real sourceValue: 25
    EditableValue {
        id: editor
        width: 180
        value: sourceValue
        onValueCommitted: function(number) { sourceValue = number }
    }
    SignalSpy { id: commits; target: editor; signalName: "valueCommitted" }
    function init() {
        editor.finish(false)
        editor.minimumValue = 0
        editor.maximumValue = 100
        editor.stepSize = 0
        editor.decimals = 1
        editor.unit = "%"
        sourceValue = 25
        editor.refreshText()
        commits.clear()
    }
    function edit(draft, key) {
        editor.forceActiveFocus()
        editor.text = draft
        keyClick(key)
    }
    function test_enterAndBinding() {
        edit("37.5", Qt.Key_Return)
        compare(sourceValue, 37.5)
        compare(commits.count, 1)
        compare(editor.text, "37.5 %")
        sourceValue = 60
        compare(editor.text, "60 %")
    }
    function test_unchangedFocusPreservesPrecision() {
        sourceValue = 25.123
        editor.forceActiveFocus()
        editor.focus = false
        compare(sourceValue, 25.123)
        compare(commits.count, 0)
    }
    function test_escape() {
        editor.stepSize = 0.5
        sourceValue = 25.2
        edit("90", Qt.Key_Escape)
        compare(sourceValue, 25.2)
        compare(commits.count, 0)
    }
    function test_validation() {
        for (const draft of ["", "-", "12junk", "NaN", "Infinity", "1e99"]) {
            edit(draft, Qt.Key_Return)
            compare(sourceValue, 25)
            compare(editor.text, "25 %")
        }
        compare(commits.count, 0)
    }
    function test_clamp() {
        edit("120", Qt.Key_Return)
        compare(sourceValue, 100)
        edit("-20", Qt.Key_Enter)
        compare(sourceValue, 0)
    }
    function test_gainStep() {
        editor.minimumValue = -18
        editor.maximumValue = 18
        editor.stepSize = 0.5
        editor.unit = "dB"
        edit("-3.3", Qt.Key_Return)
        compare(sourceValue, -3.5)
        compare(editor.text, "-3.5 dB")
    }
    function test_frequencyAndQ() {
        editor.minimumValue = 20
        editor.maximumValue = 20000
        editor.unit = "Hz"
        edit("31.5", Qt.Key_Return)
        compare(sourceValue, 31.5)
        editor.minimumValue = 0.1
        editor.maximumValue = 30
        editor.decimals = 2
        editor.unit = "Q"
        edit("0.71", Qt.Key_Return)
        compare(sourceValue, 0.71)
        compare(editor.text, "0.71 Q")
    }
    function test_focusLossAndExternalUpdate() {
        editor.forceActiveFocus()
        editor.text = "42"
        sourceValue = 30
        compare(editor.text, "42")
        editor.focus = false
        compare(sourceValue, 42)
        compare(commits.count, 1)
    }
}
