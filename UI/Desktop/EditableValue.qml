import QtQuick
import QtQuick.Controls

// Edits a draft, emitting a value to the owner without replacing its binding.
TextField {
    id: control
    property real value: 0
    property real minimumValue: 0
    property real maximumValue: 100
    property real stepSize: 0
    property int decimals: 1
    property string unit: ""
    property string parameterName: "Value"
    signal valueCommitted(real newValue)

    property string initialText: ""
    property bool finishing: false

    selectByMouse: true
    horizontalAlignment: TextInput.AlignRight
    maximumLength: 32
    Accessible.name: parameterName + (unit ? " (" + unit + ")" : "")
    ToolTip.visible: hovered
    ToolTip.text: "Click to edit; Enter applies, Escape cancels. Range: "
                  + minimumValue + " to " + maximumValue + " " + unit

    function refreshText() {
        text = Number(value.toFixed(decimals)).toString()
               + (!activeFocus && unit ? " " + unit : "")
    }

    function commit() {
        const draft = text.trim()
        if (draft === initialText) { refreshText(); return }
        // Validate the whole number, rejecting partial numbers, NaN and infinity.
        if (/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$/.test(draft)) {
            let number = Number(draft)
            if (isFinite(number)) {
                number = Math.max(minimumValue, Math.min(maximumValue, number))
                if (stepSize > 0)
                    number = minimumValue + Math.round((number - minimumValue) / stepSize) * stepSize
                number = Math.max(minimumValue, Math.min(maximumValue,
                                  Number(number.toFixed(decimals))))
                if (number !== value)
                    valueCommitted(number)
            }
        }
        refreshText()
    }

    onValueChanged: if (!activeFocus) refreshText()
    onActiveFocusChanged: {
        if (activeFocus) {
            refreshText()
            initialText = text
            selectAll()
        } else if (!finishing) {
            commit()
        }
    }
    function finish(apply) {
        finishing = true
        if (apply) commit()
        focus = false
        refreshText()
        finishing = false
    }
    Keys.onReturnPressed: finish(true)
    Keys.onEnterPressed: finish(true)
    Keys.onEscapePressed: finish(false)
    Component.onCompleted: refreshText()
}
