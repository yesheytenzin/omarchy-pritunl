# Pritunl for the Omarchy bar

An Omarchy shell bar widget for the Pritunl VPN client. Click the shield in the bar to open a card with an on/off switch that connects or disconnects your Pritunl profile.

Requires `pritunl-client` with a profile already imported. The widget uses the first profile from `pritunl-client list`.

## Install

```bash
git clone https://github.com/yesheytenzin/omarchy-pritunl ~/.config/omarchy/plugins/tenzin.pritunl
omarchy bar put tenzin.pritunl --section right
```
