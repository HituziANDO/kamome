# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Kamome is a cross-platform WebView bridge library that enables bidirectional communication between JavaScript running in a WebView and native code on iOS (Swift) and Android (Java/Kotlin). Version 5.4.0. A separate Flutter plugin exists at [kamome_flutter](https://github.com/HituziANDO/kamome_flutter).

## Build & Development Commands

### JavaScript library (`js/kamome/`)
```bash
cd js/kamome
npm install
npm run build        # Vite build → dist/ (UMD + ES modules + type declarations)
npm run test         # Vitest with jsdom
npm run lint         # ESLint + Prettier check
npm run lint:fix     # ESLint + Prettier auto-fix
npm run dev          # Vite dev server
```

### JavaScript sample app (`js/kamome-sample/`)
```bash
cd js/kamome-sample
npm install
npm run dev          # Vite dev server (Vue 3 + Vuetify)
npm run build        # vue-tsc + Vite build
npm run copy         # Build then copy dist/ to both iOS and Android sample app asset directories
npm run ios          # Copy dist/ to ios/kamome-ios-sample/KamomeSwift/www/
npm run android      # Copy dist/ to android/app/src/main/assets/www/
```

### iOS (`ios/kamome-framework/`)
- Xcode project: `ios/kamome-framework/kamome.xcodeproj`
- Build xcframework: `xcodebuild -scheme "kamomeUniversal" -configuration Release`
- Also available via Swift Package Manager (`Package.swift` at repo root), CocoaPods (`kamome.podspec`), and Carthage
- Platforms: iOS 12.0+, macOS 10.15+
- Sample app: `ios/kamome-ios-sample/KamomeSwift.xcodeproj`

### Android (`android/`)
```bash
cd android
./gradlew --info publish    # Build AAR and publish to local Maven repo
```
- compileSdk/targetSdk 34, minSdk 17
- Namespace: `jp.hituzi.kamome`
- Sample app module: `android/app/`

### Full build (all platforms)
```bash
./make_libs.sh [optional-codesign-credentials]
# Outputs to output/kamome/{js,android,ios}/
```

## Architecture

### Communication Pattern

All platforms implement the same symmetric request/response bridge:

- **JS → Native**: `KM.send(commandName, data)` returns a Promise. Native side registers handlers via `Client.add(Command(name, handler))`. Handler calls `completion.resolve(data)` or `completion.reject(error)`.
- **Native → JS**: Native calls `client.send(data, commandName)`. JS registers receivers via `KM.addReceiver(commandName, callback)`. Callback calls `resolve(result)` or `reject(error)`.
- **Browser-only mode**: `KM.browser.addCommand(name, handler)` registers JS-side fallback handlers when no native client is present.

### Platform Implementations

Each platform has parallel types implementing the same concepts:

| Concept | JS (`js/kamome/src/`) | iOS (`ios/kamome-framework/src/`) | Android (`android/kamome/src/.../kamome/`) |
|---------|----------------------|-----------------------------------|---------------------------------------------|
| Entry point | `KM.ts` | `Client.swift` | `Client.java` |
| Command handler | built into KM | `Command.swift` | `Command.java` |
| Request lifecycle | `KamomeRequest.ts` | `Request.swift`, `Completable.swift`, `Completion.swift` | `Request.java`, `Completable.java`, `Completion.java` |
| Message transport | `platform/index.ts` (detects iOS/Android/Flutter/browser) | `Messenger.swift` (WKWebView script injection) | `Messenger.java` (JavascriptInterface) |

### JavaScript Module

TypeScript with strict mode. Builds to both UMD (`dist/index.umd.js`, global `window.Kamome`) and ES module (`dist/index.es.js`) via Vite. Platform detection in `platform/index.ts` adapts transport to the runtime environment.

### Version Synchronization

Version is tracked in multiple places that must stay in sync:
- `js/kamome/package.json` → `version`
- `kamome.podspec` → `s.version`
- `android/gradle.properties` → `LIB_VERSION` and `LIB_VERSION_CODE`
