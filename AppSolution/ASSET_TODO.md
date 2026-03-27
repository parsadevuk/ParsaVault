# Asset To-Do List — Parsa Vault

Everything below needs to be done manually. The app builds and runs without these — they are replacements for the current placeholders.

---

## 1. App Icon

**Where to put it:**
`parsa_vault/ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Flutter generates this folder automatically. Replace the contents with your icon files.

**Files needed (iOS):**

| File Name | Size | Use |
|-----------|------|-----|
| `Icon-App-20x20@1x.png` | 20×20 | Notifications |
| `Icon-App-20x20@2x.png` | 40×40 | Notifications |
| `Icon-App-20x20@3x.png` | 60×60 | Notifications |
| `Icon-App-29x29@1x.png` | 29×29 | Settings |
| `Icon-App-29x29@2x.png` | 58×58 | Settings |
| `Icon-App-29x29@3x.png` | 87×87 | Settings |
| `Icon-App-40x40@1x.png` | 40×40 | Spotlight |
| `Icon-App-40x40@2x.png` | 80×80 | Spotlight |
| `Icon-App-40x40@3x.png` | 120×120 | Spotlight |
| `Icon-App-60x60@2x.png` | 120×120 | Home screen |
| `Icon-App-60x60@3x.png` | 180×180 | Home screen |
| `Icon-App-76x76@1x.png` | 76×76 | iPad |
| `Icon-App-76x76@2x.png` | 152×152 | iPad |
| `Icon-App-83.5x83.5@2x.png` | 167×167 | iPad Pro |
| `Icon-App-1024x1024@1x.png` | 1024×1024 | App Store |

**Logo style for app icon:**
- Gold letter P with vault dial on black background
- No transparency (Apple requires solid backgrounds for app icons)
- Use the "Gold on black" logo variant

**Tip:** Use a tool like `flutter_launcher_icons` package or Xcode to auto-resize from the 1024×1024 master.
Simplest way: paste one 1024×1024 PNG into Xcode and it generates all sizes.

---

## 2. In-App Logo (Splash + Auth Screens)

The current placeholder is a gold "P" in a circle drawn with Flutter code.

**Where to put your real logo:**
`parsa_vault/assets/images/logo_transparent.png`

**Create this folder first:**
```
parsa_vault/assets/
parsa_vault/assets/images/
```

**Then add to `pubspec.yaml`** under `flutter:`:
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

**Files needed:**

| File Name | Size | Background | Use |
|-----------|------|-----------|-----|
| `logo_transparent.png` | 240×240 | Transparent | Main in-app logo |
| `logo_on_white.png` | 240×240 | White | Fallback / documents |
| `logo_on_black.png` | 240×240 | Black | Dark contexts |

**All at 3× resolution = 720×720 pixels for @3x screens.**

---

## 3. After Adding Logo Files

In `splash_screen.dart`, replace this block:

```dart
// Current placeholder:
Container(
  width: 120,
  height: 120,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    border: Border.all(color: AppColors.gold, width: 2.5),
  ),
  child: Center(
    child: Text('P', style: ...),
  ),
),
```

With:

```dart
// Real logo:
Image.asset(
  'assets/images/logo_transparent.png',
  width: 120,
  height: 120,
),
```

Same replacement in `register_screen.dart` and `login_screen.dart` for the smaller 60×60 logo — use width/height 60.

---

## 4. Asset Icons (Stocks and Crypto)

Currently the app uses generic Flutter icons for each asset tile:
- Stocks: `Icons.show_chart` on a grey background
- Crypto: `Icons.currency_bitcoin` on a gold background

**Optional upgrade later:**
Create `assets/images/assets/` and add PNG logos for each of the 40 assets:

```
aapl.png, msft.png, googl.png, amzn.png, nvda.png, meta.png,
tsla.png, nflx.png, amd.png, intc.png, dis.png, pypl.png,
uber.png, spot.png, shop.png, crm.png, baba.png, ba.png,
jpm.png, v.png

btc.png, eth.png, bnb.png, sol.png, xrp.png, ada.png,
doge.png, avax.png, dot.png, matic.png, link.png, uni.png,
atom.png, ltc.png, bch.png, xlm.png, algo.png, vet.png,
fil.png, sand.png
```

**Size:** 64×64 or 128×128 PNG with transparent background.

**Where to update the code:** `lib/widgets/common/asset_tile.dart` — replace the `_AssetIcon` widget with an `Image.asset` call.

---

## 5. Running on iOS Simulator Right Now

```bash
cd /Users/parsaprojects/GitHub/ParsaVault/parsa_vault
open -a Simulator
flutter run
```

Or in VS Code: press **F5** with the parsa_vault folder open.

---

## 6. Running on Real iPhone (When Ready)

1. Buy Apple Developer Program at developer.apple.com ($99/year)
2. Open `parsa_vault/ios/Runner.xcworkspace` in Xcode
3. Sign in with your Apple ID → Signing & Capabilities → select your team
4. Connect your iPhone → select it as the target → Run

For TestFlight: Archive in Xcode → Distribute App → TestFlight.
