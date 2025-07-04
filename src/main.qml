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
            Layout.preferredWidth: 140
            Layout.minimumWidth: 160
            Layout.maximumWidth: 300
            Layout.fillHeight: true
            spacing: 8

            Text {
                text: globalImageManager.totalCount > 0
                      ? `${globalImageManager.currentIndex + 1} / ${globalImageManager.totalCount}`
                      : "未加载图片"
                font.pixelSize: 14
                horizontalAlignment: Text.AlignHCenter
                Layout.alignment: Qt.AlignHCenter
            }

            Platform.FileDialog {
                id: folderPicker
                title: "选择图片所在文件夹"
                onAccepted: {
                    selectedFolder = folderPicker.folder
                    folderModel.folder = folderPicker.folder
                    globalImageManager.loadFromFolder(folderPicker.folder)
                }
            }

            RowLayout {
                Button {
                    text: "📁 选择父文件夹"
                    onClicked: folderPicker.open()
                }

                Button {
                    text: "⬆️ 返回上一级"
                    onClicked: {
                        var parts = selectedFolder.toString().split("/")
                        parts.pop()  // 去掉当前目录
                        var parentPath = parts.join("/")
                        if (parentPath.startsWith("file:///") === false)
                            parentPath = "file:///" + parentPath
                        selectedFolder = parentPath
                        folderModel.folder = parentPath
                        globalImageManager.loadFromFolder(parentPath)
                    }
                }
            }

            Text {
                text: selectedFolder == ""
                    ? "Path will be shown here"
                    : selectedFolder.toString().replace("file:///", "").replace("file://", "")
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
                    width: ListView.view.width   // 限制宽度，防止撑出列表
                    text: fileName
                    font.pixelSize: 12

                    contentItem: Text {
                        text: fileName
                        wrapMode: Text.Wrap
                        elide: Text.ElideMiddle
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 8
                    }

                    onClicked: {
                        const path = selectedFolder + "/" + fileName
                        console.log("点击进入子目录:", path)
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
                    color: "transparent"

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5
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
                    border.color: "#cccccc"
                    radius: 5
                    color: "transparent"

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
                    text: "👍 我看行 (Q)"
                    onClicked: globalImageManager.markCurrent(true)
                }

                FluButton {
                    text: "👎 不太行 (W)"
                    onClicked: globalImageManager.markCurrent(false)
                }

                FluButton {
                    text: "⬅️ 上一张 (Space)"
                    onClicked: globalImageManager.previous()
                }

                FluButton {
                    text: "➡️ 下一张 (D)"
                    onClicked: globalImageManager.next()
                }
            }
        }
    }

    // 快捷键绑定
    Shortcut { sequence: "Space"; onActivated: globalImageManager.next() }
    Shortcut { sequence: "D"; onActivated: globalImageManager.previous() }
    Shortcut { sequence: "Q"; onActivated: globalImageManager.markCurrent(true) }
    Shortcut { sequence: "W"; onActivated: globalImageManager.markCurrent(false) }
}
