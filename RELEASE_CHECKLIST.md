# TimeToGo — Release checklist

Last updated: 19 Oct 2026

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

## 3. Test plan (real iPhone, Release build or TestFlight)

Use the **Release** build (Edit Scheme → Run → Build Configuration → Release, or TestFlight). That's what users get, and the DEV button must **not** appear. Station pairs below are ones that trigger each case; TfL plans change through the day, so if a case doesn't appear, try another arrival time.

Change stations and times in **Settings** (not by reinstalling) unless a step says otherwise. After each change, the To office time should update within about a second.

### A. Fresh install and onboarding
1. Delete the app, then install it. Onboarding starts.
2. Home station: the sheet opens instantly and lists all stations A–Z. Search "kings cross", "totteridge and", "st paul" and "battersea". Each finds the right station as you type; Battersea shows as **Battersea Power Station**, not "Battersea Power".
3. Walk time starts at "Choose"; Next stays disabled until you pick one. Same for the office station.
4. Arrival time and days: "Complete" stays disabled until at least one day is on.
5. Success page: "Next commute" shows the right next office day and your arrival time.
6. Glow animations on steps 1 and 2 loop: glow, fade, 2 s pause. Step titles are 28pt and don't clip.

### B. To office – direct journey
Use **Totteridge & Whetstone → Camden Town**.
1. "LEAVE TODAY/TOMORROW/MONDAY AT" + time. On a Saturday or Sunday it should name the next office day.
2. Journey block: Home → Totteridge & Whetstone → Camden Town → Office, **no** change row, chevron after "Office journey".
3. Status pill shows TfL's status for the Northern line.
4. Departures: every train goes toward Camden Town. Pull to refresh works; the header blurs under the status bar when you scroll; the train animation loops.

### C. Journeys with changes
| Pair (home → office) | Expect in the Journey block | Expect on the journey page |
|---|---|---|
| Totteridge & Whetstone → West Hampstead | "1 line change" | Northern line (black badge, white text) → "Change to Thameslink" with swap icon → Thameslink (pink badge, black text) → walk to West Hampstead |
| Totteridge & Whetstone → Old Street, arrive 9:00 | "1 branch change" (when TfL routes via Finchley Central) | "Branch change" between two Northern line cards |
| West Hampstead → Old Street | "2 line changes" or "1 line change, 1 branch change" | One card per train, a change row between each |

For each:
1. The departures board lists trains for the **first** train only, heading the right way.
2. Status pill: if any line on the route has delays, it names that line and says "Leave earlier to catch the … train" (suspensions say "Check your route before you leave"). Good service on all lines → green "Good service on all lines". Weekends with engineering works are the easiest time to see this.

### D. Journey page
Tap "Office journey ›" (and "Back home journey ›").
1. Sheet opens at half height; drag up to full height; ✕ and swipe down both close it.
2. Header: day and date, then "leave → arrive · minutes · changes" (or "Direct").
3. Timeline:
   - Times on the left line up with their rows.
   - Dots, dashed lines, solid lines and the pin all sit on one vertical line, with a 4pt gap around every dot, the home circle and the pin; no line inside the pin.
   - Station names are level with their dots.
   - Walk and change rows sit between the stations and line up with the text inside the train cards.
   - Train cards: badge in the line colour, "to …" and "N stops · N min" in Grey 40; tap to expand the stop list and tap again to collapse.
   - A change under 3 minutes shows the note in amber.
4. Badge colours: try a Victoria line trip (**Green Park → Brixton**) and a Bakerloo trip (**Oxford Circus → Elephant & Castle**): both have **white** badge text. Circle/Hammersmith & City/Jubilee badges have black text.
5. Force-quit and reopen the app, then tap the title straight away: the sheet shows "Loading your journey…" and then the timeline.

### E. Departures board accuracy
| Boarding → destination | Should show | Should **not** show |
|---|---|---|
| Old Street → Totteridge & Whetstone (Back home) | High Barnet trains | Edgware or Mill Hill East trains |
| Totteridge & Whetstone → Old Street | "Morden via Bank" | "via Charing Cross" trains |
| King's Cross → Edgware | Edgware trains | High Barnet trains |
| Bank → Newbury Park | "Hainault via Newbury Park" | Epping, Loughton |
| Victoria → Wimbledon | Wimbledon trains | Richmond, Ealing Broadway |
| King's Cross → Heathrow T4 | "Heathrow via T4 Loop" | Uxbridge, Rayners Lane |

1. **Near the end of a line** (Totteridge & Whetstone → Old Street): the board fills with rows marked "Scheduled · Southbound - Platform 2" after the first live train, instead of showing 0–1 trains.
2. Rows are all the same style; "Due" for a train under a minute away.
3. Late night (after about 00:15): scheduled trains still appear until the last train, then the board says no trains are found.

### F. Back home
1. Before setup: the "Need to be back right on time?" page, then "Let's go".
2. **Home** path: 2 steps → success page → leave-office time, journey block (office → home) and departures.
3. **Other place** path: 3 steps; walk time starts at "Choose"; then "At your destination" on the journey page.
4. Repeat C and D for the reverse direction (West Hampstead → Totteridge & Whetstone).

### G. Settings
1. Change each value: home/office station, walk times, arrival time, days, Back home arrival.
2. To office and Back home update within about a second of the last change; toggling days quickly stays smooth.
3. Change the office to a station that needs a change: the Journey block switches to the multi variant without restarting.

### H. Offline and errors
1. Airplane mode, then open the app: the last result shows if it's from today; otherwise "No internet connection. Pull down to try again."
2. Network back on, pull to refresh: it recovers.
3. A station pair TfL can't route: a plain message, not "HTTP …".

### I. Device and accessibility
1. Rotate the phone: stays portrait.
2. Small phone (iPhone SE / 13 mini): header artwork ends at the leave-time card, nothing cut.
3. Reduce Motion on: glow and train animations stop.
4. Largest standard text size (Settings → Display → Text Size): text grows; nothing overlaps; long station names wrap and push the card down; the journey page time column still fits.
5. iPad (if still enabled): every screen usable, or remove iPad support before submitting.

### J. Before you upload
1. Product → Archive in Release. It must build with no warnings.
2. Confirm the DEV button is absent in the TestFlight build.
3. Bump `CURRENT_PROJECT_VERSION` for each upload (and `MARKETING_VERSION` for each release).
