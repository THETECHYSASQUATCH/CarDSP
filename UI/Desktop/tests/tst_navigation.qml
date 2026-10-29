import QtQuick
import QtQuick.Controls
import QtTest
import ".."

TestCase {
    id: testCase
    name: "PageNavigation"
    when: windowShown
    width: 1100
    height: 600
    Component {
        id: shellComponent
        PageShell {
            width: 1100
            height: 400
            Rectangle { objectName: "dashboard" }
            Rectangle { objectName: "equalizer" }
            Rectangle { objectName: "spectrum" }
            Rectangle { objectName: "routing" }
            Rectangle { objectName: "crossovers" }
            Rectangle { objectName: "alignment" }
            Rectangle { objectName: "presets" }
            Rectangle { objectName: "settings" }
        }
    }
    function test_eachPageIsExclusive() {
        const shell = createTemporaryObject(shellComponent, testCase)
        verify(shell !== null)
        const names = ["dashboard", "equalizer", "spectrum", "routing", "crossovers", "alignment", "presets", "settings"]
        for (let selected = 0; selected < names.length; ++selected) {
            shell.selectPage(selected)
            compare(shell.currentIndex, selected)
            for (let page = 0; page < names.length; ++page)
                tryCompare(findChild(shell, names[page]), "visible", page === selected)
        }
        shell.selectPage(-1)
        compare(shell.currentIndex, 7)
        shell.selectPage(99)
        compare(shell.currentIndex, 7)
    }
    function test_compactNavigationPreservesSelection() {
        const shell = createTemporaryObject(shellComponent, testCase)
        shell.selectPage(2)
        compare(shell.compact, false)
        shell.width = 640
        compare(shell.compact, true)
        const picker = findChild(shell, "compactNavigation")
        tryCompare(picker, "visible", true)
        compare(picker.currentIndex, 2)
        shell.selectPage(6)
        compare(picker.currentIndex, 6)
        shell.width = 1100
        compare(shell.compact, false)
        compare(shell.currentIndex, 6)
    }
}
