# TimeToGo — Release checklist

Last updated: 14 Oct 2026

## 1. Fixes you still need to do

### Must do before submitting
- [x] **App icon.** Added 16 Oct: `AppIcon-1024.png`, flattened to an opaque square (no alpha, no baked corners) from `exports/app icon/Icon-iOS-Default-1024@1x.png`. iOS generates dark and tinted versions automatically. Optional: design your own dark and tinted variants.
- [ ] **Bundle ID.** It's currently `timetogo.timetogo`. Change it to a reverse-DNS ID you own (e.g. `com.vahanhovhannisyan.timetogo`) **before** creating the App Store record. It can't be changed after the first release.
- [x] **TfL attribution.** The departures card now says "Powered by TfL Open Data" (done 14 Oct). Update the Figma frames to match.
- [x] **TfL app key.** Added 16 Oct. It lives in `timetogo/timetogo/Secrets.swift`, which git ignores so the key is never pushed. On a fresh clone, recreate that file:
  ```swift
  nonisolated enum Secrets { static let tflAppKey = "<Primary key from api-portal.tfl.gov.uk>" }
  ```
- [ ] **Privacy policy URL.** App Store Connect requires one, even though the app collects nothing. A one-page note is enough: "No personal data is collected; stations and times stay on your device."
- [ ] **App Store Connect privacy answers.** Answer "Data Not Collected". This matches the `PrivacyInfo.xcprivacy` now in the app.
- [ ] **iPad: decide.** The app is set up for iPhone *and* iPad, but every screen is designed for iPhone. Either remove iPad (Target → General → Supported Destinations), or test it properly, because Apple reviews on iPad too.
- [ ] **Screenshots and listing.** 6.9" iPhone screenshots, description, keywords, support URL, age rating.

### Should do soon after
- [ ] **Station list refresh.** `Resources/tube-stations.json` was generated from TfL on 13 Oct 2026. Regenerate it if TfL opens a station.
- [ ] **Figma copy.** The Back home "Other place" frames still say "Where is the office?" / "Office station". The app uses "Where is your destination?" / "Destination station".
- [ ] **Back home artwork.** The "Need to be back right on time?" illustration is a 1024 px Figma export (@2x). Export it at @3x so it's sharp.
- [ ] **`LOGIC.md` is out of date** (direction maps, settings flow). Update it or delete it.

## 2. Fixed in this pass

| Problem | Fix |
|---|---|
| DEV button and dev menu (with "Reset") shipped to users | Shown in Debug builds only (`#if DEBUG`); left out of Release entirely |
| No privacy manifest | Added `PrivacyInfo.xcprivacy` (UserDefaults, reason CA92.1; no tracking, no data collected) |
| Departures board only worked on Northern and Victoria | Direction now comes from TfL's route order for **any** line; checked live on Northern, Central and District |
| Multi-line stations picked the wrong line (King's Cross used "Circle") | Line status and departures use the line the journey actually takes |
| Journeys with a change pointed the board at the final station | The board targets the station where you leave the first train |
| iPhone allowed landscape | iPhone is portrait-only |
| Every Settings tap fired several TfL requests | Saving is instant; the reload waits until 0.6 s after your last change |
| Technical error text on screen ("HTTP 500", "Failed to parse…") | Plain messages: "No internet connection. Pull down to try again." etc. |
| Back home walk time defaulted to 5 min | Starts at "Choose", like onboarding; Next waits for a choice |
| Unused files | Deleted `ScheduleReviewSheet.swift` and `ComponentsIndex.swift` |

## 3. Test plan (do on a real iPhone, cable connected)

Use the **Release** build for steps A–F (Edit Scheme → Run → Build Configuration → Release, or TestFlight). That's what users get, and the DEV button must **not** appear.

### A. Fresh install
1. Delete the app, then install it.
2. Step 1: tap "Home station". The sheet should open instantly and list all stations A–Z.
3. Search "kings cross", "totteridge and" and "st paul". Each should find the right station as you type.
4. Choose a walk time, then Next. Step 2: same checks for the office station.
5. Step 3: arrival time, then toggle days. "Complete" stays disabled until at least one day is on.
6. Success page: "Next commute" shows the right next office day and your arrival time.
7. Glow animations on steps 1 and 2 loop: glow, fade, 2 s pause.

### B. To office tab
1. The leave time appears, with "LEAVE TODAY/TOMORROW AT".
2. The status pill shows a real TfL status.
3. Departures: try **at least 4 lines**, e.g. Northern, Central, District and Jubilee. Every train listed should be going toward your office.
4. Try a multi-line station (King's Cross, Baker Street, Bank). The departures should be on the line the journey uses.
5. Try a journey with a change (e.g. Acton Town → Old Street). The departures should show your first train.
6. Pull to refresh; scroll (the status bar blurs once scrolled); the train animation loops.

### C. Back home tab
1. Before setup: the "Need to be back right on time?" page appears, and "Let's go" opens the setup.
2. **Home** path: 2 steps, then the success page, then the leave-office time and departures.
3. **Other place** path: 3 steps. The walk time starts at "Choose"; the glow runs right to left.
4. On the success page, "Change your settings" restarts the setup.

### D. Settings
1. Change a station, a walk time, the arrival time and the days.
2. Go back to To office. The time updates within about a second of your last change.
3. Toggle days quickly. The app stays smooth (the requests are debounced).

### E. Offline and errors
1. Airplane mode, then open the app. The last result shows if it's from today; otherwise "No internet connection. Pull down to try again."
2. Turn the network back on and pull to refresh. It recovers.
3. Pick a station pair TfL can't route. You should see a plain message, not "HTTP …".

### F. Device checks
1. Rotate the phone. The app must stay portrait.
2. Try a small phone (iPhone SE / 13 mini) if you can. Check that illustrations scale and nothing is cut.
3. Turn on Settings → Accessibility → Reduce Motion. The glow and train animations stop.
4. Largest text size (Settings → Display → Text Size). Check that nothing overlaps badly.

### G. Before you upload
1. Product → Archive in Release. It must build with no warnings.
2. Confirm the DEV button is absent in the archived build (install via TestFlight first).
3. Bump `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` for each upload.
