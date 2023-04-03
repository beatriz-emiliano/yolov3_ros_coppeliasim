import QtQuick 2.12
import QtQuick.Window 2.12

Window {
    id: mainWindow
    width: 320
    height: 225
    visible: true
    flags: Qt.Tool
    color: palette.window
    title: qsTr("QML Plugin Window")
    property alias simBridge: simBridge
    property bool sticky: false

    SystemPalette {
        id: palette
        colorGroup: SystemPalette.Active
    }

    CoppeliaSimBridge {
        id: simBridge
        onEventReceived: {
            if(typeof mainWindow[name] === 'function')
                mainWindow[name].call(mainWindow, JSON.parse(data))
        }
    }

    /* This event is sent by the plugin when the scene that has created
     * this window becomes active/inactive.
     */
    function onInstanceSwitch(active) {
        visible = sticky || active
    }
}

