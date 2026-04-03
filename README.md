# VoiceSpell

**Cast magic spells with your voice to control your Android phone.**

Say *"Illumina"* and your flashlight toggles. Say *"Tempus"* and a 5-minute timer starts. Say *"Silencio"* and the phone goes silent. No tapping, no searching — just your voice.

## Download

Get the latest APK from the [Releases](https://github.com/YShevchenko/voicespell-public/releases) page.

## Features

### Free Tier — 5 Default Spells

| Spell | Trigger | Action |
|---|---|---|
| Toggle Flashlight | *"Illumina"* | Toggle flashlight on/off |
| Adjust Brightness | *"Obscura"* | Toggle screen brightness (10% / 100%) |
| 5-Minute Timer | *"Tempus"* | Schedule a 5-minute notification timer |
| Mute / Unmute | *"Silencio"* | Toggle system volume mute |
| Flash Reveal | *"Revelio"* | Flashlight on for 3 seconds, then off |

### Premium ($3.99 one-time)

- Up to **20 active spells**
- **Rename** any trigger phrase
- **Create custom spells** with Android Intent URLs (open apps, run shortcuts, etc.)
- One-time purchase — no subscription, no ads

## How It Works

1. Tap the glowing orb on the Cast screen
2. Say your spell trigger phrase
3. The app matches your words against the spellbook using on-device speech recognition
4. The matched action executes — heavy haptic on success, light haptic on fizzle

All processing is **100% on-device**. No cloud, no backend, no data collection.

## Requirements

- Android 5.0+ (API 21+)
- Microphone permission for voice recognition
- Camera permission for flashlight control

## Building from Source

```bash
flutter build apk --release
```

## Architecture

- **State management**: `provider`
- **Database**: SQLite via `sqflite`
- **Speech**: `speech_to_text` (on-device)
- **IAP**: `in_app_purchase` (product: `voicespell_premium`)
- **Notifications**: `flutter_local_notifications` with `timezone`
- **Haptics**: `HapticFeedback.heavyImpact` / `lightImpact`

## Publisher

**Heldig Lab** — heldig.lab@pm.me
