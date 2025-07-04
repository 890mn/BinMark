import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import QtQuick.Dialogs
import Qt.labs.platform as Platform

Item {
    id: root
    width: 300
    height: parent.height

    property url selectedFolder: ""

    Platform.FileDialog {
        id: folderPicker
        title: "选择图片所在文件夹"
        folder: selectedFolder
        //selectFolder: true   // ✅ 支持！
        onAccepted: {
            console.log("✅ 选中了文件夹:", folderPicker.folder)
            imageManager.loadFromFolder(folderPicker.folder)
        }
    }

    FolderListModel {
        id: folderModel
        folder: selectedFolder
        showDirs: true
        showFiles: false
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Button {
            text: "📁 选择父文件夹"
            onClicked: folderPicker.open()
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
                    console.log("加载子目录:", filePath)
                    imageManager.loadFromFolder(filePath)
                }
            }
        }
    }
}
