---
description: Fix Xcode "concurrent builds" error by killing processes and clearing cache
---
1. Kill any running xcodebuild processes to unlock the build lock.
// turbo
killall -9 xcodebuild || true

2. Delete the iOS DerivedData folder contents to clear stale build artifacts.
// turbo
rm -rf ~/Library/Developer/Xcode/DerivedData/*

3. Clean the Flutter project.
// turbo
flutter clean

4. Fetch dependencies.
// turbo
flutter pub get
