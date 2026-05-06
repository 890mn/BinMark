pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import Qt.labs.folderlistmodel

ApplicationWindow {
    id: window

    width: 1280
    height: 760
    minimumWidth: 980
    minimumHeight: 580
    visible: true
    title: "BinMark"
    flags: window.stayOnTop ? (Qt.Window | Qt.WindowStaysOnTopHint) : Qt.Window
    color: window.appBackground

    property bool darkMode: false
    property bool foldersExpanded: true
    property bool statusExpanded: true
    property bool historyExpanded: true
    property bool stayOnTop: false
    property url selectedFolder: ""
    property url previewImageUrl: ""
    property string previewImageName: ""

    readonly property bool hasFolder: String(selectedFolder).length > 0
    readonly property bool hasImages: globalImageManager.totalCount > 0
    readonly property bool hasLastGood: String(globalImageManager.lastGoodImage).length > 0
    readonly property bool hasStatusPreview: String(previewImageUrl).length > 0
    readonly property int reviewTotal: globalImageManager.statusCount + globalImageManager.totalCount
    readonly property real reviewProgress: reviewTotal > 0
                                           ? globalImageManager.statusCount / reviewTotal
                                           : 0

    readonly property color appBackground: darkMode ? "#10151d" : "#eef2f6"
    readonly property color surfaceColor: darkMode ? "#18202b" : "#ffffff"
    readonly property color panelColor: darkMode ? "#111923" : "#f8fafc"
    readonly property color borderColor: darkMode ? "#2a3544" : "#d8e0ea"
    readonly property color hoverColor: darkMode ? "#243142" : "#edf3fb"
    readonly property color primaryText: darkMode ? "#e8edf4" : "#172033"
    readonly property color secondaryText: darkMode ? "#aeb8c7" : "#5d697a"
    readonly property color mutedText: darkMode ? "#7f8b9d" : "#7a8494"
    readonly property color disabledFill: darkMode ? "#202936" : "#edf1f5"
    readonly property color disabledText: darkMode ? "#647083" : "#a0a9b7"
    readonly property color accentBlue: darkMode ? "#6ea8ff" : "#2563eb"
    readonly property color accentGreen: darkMode ? "#4ade80" : "#15803d"
    readonly property color accentRed: darkMode ? "#fb7185" : "#b42318"
    readonly property color warningPink: "#c9778f"
    readonly property int panelRadius: 8
    readonly property int innerMargin: 16

    function displayPath(urlValue) {
        var text = String(urlValue)
        if (text.length === 0)
            return "No folder selected"

        try {
            text = decodeURIComponent(text)
        } catch (error) {
        }

        if (text.indexOf("file:///") === 0)
            return text.substring(8)
        if (text.indexOf("file://") === 0)
            return text.substring(7)
        return text
    }

    function openFolder(folderUrl) {
        if (String(folderUrl).length === 0)
            return

        endStatusPreview()
        selectedFolder = folderUrl
        folderModel.folder = folderUrl
        globalImageManager.loadFromFolder(folderUrl)
    }

    function previewStatus(record) {
        previewImageUrl = record.imageUrl
        previewImageName = record.fileName
    }

    function endStatusPreview() {
        previewImageUrl = ""
        previewImageName = ""
    }

    function openParentFolder() {
        var text = String(selectedFolder)
        if (text.length === 0)
            return

        while (text.endsWith("/"))
            text = text.substring(0, text.length - 1)

        var lastSeparator = text.lastIndexOf("/")
        if (lastSeparator >= "file:///".length)
            openFolder(text.substring(0, lastSeparator))
    }

    function childFolderUrl(fileName) {
        var base = String(selectedFolder)
        if (base.length === 0)
            return ""
        if (!base.endsWith("/"))
            base += "/"
        return base + encodeURIComponent(fileName)
    }

    function themedIcon(name) {
        return "qrc:/assets/" + name + (window.darkMode ? "-light.png" : "-dark.png")
    }

    component Panel: Rectangle {
        color: window.surfaceColor
        radius: window.panelRadius
        border.color: window.borderColor
        border.width: 1
    }

    component SectionLabel: Label {
        color: window.primaryText
        font.pixelSize: 13
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    component MetaLabel: Label {
        color: window.secondaryText
        font.pixelSize: 12
        elide: Text.ElideRight
    }

    component ActionButton: Button {
        id: control

        property bool filled: false
        property color accentColor: window.accentBlue

        implicitHeight: 44
        font.pixelSize: 14
        font.weight: Font.DemiBold

        contentItem: Label {
            text: control.text
            color: !control.enabled
                   ? window.disabledText
                   : control.filled ? (window.darkMode ? "#0d1117" : "#ffffff") : control.accentColor
            font: control.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        background: Rectangle {
            radius: 7
            border.width: 1
            border.color: !control.enabled
                          ? window.borderColor
                          : control.filled ? control.accentColor : window.borderColor
            color: {
                if (!control.enabled)
                    return window.disabledFill
                if (control.filled)
                    return control.down ? Qt.darker(control.accentColor, 1.12) : control.accentColor
                return control.hovered || control.down ? window.hoverColor : window.surfaceColor
            }
        }
    }

    component IconButton: ToolButton {
        id: control

        property url iconSource: ""

        implicitWidth: 34
        implicitHeight: 34

        contentItem: Image {
            source: control.iconSource
            sourceSize.width: 20
            sourceSize.height: 20
            fillMode: Image.PreserveAspectFit
            opacity: control.enabled ? 1 : 0.38
        }

        background: Rectangle {
            radius: 7
            color: control.checked ? window.hoverColor
                                    : control.hovered || control.down ? window.hoverColor : "transparent"
            border.color: control.checked || control.hovered || control.down ? window.borderColor : "transparent"
        }
    }

    component ThemeSwitch: Switch {
        id: control

        implicitWidth: 86
        implicitHeight: 34
        text: checked ? "Dark" : "Light"

        indicator: Rectangle {
            x: control.leftPadding
            y: (control.height - height) / 2
            width: 42
            height: 24
            radius: 12
            color: control.checked ? window.accentBlue : window.panelColor
            border.color: control.checked ? window.accentBlue : window.borderColor

            Rectangle {
                x: control.checked ? parent.width - width - 3 : 3
                y: 3
                width: 18
                height: 18
                radius: 9
                color: control.checked ? "#0d1117" : window.surfaceColor

                Behavior on x {
                    NumberAnimation { duration: 120 }
                }
            }
        }

        contentItem: Label {
            text: control.text
            color: window.secondaryText
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
            leftPadding: 50
        }
    }

    component ReviewProgressBar: ProgressBar {
        id: progress

        implicitHeight: 12
        padding: 0

        background: Rectangle {
            implicitHeight: 12
            radius: 6
            color: window.darkMode ? "#263242" : "#e4eaf2"
        }

        contentItem: Item {
            implicitHeight: 12
            clip: true

            Rectangle {
                width: Math.max(0, parent.width * progress.visualPosition)
                height: parent.height
                radius: 6
                color: window.accentBlue
            }
        }
    }

    component ImagePanel: Panel {
        id: imagePanel

        property string heading: ""
        property string detail: ""
        property string emptyText: ""
        property url imageSource: ""
        property bool imageVisible: false
        property bool zoomable: false
        property bool returnVisible: false
        property real zoomScale: 1.0

        signal returnRequested()

        function resetZoom() {
            zoomScale = 1.0
            imageFlick.contentX = 0
            imageFlick.contentY = 0
        }

        onImageSourceChanged: resetZoom()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: window.innerMargin
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SectionLabel {
                    text: imagePanel.heading
                    font.pixelSize: 14
                    Layout.fillWidth: true
                }

                ActionButton {
                    text: "Return"
                    visible: imagePanel.returnVisible
                    Layout.preferredWidth: 76
                    implicitHeight: 30
                    onClicked: imagePanel.returnRequested()
                }

                MetaLabel {
                    text: imagePanel.zoomable && imagePanel.imageVisible
                          ? Math.round(imagePanel.zoomScale * 100) + "%"
                          : imagePanel.detail
                    horizontalAlignment: Text.AlignRight
                    visible: text.length > 0
                    Layout.maximumWidth: 180
                }

                ActionButton {
                    text: "Reset"
                    visible: imagePanel.zoomable && imagePanel.zoomScale > 1.01
                    Layout.preferredWidth: 68
                    implicitHeight: 30
                    onClicked: imagePanel.resetZoom()
                }
            }

            Rectangle {
                id: imageViewport
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 6
                color: window.panelColor
                border.color: window.borderColor
                clip: true

                Flickable {
                    id: imageFlick
                    anchors.fill: parent
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    contentWidth: Math.max(width, width * imagePanel.zoomScale)
                    contentHeight: Math.max(height, height * imagePanel.zoomScale)
                    interactive: imagePanel.zoomable && imagePanel.zoomScale > 1.01

                    Image {
                        width: imageFlick.contentWidth
                        height: imageFlick.contentHeight
                        fillMode: Image.PreserveAspectFit
                        source: imagePanel.imageSource
                        asynchronous: true
                        cache: false
                        visible: imagePanel.imageVisible
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    enabled: imagePanel.zoomable && imagePanel.imageVisible

                    onWheel: function(wheel) {
                        var oldScale = imagePanel.zoomScale
                        var direction = wheel.angleDelta.y > 0 ? 1 : -1
                        var factor = direction > 0 ? 1.14 : 0.88
                        var nextScale = Math.max(1.0, Math.min(5.0, oldScale * factor))
                        if (Math.abs(nextScale - oldScale) < 0.001)
                            return

                        var focusX = imageFlick.contentX + wheel.x
                        var focusY = imageFlick.contentY + wheel.y
                        var ratio = nextScale / oldScale
                        imagePanel.zoomScale = nextScale
                        imageFlick.contentX = Math.max(0, Math.min(imageFlick.contentWidth - imageFlick.width, focusX * ratio - wheel.x))
                        imageFlick.contentY = Math.max(0, Math.min(imageFlick.contentHeight - imageFlick.height, focusY * ratio - wheel.y))
                        wheel.accepted = true
                    }
                }

                Label {
                    anchors.centerIn: parent
                    width: parent.width - 56
                    text: imagePanel.emptyText
                    color: window.mutedText
                    font.pixelSize: 13
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    visible: !imagePanel.imageVisible
                }
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Choose image folder"
        currentFolder: window.selectedFolder
        onAccepted: window.openFolder(folderDialog.selectedFolder)
    }

    FolderListModel {
        id: folderModel
        folder: window.selectedFolder
        showDirs: true
        showFiles: false
    }

    Popup {
        id: archivePopup

        width: 430
        height: Math.min(window.height - 92, 540)
        x: Math.max(16, window.width - width - 176)
        y: 72
        padding: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Panel {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: window.innerMargin
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                SectionLabel {
                    text: "Archive"
                    font.pixelSize: 15
                    Layout.fillWidth: true
                }

                ActionButton {
                    text: "Add Current"
                    enabled: window.hasFolder
                    implicitHeight: 34
                    Layout.preferredWidth: 116
                    onClicked: globalImageManager.addPinnedFolder(window.selectedFolder)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 210
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    IconButton {
                        iconSource: window.themedIcon("pin")
                        implicitWidth: 24
                        implicitHeight: 24
                    }

                    SectionLabel {
                        text: "Pinned"
                        Layout.fillWidth: true
                    }

                    MetaLabel {
                        text: globalImageManager.pinnedFolders.length + ""
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 6
                    color: window.panelColor
                    border.color: window.borderColor
                    clip: true

                    Label {
                        anchors.centerIn: parent
                        text: "No pinned folders"
                        color: window.mutedText
                        font.pixelSize: 12
                        visible: pinnedArchiveList.count === 0
                    }

                    ListView {
                        id: pinnedArchiveList
                        anchors.fill: parent
                        anchors.margins: 6
                        clip: true
                        spacing: 5
                        model: globalImageManager.pinnedFolders

                        delegate: ItemDelegate {
                            id: pinnedArchiveDelegate
                            required property var modelData

                            width: pinnedArchiveList.width - 12
                            height: 42
                            enabled: modelData.exists
                            onClicked: {
                                archivePopup.close()
                                window.openFolder(modelData.url)
                            }

                            contentItem: RowLayout {
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Label {
                                        text: pinnedArchiveDelegate.modelData.name
                                        color: pinnedArchiveDelegate.enabled ? window.primaryText : window.disabledText
                                        font.pixelSize: 12
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }

                                    MetaLabel {
                                        text: pinnedArchiveDelegate.modelData.path
                                        color: pinnedArchiveDelegate.enabled ? window.secondaryText : window.disabledText
                                        Layout.fillWidth: true
                                    }
                                }

                                IconButton {
                                    iconSource: window.themedIcon("pin")
                                    onClicked: globalImageManager.removePinnedFolder(pinnedArchiveDelegate.modelData.path)
                                }
                            }

                            background: Rectangle {
                                radius: 5
                                color: pinnedArchiveDelegate.hovered ? window.hoverColor : "transparent"
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AlwaysOff
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    SectionLabel {
                        text: "Recent"
                        Layout.fillWidth: true
                    }

                    MetaLabel {
                        text: globalImageManager.recentFolders.length + ""
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 6
                    color: window.panelColor
                    border.color: window.borderColor
                    clip: true

                    Label {
                        anchors.centerIn: parent
                        text: "No recent folders"
                        color: window.mutedText
                        font.pixelSize: 12
                        visible: recentArchiveList.count === 0
                    }

                    ListView {
                        id: recentArchiveList
                        anchors.fill: parent
                        anchors.margins: 6
                        clip: true
                        spacing: 5
                        model: globalImageManager.recentFolders

                        delegate: ItemDelegate {
                            id: recentArchiveDelegate
                            required property var modelData

                            width: recentArchiveList.width - 12
                            height: 42
                            enabled: modelData.exists
                            onClicked: {
                                archivePopup.close()
                                window.openFolder(modelData.url)
                            }

                            contentItem: RowLayout {
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Label {
                                        text: recentArchiveDelegate.modelData.name
                                        color: recentArchiveDelegate.enabled ? window.primaryText : window.disabledText
                                        font.pixelSize: 12
                                        elide: Text.ElideMiddle
                                        Layout.fillWidth: true
                                    }

                                    MetaLabel {
                                        text: recentArchiveDelegate.modelData.path
                                        color: recentArchiveDelegate.enabled ? window.secondaryText : window.disabledText
                                        Layout.fillWidth: true
                                    }
                                }

                                IconButton {
                                    iconSource: window.themedIcon("pin")
                                    enabled: recentArchiveDelegate.enabled
                                    onClicked: globalImageManager.addPinnedFolder(recentArchiveDelegate.modelData.url)
                                }
                            }

                            background: Rectangle {
                                radius: 5
                                color: recentArchiveDelegate.hovered ? window.hoverColor : "transparent"
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AlwaysOff
                        }
                    }
                }
            }
        }
    }

    header: ToolBar {
        height: 64
        leftPadding: 0
        rightPadding: 0

        background: Rectangle {
            color: window.surfaceColor
            border.color: window.borderColor
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 14

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true

                Label {
                    text: "BinMark"
                    color: window.primaryText
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                MetaLabel {
                    text: window.displayPath(window.selectedFolder)
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                implicitWidth: 116
                implicitHeight: 34
                radius: 17
                color: window.panelColor
                border.color: window.borderColor

                Label {
                    anchors.centerIn: parent
                    text: window.hasImages
                          ? (globalImageManager.currentIndex + 1) + " / " + globalImageManager.totalCount
                          : "No images"
                    color: window.primaryText
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: parent.width - 20
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            ThemeSwitch {
                checked: window.darkMode
                onToggled: window.darkMode = checked
            }

            IconButton {
                iconSource: window.themedIcon("pin")
                checkable: true
                checked: window.stayOnTop
                onClicked: window.stayOnTop = !window.stayOnTop
            }

            IconButton {
                iconSource: window.themedIcon("archive")
                onClicked: archivePopup.open()
            }

            ActionButton {
                text: "Choose Folder"
                Layout.preferredWidth: 132
                onClicked: folderDialog.open()
            }

            ActionButton {
                text: "Parent"
                enabled: window.hasFolder
                Layout.preferredWidth: 92
                onClicked: window.openParentFolder()
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            ImagePanel {
                heading: window.hasStatusPreview ? window.previewImageName : "Current Image"
                detail: window.hasStatusPreview ? "Status preview"
                        : window.hasImages
                        ? (globalImageManager.currentIndex + 1) + " of " + globalImageManager.totalCount
                        : ""
                emptyText: window.hasFolder ? "No supported images in this folder" : "Choose a folder to begin"
                imageSource: window.hasStatusPreview ? window.previewImageUrl : globalImageManager.currentImage
                imageVisible: window.hasStatusPreview || window.hasImages
                zoomable: true
                returnVisible: window.hasStatusPreview
                onReturnRequested: window.endStatusPreview()
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 460
            }

            ScrollView {
                id: rightScroll

                Layout.preferredWidth: 360
                Layout.minimumWidth: 320
                Layout.maximumWidth: 420
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: rightScroll.availableWidth
                    spacing: 16

                Panel {
                    id: foldersPanel
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.foldersExpanded ? 240 : 62
                    Layout.maximumHeight: window.foldersExpanded ? 240 : 62
                    Layout.minimumHeight: 62

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.innerMargin
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            IconButton {
                                iconSource: window.themedIcon(window.foldersExpanded ? "up" : "down")
                                implicitWidth: 28
                                implicitHeight: 28
                                onClicked: window.foldersExpanded = !window.foldersExpanded
                            }

                            SectionLabel {
                                text: "Subfolders"
                                Layout.fillWidth: true
                            }

                            MetaLabel {
                                text: folderList.count + ""
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: window.borderColor
                            visible: window.foldersExpanded
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: window.foldersExpanded

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 10

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 6
                                    color: window.panelColor
                                    border.color: window.borderColor
                                    clip: true

                                    Label {
                                        anchors.centerIn: parent
                                        width: parent.width - 32
                                        text: window.hasFolder ? "No subfolders" : "Choose a folder to browse"
                                        color: window.mutedText
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.Wrap
                                        visible: folderList.count === 0
                                    }

                                    ListView {
                                        id: folderList
                                        anchors.fill: parent
                                        anchors.margins: 6
                                        clip: true
                                        model: folderModel
                                        spacing: 3

                                        delegate: ItemDelegate {
                                            id: folderDelegate
                                            required property string fileName

                                            width: folderList.width - 12
                                            height: 38

                                            contentItem: Label {
                                                text: folderDelegate.fileName
                                                color: window.primaryText
                                                font.pixelSize: 12
                                                elide: Text.ElideMiddle
                                                verticalAlignment: Text.AlignVCenter
                                            }

                                            background: Rectangle {
                                                radius: 5
                                                color: folderDelegate.hovered ? window.hoverColor : "transparent"
                                            }

                                            onClicked: window.openFolder(window.childFolderUrl(folderDelegate.fileName))
                                        }

                                        ScrollBar.vertical: ScrollBar {
                                            policy: ScrollBar.AlwaysOff
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Panel {
                    id: statusPanel
                    Layout.fillWidth: true
                    Layout.preferredHeight: window.statusExpanded ? 360 : 62
                    Layout.maximumHeight: window.statusExpanded ? 360 : 62
                    Layout.minimumHeight: 62

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.innerMargin
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            IconButton {
                                iconSource: window.themedIcon(window.statusExpanded ? "up" : "down")
                                implicitWidth: 28
                                implicitHeight: 28
                                onClicked: window.statusExpanded = !window.statusExpanded
                            }

                            SectionLabel {
                                text: "Status"
                                Layout.fillWidth: true
                            }

                            MetaLabel {
                                text: "A " + globalImageManager.acceptedCount + " / R " + globalImageManager.rejectedCount
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: window.borderColor
                            visible: window.statusExpanded
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: window.statusExpanded

                            Label {
                                anchors.centerIn: parent
                                width: parent.width - 32
                                text: window.hasFolder ? "No marked images in this folder" : "Choose a folder to begin"
                                color: window.mutedText
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                visible: globalImageManager.statusCount === 0
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 8
                                visible: globalImageManager.statusCount > 0

                                ListView {
                                    id: statusList
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    model: globalImageManager.statusRecords
                                    spacing: 6

                                    delegate: Rectangle {
                                        id: statusDelegate
                                        required property var modelData

                                        width: statusList.width
                                        height: 46
                                        radius: 6
                                        color: window.panelColor
                                        border.color: window.borderColor

                                        TapHandler {
                                            onTapped: window.previewStatus(statusDelegate.modelData)
                                        }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8

                                            AbstractButton {
                                                id: statusToggle

                                                Layout.preferredWidth: 30
                                                Layout.preferredHeight: 24
                                                onClicked: globalImageManager.toggleStatusRecord(statusDelegate.modelData.index)

                                                contentItem: Label {
                                                    text: statusDelegate.modelData.status.toUpperCase()
                                                    color: window.darkMode ? "#0d1117" : "#ffffff"
                                                    font.pixelSize: 12
                                                    font.weight: Font.DemiBold
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                background: Rectangle {
                                                    radius: 5
                                                    color: statusDelegate.modelData.isGood ? window.accentGreen : window.accentRed
                                                    opacity: statusToggle.down ? 0.76 : 1
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Label {
                                                    text: statusDelegate.modelData.fileName
                                                    color: window.primaryText
                                                    font.pixelSize: 12
                                                    elide: Text.ElideMiddle
                                                    Layout.fillWidth: true
                                                }

                                                MetaLabel {
                                                    text: statusDelegate.modelData.label
                                                    color: statusDelegate.modelData.isGood ? window.accentGreen : window.accentRed
                                                    Layout.fillWidth: true
                                                }
                                            }
                                        }
                                    }

                                    ScrollBar.vertical: ScrollBar {
                                        policy: ScrollBar.AlwaysOff
                                    }
                                }

                                ActionButton {
                                    text: "Load More"
                                    visible: globalImageManager.canLoadMoreStatus
                                    Layout.fillWidth: true
                                    implicitHeight: 34
                                    onClicked: globalImageManager.loadMoreStatus()
                                }
                            }
                        }
                    }
                }

                Panel {
                    id: historyPanel
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: window.historyExpanded ? 300 : 62
                    Layout.maximumHeight: window.historyExpanded ? 320 : 62
                    Layout.minimumHeight: 62

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: window.innerMargin
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            IconButton {
                                iconSource: window.themedIcon(window.historyExpanded ? "up" : "down")
                                implicitWidth: 28
                                implicitHeight: 28
                                onClicked: window.historyExpanded = !window.historyExpanded
                            }

                            SectionLabel {
                                text: "Last Accepted"
                                Layout.fillWidth: true
                            }

                            MetaLabel {
                                text: globalImageManager.historyCount + ""
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: window.borderColor
                            visible: window.historyExpanded
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: window.historyExpanded

                            Label {
                                anchors.centerIn: parent
                                width: parent.width - 32
                                text: "No reviewed images"
                                color: window.mutedText
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                visible: globalImageManager.historyCount === 0
                            }

                            ListView {
                                id: historyList
                                anchors.fill: parent
                                clip: true
                                model: globalImageManager.history
                                spacing: 6
                                visible: globalImageManager.historyCount > 0

                                delegate: Rectangle {
                                    id: historyDelegate
                                    required property var modelData

                                    width: historyList.width
                                    height: 46
                                    radius: 6
                                    color: window.panelColor
                                    border.color: window.borderColor

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 6
                                        spacing: 8

                                        Rectangle {
                                            Layout.preferredWidth: 8
                                            Layout.preferredHeight: 28
                                            radius: 4
                                            color: historyDelegate.modelData.isGood ? window.accentGreen : window.accentRed
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Label {
                                                text: historyDelegate.modelData.fileName
                                                color: window.primaryText
                                                font.pixelSize: 12
                                                elide: Text.ElideMiddle
                                                Layout.fillWidth: true
                                            }

                                            MetaLabel {
                                                text: historyDelegate.modelData.label
                                                color: historyDelegate.modelData.isGood ? window.accentGreen : window.accentRed
                                                Layout.fillWidth: true
                                            }
                                        }

                                        IconButton {
                                            iconSource: window.themedIcon("undo")
                                            onClicked: globalImageManager.undoHistoryItem(historyDelegate.modelData.index)
                                        }
                                    }
                                }

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AlwaysOff
                                }
                            }
                        }
                    }
                }
                }
            }
        }

        Panel {
            Layout.fillWidth: true
            Layout.preferredHeight: 86

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                ActionButton {
                    text: "Accept"
                    filled: true
                    accentColor: window.accentGreen
                    enabled: window.hasImages
                    Layout.preferredWidth: 150
                    onClicked: globalImageManager.markCurrent(true)
                }

                ActionButton {
                    text: "Reject"
                    filled: true
                    accentColor: window.accentRed
                    enabled: window.hasImages
                    Layout.preferredWidth: 150
                    onClicked: globalImageManager.markCurrent(false)
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: window.borderColor
                }

                ActionButton {
                    text: "Previous"
                    enabled: window.hasImages && globalImageManager.currentIndex > 0
                    Layout.preferredWidth: 150
                    onClicked: globalImageManager.previous()
                }

                ActionButton {
                    text: "Next"
                    filled: true
                    accentColor: window.accentBlue
                    enabled: window.hasImages
                    Layout.preferredWidth: 132
                    onClicked: globalImageManager.next()
                }

                Item {
                    Layout.fillWidth: true
                }

                ReviewProgressBar {
                    Layout.preferredWidth: 190
                    Layout.minimumWidth: 120
                    from: 0
                    to: 1
                    value: window.reviewProgress
                    visible: window.reviewTotal > 0
                }

                MetaLabel {
                    text: window.reviewTotal > 0
                          ? Math.round(window.reviewProgress * 100) + "%  A "
                            + globalImageManager.acceptedCount + " / R "
                            + globalImageManager.rejectedCount + " / Left "
                            + globalImageManager.totalCount
                          : ""
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 220
                }
            }
        }
    }

    Shortcut {
        sequence: "q"
        context: Qt.ApplicationShortcut
        enabled: window.hasImages
        onActivated: globalImageManager.markCurrent(true)
    }

    Shortcut {
        sequence: "w"
        context: Qt.ApplicationShortcut
        enabled: window.hasImages
        onActivated: globalImageManager.markCurrent(false)
    }

    Shortcut {
        sequence: "Space"
        enabled: window.hasImages && globalImageManager.currentIndex > 0
        onActivated: globalImageManager.previous()
    }

    Shortcut {
        sequence: "D"
        enabled: window.hasImages
        onActivated: globalImageManager.next()
    }

    Shortcut {
        sequence: StandardKey.Undo
        enabled: globalImageManager.historyCount > 0
        onActivated: globalImageManager.undoHistoryItem(0)
    }
}
