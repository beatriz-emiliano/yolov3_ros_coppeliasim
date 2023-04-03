import CoppeliaSimPlugin.Bridge 1.0 as Bridge

Bridge.CoppeliaSimBridge {
    function sendEvent(name, data) {
        sendEventRaw(name, JSON.stringify(data))
    }
}
