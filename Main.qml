import QtQuick 2.15
import QtQuick.Controls 2.15 as Controls
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import Qt5Compat.GraphicalEffects 1.0

import SddmComponents 2.0

Rectangle {
    id: root
    width: Screen.width || 1920
    height: Screen.height || 1080

    // -------------------------------------------------------------------------
    // Responsive Scaling
    // -------------------------------------------------------------------------
    readonly property real scaleFactor: Math.max(0.9, Math.min(width / 1920, height / 1080))
    readonly property real baseUnit: 8 * scaleFactor

    // -------------------------------------------------------------------------
    // Theme Constants (Rose Pine) & Style Tokens
    // -------------------------------------------------------------------------
    readonly property color mPrimary: config.mPrimary || "#c7a1d8"
    readonly property color mOnPrimary: config.mOnPrimary || "#1a151f"
    readonly property color mSurface: config.mSurface || "#1c1822"
    readonly property color mSurfaceVariant: config.mSurfaceVariant || "#262130"
    readonly property color mOnSurface: config.mOnSurface || "#e9e4f0"
    readonly property color mOnSurfaceVariant: config.mOnSurfaceVariant || "#a79ab0"
    readonly property color mError: config.mError || "#e9899d"
    readonly property color mOutline: config.mOutline || "#342c42"

    // Responsive sizes
    readonly property real configRadiusL: config.radius || 20
    readonly property real fontSizeM: 12 * scaleFactor
    readonly property real fontSizeL: 14 * scaleFactor
    readonly property real fontSizeXL: 20 * scaleFactor
    readonly property real fontSizeXXL: 26 * scaleFactor
    readonly property real fontSizeClock: 42 * scaleFactor

    // Configurable Background
    readonly property string backgroundPath: config.background || "Assets/background.png"

    // Fonts
    property font fontMain: Qt.font({
        family: "JetBrainsMono NF",
        pixelSize: 14 * scaleFactor
    })

    LayoutMirroring.enabled: Qt.locale().textDirection == Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    readonly property real blurRadius: config.blurRadius || 0

    // -------------------------------------------------------------------------
    // Background
    // -------------------------------------------------------------------------
    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.backgroundPath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        clip: true
        visible: root.blurRadius <= 0 // Hide if blurred version is shown
    }

    FastBlur {
        anchors.fill: parent
        source: wallpaper
        radius: root.blurRadius
        transparentBorder: false
        visible: root.blurRadius > 0
        cached: true
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(0, 0, 0, 0.4)
            } // Darker top
            GradientStop {
                position: 0.4
                color: Qt.rgba(0, 0, 0, 0.1)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(0, 0, 0, 0.5)
            } // Darker bottom
        }
    }

    // -------------------------------------------------------------------------
    // Top Card: User Info & Time
    // -------------------------------------------------------------------------
    Rectangle {
        id: headerCard
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.11
        anchors.horizontalCenter: parent.horizontalCenter

        width: Math.max(600 * scaleFactor, Math.min(parent.width * 0.70, 550 * scaleFactor))
        height: 130 * scaleFactor
        radius: root.configRadiusL
        color: root.mSurface
        border.color: Qt.rgba(root.mOutline.r, root.mOutline.g, root.mOutline.b, 0.2)
        border.width: 1 * scaleFactor

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.margins: 16 * scaleFactor
            spacing: 30 * scaleFactor

            // Avatar - Perfect Circle
            Item {
                id: avatarRect
                Layout.preferredWidth: 70 * scaleFactor
                Layout.preferredHeight: 70 * scaleFactor
                Layout.alignment: Qt.AlignVCenter

                width: 70 * scaleFactor
                height: 70 * scaleFactor

                property int tryIndex: 0

                property string primaryUser: userModel.lastUser
                property string currentIcon: ""
                property string currentHome: ""
                property string currentRealName: ""
                property string firstUserName: ""

                // Data Extractor
                Repeater {
                    model: userModel
                    delegate: Item {
                        visible: false

                        // Capture first user name as fallback
                        Binding {
                            target: avatarRect
                            property: "firstUserName"
                            value: model.name
                            when: index === 0
                        }

                        // Capture details if this matches primaryUser
                        Binding {
                            target: avatarRect // The Avatar Rectangle
                            property: "currentIcon"
                            value: model.icon
                            when: model.name === avatarRect.displayUser
                        }
                        Binding {
                            target: avatarRect // The Avatar Rectangle
                            property: "currentHome"
                            value: model.homeDir
                            when: model.name === avatarRect.displayUser
                        }
                        Binding {
                            target: avatarRect // The Avatar Rectangle
                            property: "currentRealName"
                            value: model.realName
                            when: model.name === avatarRect.displayUser
                        }
                    }
                }

                // Computed property for whom we are showing
                property string displayUser: primaryUser !== "" ? primaryUser : firstUserName
                property string displayName: currentRealName !== "" ? currentRealName : (displayUser !== "" ? displayUser : "User")

                // Reset try index when user changes
                onDisplayUserChanged: {
                    tryIndex = 0;
                }

                // Get list of icon paths to try
                property var iconPaths: {
                    var paths = [];
                    var u = displayUser;

                    if (u) {
                        // 1. Try path from userModel (if any)
                        // if (currentIcon && currentIcon !== "") {
                        //     var p = currentIcon
                        //     if (p.indexOf("://") === -1 && p.charAt(0) === '/')
                        //         p = "file://" + p
                        //     paths.push(p)
                        // }

                        // 2. Try home directory faces
                        if (currentHome) {
                            paths.push("file://" + currentHome + "/.face.icon");
                            paths.push("file://" + currentHome + "/.face");
                        }

                        // 3. System paths
                        paths.push("file:///usr/share/sddm/faces/" + u + ".face.icon");
                        paths.push("file:///var/lib/AccountsService/icons/" + u);
                    }

                    // 4. return empty
                    paths.push("");

                    return paths;
                }

                // Circular mask for perfect circle
                Rectangle {
                    id: avatarMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                // User avatar image (circular)
                Image {
                    id: userAvatar
                    anchors.fill: parent
                    anchors.margins: 4 * scaleFactor
                    source: {
                        if (parent.iconPaths.length === 0)
                            return "";
                        var idx = Math.min(parent.tryIndex, parent.iconPaths.length - 1);
                        return parent.iconPaths[idx];
                    }
                    sourceSize: Qt.size(70 * scaleFactor, 70 * scaleFactor)
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                    visible: status === Image.Ready
                    asynchronous: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: avatarMask
                    }

                    // Try next path if current one fails
                    onStatusChanged: {
                        if (status === Image.Error && parent.tryIndex < parent.iconPaths.length - 1) {
                            parent.tryIndex++;
                        }
                    }
                }

                // Fallback logo if user avatar not available
                Image {
                    id: fallbackLogo
                    anchors.fill: parent
                    anchors.margins: 20 * scaleFactor
                    source: "Assets/user.svg"
                    sourceSize: Qt.size(70 * scaleFactor, 70 * scaleFactor)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: userAvatar.status !== Image.Ready && userAvatar.status !== Image.Loading
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: avatarMask
                    }
                }

                // Circular border
                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.color: root.mPrimary
                    border.width: 2.5 * scaleFactor
                }
            }

            // Text Info
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 1 * scaleFactor

                Text {
                    text: "Welcome back, " + avatarRect.displayName + "!"
                    font.pixelSize: root.fontSizeXXL
                    font.bold: false
                    color: root.mOnSurface
                }

                Text {
                    text: Qt.formatDate(new Date(), "dddd, MMMM d")
                    font.pixelSize: root.fontSizeXL
                    Layout.topMargin: -10 * scaleFactor
                    color: root.mOnSurfaceVariant
                }
            }

            Item {
                Layout.fillWidth: true
            } // Spacer


            // Clock
            Text {
                text: Qt.formatTime(new Date(), "hh:mm")
                font.pixelSize: root.fontSizeClock
                font.bold: true
                color: root.mOnSurface
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    // -------------------------------------------------------------------------
    // Bottom Card: Password & Controls
    // -------------------------------------------------------------------------

    Rectangle {
        id: bottomCard
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter

        width: Math.min(750 * scaleFactor, parent.width * 0.9)
        height: 145 * scaleFactor
        radius: root.configRadiusL
        color: root.mSurface
        border.color: Qt.rgba(root.mOutline.r, root.mOutline.g, root.mOutline.b, 0.2)
        border.width: 1 * scaleFactor

    Rectangle {
            id: topPill
            height: 35 * scaleFactor
            width: keyboard.layout > 1 ? 220 * scaleFactor : 200 * scaleFactor
            // radius: height / 2
            topLeftRadius: height / 2
            topRightRadius: height / 2
            bottomLeftRadius: 0
            bottomRightRadius: 0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: -height * 0.92
            color: root.mSurface
            border.color: Qt.rgba(root.mOutline.r, root.mOutline.g, root.mOutline.b, 0.2)
            border.width: 1 * scaleFactor

            // visible: keyboard.layouts.count > 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6 * scaleFactor

                Image {
                    source: "Assets/keyboard.svg"
                    Layout.preferredWidth: 16 * scaleFactor
                    Layout.preferredHeight: 16 * scaleFactor
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    Layout.alignment: Qt.AlignVCenter
                    visible: keyboard.layouts.count > 1
                }

                Text {
                    MouseArea {
                        id: kbdMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (keyboard.layouts.count > 1) {
                                keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.count;
                            }
                        }
                    }
                    text: keyboard.layouts.count > 0
                        ? keyboard.layouts.get(keyboard.currentLayout).shortName
                        : ""
                    color: root.mOnSurface
                    font.pixelSize: root.fontSizeL
                    Layout.alignment: Qt.AlignVCenter
                    visible: keyboard.layouts.count > 1
                }
                // spacer
                Item {
                    Layout.fillWidth: true
                }
                Image {
                    source: "Assets/lock.svg"
                    Layout.preferredWidth: 16 * scaleFactor
                    Layout.preferredHeight: 16 * scaleFactor
                    fillMode: Image.PreserveAspectFit
                    visible: keyboard.capsLock ? false : true
                    smooth: true
                    Layout.alignment: Qt.AlignVCenter
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: Qt.rgba(0, 0, 0, 0.5) // Semi-transparent black overlay
                    }
                }
                Image {
                    source: "Assets/lock-filled.svg"
                    Layout.preferredWidth: 16 * scaleFactor
                    Layout.preferredHeight: 16 * scaleFactor
                    fillMode: Image.PreserveAspectFit
                    visible: keyboard.capsLock ? true : false
                    smooth: true
                    Layout.alignment: Qt.AlignVCenter
                }
                Text {
                    text: "CAPS"
                    color: keyboard.capsLock ? root.mPrimary : Qt.rgba(root.mOnSurface.r, root.mOnSurface.g, root.mOnSurface.b, 0.45)
                    font.pixelSize: root.fontSizeL
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
                Item {
                    Layout.fillWidth: true
                }
                Image {
                    source: "Assets/num.svg"
                    Layout.preferredWidth: 18 * scaleFactor
                    Layout.preferredHeight: 18 * scaleFactor
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    Layout.alignment: Qt.AlignVCenter
                    layer.enabled: true
                    layer.effect: ColorOverlay {
                        color: keyboard.numLock ? true : Qt.rgba(0, 0, 0, 0.5) // Semi-transparent black overlay
                    }
                }
                Text {
                    text: "NUM"
                    color: keyboard.numLock ? root.mPrimary : Qt.rgba(root.mOnSurface.r, root.mOnSurface.g, root.mOnSurface.b, 0.45)
                    font.pixelSize: root.fontSizeL
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Rectangle {
            color: root.mSurface

            width: parent.width * 0.88
            height: parent.height * 0.01
            radius: 0
                anchors {
                    left: parent.left
                    bottom: parent.bottom 
                    right: parent.right

                }
            }

    }


        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20 * scaleFactor
            spacing: 15 * scaleFactor

            // Password Field Row
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40 * scaleFactor
                spacing: 20 * scaleFactor

                // Input Box
                Rectangle {
                    id: passwordField
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: root.mSurfaceVariant
                    radius: root.configRadiusL
                    border.width: 3 * scaleFactor
                    border.color: root.mPrimary
                    property bool showPassword: false

                    TextInput {
                        id: passwordBox
                        anchors.fill: parent
                        anchors.margins: 15 * scaleFactor
                        verticalAlignment: Text.AlignVCenter

                        text: ""
                        echoMode: passwordField.showPassword ? TextInput.Normal : TextInput.Password
                        color: root.mOnSurface
                        font.pixelSize: 14 * scaleFactor
                        font.letterSpacing: 4
                        cursorDelegate: Rectangle {
                            color: root.mPrimary
                            width: 1 // Set width for the beam
                        }
                        
                        focus: true

                        onAccepted: sddm.login(userModel.lastUser, passwordBox.text, sessionModel.lastIndex)
                        Keys.onPressed: {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                sddm.login(userModel.lastUser, passwordBox.text, sessionModel.lastIndex);
                                event.accepted = true;
                            }
                        }
                    }
                    Image {
                        id: eyeIcon
                        anchors.right: parent.right
                        anchors.rightMargin: 14 * scaleFactor
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18 * scaleFactor
                        height: 18 * scaleFactor
                        source: passwordField.showPassword ? "Assets/eye.svg" : "Assets/eye-off.svg"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        layer.enabled: true
                        layer.effect: ColorOverlay {
                            color:  root.mTertiary passwordField.showPassword ? "Assets/eye-off.svg" : "Assets/eye.svg"
                        }
                    }
                    MouseArea {
                            anchors.fill: eyeIcon
                            cursorShape: Qt.PointingHandCursor
                            onClicked: passwordField.showPassword = !passwordField.showPassword
                    }
                    Text {
                        anchors.fill: parent
                        anchors.margins: 15 * scaleFactor
                        verticalAlignment: Text.AlignVCenter
                        text: "Password..."
                        color: Qt.rgba(root.mOnSurfaceVariant.r, root.mOnSurfaceVariant.g, root.mOnSurfaceVariant.b, 0.5)
                        font.pixelSize: 14 * scaleFactor
                        visible: !passwordBox.text && !passwordBox.activeFocus
                    }
                }

                // Login Button
                Controls.Button {
                    Layout.preferredWidth: 60 * scaleFactor
                    Layout.fillHeight: true

                    background: Rectangle {
                        color: parent.down ? Qt.darker(root.mPrimary, 1.2) : root.mPrimary
                        radius: root.configRadiusL
                    }

                    contentItem: Text {
                        text: "󰍂 "
                        font.pixelSize: 20 * scaleFactor
                        font.bold: false
                        color: root.mOnPrimary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: sddm.login(userModel.lastUser, passwordBox.text, sessionModel.lastIndex)
                }
            }

            // Controls Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10 * scaleFactor

                // Session List
                Controls.ComboBox {
 
                    id: sessionList
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex
                    Layout.preferredWidth: 180 * scaleFactor
                    Layout.preferredHeight: 40 * scaleFactor
                    // arrowIcon: Qt.resolvedPath("Assets/arrow_down.svg")

                    HoverHandler {
                        id: mouse
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        cursorShape: Qt.PointingHandCursor
                    }

                    delegate: Controls.ItemDelegate {
                        width: parent.width
                        text: model.name || "" 
                        highlighted: sessionList.highlightedIndex === index

                        HoverHandler {
                            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                            cursorShape: Qt.PointingHandCursor
                        }

                        contentItem: Text {
                            text: parent.text
                            color: highlighted ? root.mSurfaceVariant : root.mOnSurface
                            font.pixelSize: root.fontSizeM
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: root.configRadiusL
                            Behavior on color {
                                ColorAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                            color: highlighted ? root.mPrimary : "transparent"
                        }
                    }

                    background: Rectangle {
                        color: "transparent"
                        radius: root.configRadiusL
                        border.color: root.mOutline
                        border.width: mouse.hovered ? 1.5 * scaleFactor : 0

                    }

                    contentItem: Text {
                        leftPadding: 16 * scaleFactor
                        text: sessionList.displayText || ""
                        color: root.mOnSurface
                        font.pixelSize: root.fontSizeL
                        font.bold: true
                        verticalAlignment: Text.AlignVCenter
                    }

                    popup: Controls.Popup {
                        y: sessionList.height - 1
                        width: sessionList.width
                        implicitHeight: contentItem.implicitHeight
                        padding: 2 * scaleFactor

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: sessionList.popup.visible ? sessionList.delegateModel : null
                            currentIndex: sessionList.highlightedIndex
                            Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
                        }

                        background: Rectangle {
                            border.color: root.mOutline
                            color: root.mSurface
                            radius: root.configRadiusL
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                } // Spacer

                // Power Buttons
                Repeater {
                    model: [
                        {
                            text: "Suspend",
                            type: "suspend"
                        },
                        {
                            text: "Reboot",
                            type: "reboot"
                        },
                        {
                            text: "Shutdown",
                            type: "shutdown"
                        }
                    ]
                    delegate: Controls.Button {
                        text: modelData.text
                        Layout.preferredHeight: 40 * scaleFactor
                        Layout.preferredWidth: 100 * scaleFactor
                        scale: hovered ? 1.04 : 1.0
                        hoverEnabled: true

                        background: Rectangle {
                            border.width: 1.35 * scaleFactor
                            border.color: modelData.type === "shutdown" ? mError : root.mOutline
                            color: parent.down ? Qt.darker(root.mSurface, 0.8) : root.mSurface
                            radius: root.configRadiusL
                        }

                        MouseArea { 
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                        }
                        contentItem: Text {
                            text: parent.text
                            font.pixelSize: root.fontSizeM
                            font.bold: true
                            color: modelData.type === "shutdown" ? root.mError : root.mOnSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            if (modelData.type === "suspend") {
                                sddm.suspend();
                            } else if (modelData.type === "reboot") {
                                sddm.reboot();
                            } else if (modelData.type === "shutdown") {
                                sddm.powerOff();
                            }
                        }
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Error Message
    // -------------------------------------------------------------------------
    Rectangle {
        width: errorMessage.implicitWidth + 40 * scaleFactor
        height: 50 * scaleFactor
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: bottomCard.top
        anchors.bottomMargin: 20 * scaleFactor
        radius: root.configRadiusL
        color: root.mError
        visible: errorMessage.text !== ""

        Text {
            id: errorMessage
            anchors.centerIn: parent
            text: "" // Set by signal
            color: "#1e1418" // mOnError
            font.pixelSize: root.fontSizeM
            font.bold: true
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordBox.text = "";
            errorMessage.text = "Authentication failed";
        }
    }
}
