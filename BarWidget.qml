import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "tenzin.pritunl"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property string profileId: ""
  property string profileName: ""
  property bool connected: false
  property bool connecting: false
  property bool popupOpen: false

  readonly property string statusText: root.profileId === "" ? strings.t("noProfile")
    : strings.t(root.connected ? "connected" : root.connecting ? "connecting" : "disconnected")

  function close() { popupOpen = false }

  Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  function refresh() {
    if (!listProc.running) listProc.running = true
  }

  function toggle() {
    if (root.profileId === "" || actionProc.running) return
    actionProc.command = ["pritunl-client", root.connected || root.connecting ? "stop" : "start", root.profileId]
    root.connecting = !root.connected
    actionProc.running = true
  }

  Process {
    id: listProc
    command: ["pritunl-client", "list", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        let profiles = []
        try { profiles = JSON.parse(text) } catch (e) { profiles = [] }
        const profile = Array.isArray(profiles) && profiles.length > 0 ? profiles[0] : null
        if (!profile || !/^[a-z0-9]+$/.test(String(profile.id))) {
          root.profileId = ""
          root.profileName = ""
          root.connected = false
          root.connecting = false
          return
        }
        root.profileId = String(profile.id)
        root.profileName = String(profile.name || "").slice(0, 64)
        root.connected = profile.connected === true
        root.connecting = !root.connected && profile.run_state === "Active"
      }
    }
  }

  Process {
    id: actionProc
    onExited: root.refresh()
  }

  Timer {
    interval: root.connecting ? 2000 : 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.connected ? "\u{f099d}" : root.connecting ? "\u{f0582}" : "\u{f099e}"
    active: root.connected
    opacity: root.connecting ? 0.6 : 1
    tooltipText: root.popupOpen ? "" : root.statusText
    onPressed: root.popupOpen = !root.popupOpen
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(280))
    contentHeight: popup.fittedContentHeight(row.implicitHeight)

    Item {
      id: row
      width: parent.width
      implicitHeight: Math.max(labels.implicitHeight, powerSwitch.implicitHeight)

      Column {
        id: labels
        anchors.left: parent.left
        anchors.right: powerSwitch.left
        anchors.rightMargin: Style.space(12)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.space(4)

        Text {
          width: parent.width
          textFormat: Text.PlainText
          elide: Text.ElideRight
          text: root.profileName !== "" ? root.profileName : strings.t("title")
          color: Commons.Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }
        Text {
          width: parent.width
          textFormat: Text.PlainText
          elide: Text.ElideRight
          text: root.statusText
          color: Commons.Color.popups.text
          opacity: 0.7
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }
      }

      ToggleSwitch {
        id: powerSwitch
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        enabled: root.profileId !== ""
        checked: root.connected || root.connecting
        busy: actionProc.running
        foreground: Commons.Color.popups.text
        onToggled: root.toggle()
      }
    }
  }
}
