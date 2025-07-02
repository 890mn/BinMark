import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls
import QtQuick.Layouts
import FluentUI 1.0

FluWindow {
    width: 640
    height: 480
    minimumWidth: 320
    minimumHeight: 240
    title: qsTr("BinMark")

    RowLayout {
        anchors.fill: parent

        // 左边文件树
        FileTree {
            width: 300
        }

        // 图片展示
        Image {
            fillMode: Image.PreserveAspectFit
            source: imageManager.currentImage
            onStatusChanged: {
                if (status === Image.Error)
                    console.log("图片加载失败:", source)
            }
        }

        // 按钮区域
        ColumnLayout {
            spacing: 10
            FluButton {
                text: "好图"
                onClicked: imageManager.markCurrent(true)
            }
            FluButton {
               text: "坏图"
                onClicked: imageManager.markCurrent(false)
            }
        }
    }

    Shortcut {
        sequence: "Right"
        onActivated: imageManager.next()
    }
    Shortcut {
        sequence: "Left"
        onActivated: imageManager.previous()
    }
    Shortcut {
        sequence: "Ctrl+H"
        onActivated: imageManager.markCurrent(true)
    }
    Shortcut {
        sequence: "Ctrl+B"
        onActivated: imageManager.markCurrent(false)
    }
}
