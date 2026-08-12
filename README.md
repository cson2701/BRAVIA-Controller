# BRAVIA Controller

A native SwiftUI remote control for Sony BRAVIA televisions, initially targeting the X90J.

## Project structure

```text
BRAVIA Controller/
├── App/                  App-wide state and dependency wiring
├── Features/
│   ├── Setup/            TV onboarding and connection validation
│   └── Remote/           Main remote-control experience
├── Models/               Device, connection, power, and command types
├── Networking/           Sony REST API and IRCC-IP clients
├── Persistence/          Keychain-backed credentials
└── Shared/Components/    Reusable SwiftUI controls
```

## TV preparation

On the TV, open Network settings and enable IP control. Select Pre-Shared Key authentication and create a key. Enable Remote Start if the app should wake the TV from standby. The phone and TV must be on the same local network.

## Current scaffold

- Manual IP address and pre-shared-key onboarding
- Authenticated `getPowerStatus` connection test
- Keychain storage for the pre-shared key
- IRCC-IP command transport
- Starter remote layout for navigation, volume, channels, and playback
- Local-network and local-HTTP Info.plist configuration

## Next implementation steps

1. Test the connection flow against the physical X90J.
2. Retrieve model/name and supported IRCC codes with `getRemoteControllerInfo`.
3. Add typed audio, input, and app-control REST endpoints.
4. Add device discovery after manual setup is proven reliable.
5. Add a unit-test target with a mocked `URLProtocol` transport.
