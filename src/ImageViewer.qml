import QtQuick
import QtQuick.Controls

Item {
    anchors.fill: parent

    Image {
        anchors.fill: parent
        source: imageManager.currentImage
        fillMode: Image.PreserveAspectFit
        cache: false

        onStatusChanged: {
            if (status === Image.Error) {
                console.warn("图片加载失败: ", source)
            }
        }
    }
}
