# OCR — device verification & platform notes

On-device OCR (photos/scans) via Google ML Kit. ML Kit and `image_picker` have
no host/desktop implementation, so the *logic* is unit-tested but the *plugins*
must be exercised on a real device. This doc records what was verified
automatically, what only a human-with-a-device can verify, and the
platform-specific issues found and fixed.

## Verified automatically

| Check | Result |
| --- | --- |
| `flutter analyze` | clean |
| `flutter test` (incl. OCR→pipeline reconcile) | 73 pass |
| **Android debug APK build** (ML Kit + image_picker link, minSdk OK) | ✅ built `app-debug.apk` |
| iOS build (pods resolve at deployment target 15.5) | ⚠️ **not verified here** — env reported "Application not configured for iOS" (no CocoaPods/Xcode signing). Config fixes applied but unproven; build on a configured Mac. |
| OCR output → parser pipeline | ✅ unit-tested: a synthetic OCR statement reconciles and auto-detects the bank |

The Android build is the important one and it passed: it proves the native ML
Kit libraries compile and link and that `minSdk` is high enough. iOS was not
buildable in this environment, so the iOS-side fixes below still need a real
`pod install` / `flutter build ios` to confirm.

## Platform issues found & fixed

- **iOS would crash on camera/gallery** — `Info.plist` was missing the required
  usage strings. Added `NSCameraUsageDescription` and
  `NSPhotoLibraryUsageDescription`. (Without these, iOS terminates the app the
  moment `image_picker` opens.)
- **iOS pods would fail to install** — ML Kit text recognition requires iOS
  **15.5+**, but the project targeted **13.0**. Bumped
  `IPHONEOS_DEPLOYMENT_TARGET` to 15.5 (Debug/Release/Profile). On first iOS
  build also set `platform :ios, '15.5'` in the generated `ios/Podfile`.
- **Android** — `image_picker` needs no extra permission (it uses the system
  camera/photo-picker), and ML Kit's `minSdk 21` is satisfied by the Flutter
  default. No manifest change required. Confirmed by the successful APK build.

## Needs a human + a physical device (cannot be automated)

Run on a real Android phone and a real iPhone:

1. **Camera flow** — Upload → "Photo or scan" → Take a photo → grant the camera
   permission → confirm the conversion runs and rows appear.
2. **Gallery flow** — "Photo or scan" → Choose from gallery → pick a statement
   image → confirm the conversion runs.
3. **Real statement** — photograph an actual (anonymised) Emirates NBD
   statement and confirm: rows extracted, debit/credit correct, balance
   reconciles, low-confidence rows flagged. Capture the result for the accuracy
   harness (`test/fixtures/accuracy/`).
4. **Permission-denied path** — deny the camera permission and confirm the app
   degrades gracefully (no crash).
5. **iOS pods** — `cd ios && pod install` (or `flutter build ios`) succeeds with
   the 15.5 target.

## Scanned PDFs (added)

A PDF with no text layer is now **rasterised page-by-page** (`printing`) and the
page images are OCR'd and merged into one document, which flows through the same
classify → template → reconcile pipeline. Password-protected scans are decrypted
in memory (Syncfusion) before rasterising. Add a real scanned PDF to the
on-device checklist: Upload → Browse PDF → pick a scanned statement → confirm it
converts (it should no longer say "OCR coming soon").

## Known limitations (deliberately not yet solved)

- **OCR accuracy on real scans is unmeasured.** This makes scans *work*; whether
  they're *accurate enough* needs real scanned statements run through the
  harness. Low-confidence rows are flagged, so errors surface for review rather
  than ship silently.
- **Rasterisation is device-only** (`printing` uses platform PDF renderers), so
  it is not covered by host tests — verify on a real device. The merge/parse
  logic it feeds *is* unit-tested.
