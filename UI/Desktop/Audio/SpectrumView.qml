import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    color: "#101b24"
    radius: 8
    border.color: "#344653"

    property var spectrumData: []
    property real minimumDb: -90
    property real maximumDb: 0

    Accessible.name: "Live microphone frequency spectrum"

    Canvas {
        id: graph
        anchors.fill: parent
        anchors.margins: 12
        anchors.bottomMargin: 30

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var w = width
            var h = height

            ctx.strokeStyle = "#30414f"
            ctx.lineWidth = 1

            for (var line = 0; line <= 4; ++line) {
                var y = h * line / 4

                ctx.beginPath()
                ctx.moveTo(0, y)
                ctx.lineTo(w, y)
                ctx.stroke()
            }

            var values = root.spectrumData || []
            var count = values.length

            if (count === 0)
                return

            var spacing = 2
            var barWidth = Math.max(1, w / count - spacing)

            for (var i = 0; i < count; ++i) {
                var db = Number(values[i])

                if (!isFinite(db))
                    continue

                var normalized = Math.max(
                    0,
                    Math.min(1,
                        (db - root.minimumDb) /
                        (root.maximumDb - root.minimumDb)
                    )
                )

                var barHeight = normalized * h

                ctx.fillStyle = normalized > 0.75
                    ? "#f5b74f"
                    : "#40b6b0"

                ctx.fillRect(
                    i * w / count,
                    h - barHeight,
                    barWidth,
                    barHeight
                )
            }
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    onSpectrumDataChanged: graph.requestPaint()

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 7

        Repeater {
            model: ["20 Hz", "100", "1 kHz", "10 kHz", "20 kHz"]

            Label {
                width: parent.width / 5
                text: modelData
                color: "#aab9c5"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
