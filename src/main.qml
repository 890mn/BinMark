import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI 1.0

FluWindow {
    width: 1000
    height: 600
    minimumWidth: 600
    minimumHeight: 400
    title: "BinMark"

    RowLayout {
        anchors.fill: parent
        spacing: 10
        anchors.margins: 10

        // 左边：文件夹树，占比固定：stretch: 3
        FileTree {
            Layout.fillHeight: true
            Layout.preferredWidth: 240 // 固定宽度（推荐）
            Layout.minimumWidth: 160
            Layout.maximumWidth: 300
        }

        // 右边：展示区，占比 stretch: 7
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: 400
            spacing: 10

            // 上部展示图区
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 480
                Layout.fillHeight: true
                spacing: 10

                // 当前图
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: "#cccccc"
                    radius: 5

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: imageManager.currentImage
                    }
                }

                // 上一个好图
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    border.color: "#cccccc"
                    radius: 5

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: imageManager.lastGoodImage
                    }
                }
            }

            // 下部按钮区
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                FluButton {
                    text: "👍 好图 (Ctrl+H)"
                    onClicked: imageManager.markCurrent(true)
                }

                FluButton {
                    text: "👎 坏图 (Ctrl+B)"
                    onClicked: imageManager.markCurrent(false)
                }

                FluButton {
                    text: "➡️ 下一张 (→)"
                    onClicked: imageManager.next()
                }

                FluButton {
                    text: "⬅️ 上一张 (←)"
                    onClicked: imageManager.previous()
                }
            }
        }
    }

    // 快捷键
    Shortcut { sequence: "Right"; onActivated: imageManager.next() }
    Shortcut { sequence: "Left"; onActivated: imageManager.previous() }
    Shortcut { sequence: "Ctrl+H"; onActivated: imageManager.markCurrent(true) }
    Shortcut { sequence: "Ctrl+B"; onActivated: imageManager.markCurrent(false) }
}
