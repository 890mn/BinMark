import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI 1.0

import Qt.labs.folderlistmodel
import QtQuick.Dialogs
import Qt.labs.platform as Platform

FluWindow {
    width: 1000
    height: 600
    minimumWidth: 600
    minimumHeight: 400
    title: "BinMark"

    property url selectedFolder: ""

    RowLayout {
        anchors.fill: parent
        spacing: 10
        anchors.margins: 10

        // 左边文件夹树（固定宽度）
        ColumnLayout {
            Layout.preferredWidth: 240
            Layout.minimumWidth: 160
            Layout.maximumWidth: 300
            Layout.fillHeight: true
            spacing: 8

            Platform.FileDialog {
                id: folderPicker
                title: "选择图片所在文件夹"
                onAccepted: {
                    selectedFolder = folderPicker.folder
                    folderModel.folder = folderPicker.folder
                    globalImageManager.loadFromFolder(folderPicker.folder)
                }
            }

            Button {
                text: "📁 选择父文件夹"
                onClicked: folderPicker.open()
            }

            Text {
                text: selectedFolder
                font.pixelSize: 12
                wrapMode: Text.Wrap
                elide: Text.ElideLeft
                maximumLineCount: 2
                Layout.fillWidth: true
            }

            FolderListModel {
                id: folderModel
                folder: selectedFolder
                showDirs: true
                showFiles: false
            }

            ListView {
                id: folderList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: folderModel

                delegate: ItemDelegate {
                    text: fileName
                    icon.name: "folder"
                    onClicked: {
                        const path = selectedFolder + "/" + fileName
                        console.log("📂 点击进入子目录:", path)
                        selectedFolder = path
                        folderModel.folder = path
                        globalImageManager.loadFromFolder(path)
                    }
                }
            }
        }

        // 右边展示区域
        ColumnLayout {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.minimumWidth: 400
            spacing: 10

            // 展示图区域（两张图）
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 480
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    border.color: "#cccccc"
                    radius: 5
                    color: "#f8f8f8"

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: globalImageManager.currentImage
                        onStatusChanged: {
                            if (status === Image.Error)
                                console.log("❌ 当前图加载失败:", source)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    border.color: "#dddddd"
                    radius: 5
                    color: "#fcfcfc"

                    Image {
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectFit
                        source: globalImageManager.lastGoodImage
                        onStatusChanged: {
                            if (status === Image.Error)
                                console.log("❌ 上一个好图加载失败:", source)
                        }
                    }
                }
            }

            // 按钮区
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                FluButton {
                    text: "👍 好图 (Ctrl+H)"
                    onClicked: globalImageManager.markCurrent(true)
                }

                FluButton {
                    text: "👎 坏图 (Ctrl+B)"
                    onClicked: globalImageManager.markCurrent(false)
                }

                FluButton {
                    text: "➡️ 下一张 (→)"
                    onClicked: globalImageManager.next()
                }

                FluButton {
                    text: "⬅️ 上一张 (←)"
                    onClicked: globalImageManager.previous()
                }
            }
        }
    }

    // 快捷键绑定
    Shortcut { sequence: "Right"; onActivated: globalImageManager.next() }
    Shortcut { sequence: "Left"; onActivated: globalImageManager.previous() }
    Shortcut { sequence: "Ctrl+H"; onActivated: globalImageManager.markCurrent(true) }
    Shortcut { sequence: "Ctrl+B"; onActivated: globalImageManager.markCurrent(false) }
}
