import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import QtQuick.Dialogs

Item {
    id: root
    width: 300
    height: parent.height

    property url selectedFolder: "D://"

    FileDialog {
        id: folderPicker
        title: "选择父文件夹"
        //selectFolder: true
        //folder: shortcuts.home
        onAccepted: {
            selectedFolder = folderPicker.folder
            folderModel.folder = selectedFolder
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
