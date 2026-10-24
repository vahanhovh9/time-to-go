# **TimeToGo — Logic Specification**

## **1. Purpose**

TimeToGo is a proactive commute agent.

The app calculates the exact time a user must leave home in order to arrive at their office desk at a preferred time.

The user completes setup once.

After that, whenever the user needs to know when to leave, they open TimeToGo and see the leave time immediately — no external map apps.

The app sends no notifications and does no background work. Everything is calculated on demand when the app is opened.

---

## **2. Core Architecture Principles**

- Business logic must NOT live inside SwiftUI Views.
- All commute calculation logic must live inside a dedicated service (e.g., CommuteCalculationService).
- UI reads computed state only.
- TFL API integration must be isolated inside a TFLService.

Pattern: MVVM

---

## **3. Stored User Data**

Persisted after setup:

```
userHomeLine: String
userHomeStation: String
userWalkingTimeToStation: Int (minutes)

userOfficeLine: String
userOfficeStation: String
userWalkingTimeToOffice: Int (minutes)

userArrivalTime: Date (time-only component)
officeDays: [Weekday]
```

---

## **4. Setup Logic**

### **Step 1 — Home**

- Fetch tube lines from TFL API
- Sort alphabetically
- On selection → store userHomeLine
- Fetch stations for selected line
- Sort alphabetically
- On selection → store userHomeStation
- Store walking time to station

### **Step 2 — Office**

Same logic as Step 1

### **Step 3 — Arrival**

- Store arrival time
- Store selected weekdays

Setup has 3 steps. There is no notification step.

---

## **5. Completion Logic**

When setup completes:

1. Save settings.
2. Show success screen:

    “Open TimeToGo whenever you’re heading out.”

3. On “All done” → open the main screen, which calculates the commute immediately.

---

## **6. Main Page Logic**

### **Small Text**

Determine relative phrasing:

Based on the next commute day:

If next commute day == tomorrow →

“Tomorrow at”

If >1 day away →

“Upcoming  at”

If today →

“Today at”

---

## **7. Core Commute Calculation (Main Engine)**

When determining Leave Time:

1. Determine closest upcoming commute day
2. Retrieve:
    - userArrivalTime
    - userWalkingTimeToOffice
    - userWalkingTimeToStation
3. Calculate:
    
    desiredTrainArrivalTime = userArrivalTime - walkingTimeToOffice
    
4. Query TFL API:
    - Build journey from home station to office station
    - Consider multi-line transfers
    - Must arrive at or BEFORE desiredTrainArrivalTime
    - Never after
5. From selected valid journey:
    - Determine train arrival time at home station
    - Subtract walkingTimeToStation
    - Add safetyBufferMinutes (default: 2–3 mins)
6. Result:
    
    leaveHomeTime
    

This is the Large Time displayed on main page.

---

## **8. Service Status Logic**

On each calculation:

- Fetch line status from TFL API
- If all lines “Good Service” → show:
    
    “Good services on all lines”
    
- If delays:
    
    Show “Minor Delays” or “Major Delays”
    

---

## **9. Info Block Logic**

### **Home**

Show:

- userHomeStation
- calculated train arrival time at home station

### **Tube Journey**

Show:

- numberOfStations between home and office
- total journey duration

### **Work**

Show:

- userOfficeStation
- userArrivalTime

---

## **10. Non-Negotiable Rules**

- Arrival must never be later than userArrivalTime
- Calculations must update automatically if:
    - Date changes
    - API status changes
- All time calculations must use user’s locale and timezone
- No hardcoded times inside Views

---

## **11. On-Demand Delivery & Cache Logic**

11.1 Purpose

TimeToGo has no notifications and no background execution.

The user opens the app whenever they need it; the app shows the current leave time.

The system must:
	•	Calculate the commute when the app opens.
	•	Never show stale leave times as if they were fresh.

⸻

11.2 Removed Behaviour

The following do NOT exist and must not be reintroduced without a spec change:
	•	Notification permission requests
	•	Scheduled / placeholder notifications
	•	BGTaskScheduler background refresh
	•	Notification deep links
	•	Notification time / days settings

On launch the app clears any notifications left pending or delivered by older builds.

⸻

11.5 Fallback Policy

If a fresh calculation fails:
	•	Normal load → show the last same-day cached result with “(Using last available data)”.
	•	Forced refresh (manual refresh, settings change) → surface the real error.

⸻

11.6 Cache Rules

Cache must store:
	•	leaveHomeTime
	•	trainArrivalTime
	•	journeyDuration
	•	serviceStatus
	•	commuteDate
	•	timestamp

Cache validity:
	•	Same commute date
	•	Not older than 24 hours

If cache exists but is outdated:
	•	It may be displayed inside the app only with a clear staleness indicator.

⸻

11.9 Settings Change Rule

If user updates:
	•	Arrival time
	•	Office days
	•	Home or office station
	•	Walking durations

Then:
	•	Save settings.
	•	Force a fresh commute calculation.

⸻


⸻

12. Outbound Commute Logic

12.1 Purpose

TimeToGo currently supports inbound commute only:

* Home → Office

Outbound is introduced as an optional add-on flow:

* Office → Home
* Office → Other destination

Outbound allows the user to determine when to leave the office in order to arrive at a destination at a specific required time.

Example:

User must be at nursery at 5:50 PM.

⸻

12.2 Bottom Navigation

Bottom navigation always shows:

Inbound
Outbound
Settings

Inbound

* Always available after initial setup.
* Opens inbound commute screen.

Outbound

If outbound is not configured:

* Opens outbound intro screen.

If outbound is configured:

* Opens outbound commute screen.

Settings

Before outbound is configured:

* Show inbound settings only.

After outbound is configured:

* Show:
    * Inbound settings
    * Outbound settings

Condition:

outboundEnabled == true

⸻

12.3 Outbound Entry Flow

When user taps Outbound (not configured):

Show intro screen:

Need to be back right on time?
Use Outbound to know when you should leave the office.

CTA:

Let’s go

On tap:

* Start outbound setup.

⸻

12.4 Outbound Setup

Step 1 — Destination Type

Where are you going after work?

Options:

Home
Other place

⸻

12.5 Option A — Home

Reuse inbound home data:

outboundDestinationLine = userHomeLine
outboundDestinationStation = userHomeStation
outboundWalkingTimeFromStation = userWalkingTimeToStation

Ask:

When do you need to be home?

Store:

outboundArrivalTime: Date

⸻

12.6 Option B — Other Place

Step 1 — Destination Station

* Fetch lines from TFL API
* Sort alphabetically
* Select line → fetch stations
* Sort alphabetically
* Select station

Store:

outboundDestinationLine: String
outboundDestinationStation: String

Step 2 — Walking Time

outboundWalkingTimeFromStation: Int

Step 3 — Arrival Time

outboundArrivalTime: Date

⸻

12.7 Stored Data

outboundEnabled: Bool
outboundDestinationType: OutboundDestinationType
// home | otherPlace
outboundDestinationLine: String
outboundDestinationStation: String
outboundWalkingTimeFromStation: Int
outboundArrivalTime: Date

Outbound runs on the same officeDays as inbound.

⸻

12.8 Completion Logic

On outbound setup completion:

1. Save all outbound data
2. Set:

outboundEnabled = true

3. Show success screen:

Outbound is all set!
Open TimeToGo whenever you’re heading out.

⸻

12.9 Outbound Commute Calculation

Direction:

Office → Destination

Steps:

1. Determine next outbound commute day
2. Retrieve:
    * userOfficeStation
    * outboundDestinationStation
    * outboundArrivalTime
    * outboundWalkingTimeFromStation
    * userWalkingTimeToOffice
3. Calculate:

desiredTrainArrivalTime = outboundArrivalTime - outboundWalkingTimeFromStation

4. Query TFL API:
    * Journey from office → destination
    * Must arrive ≤ desiredTrainArrivalTime
5. From selected journey:

leaveOfficeTime = trainDepartureTime - userWalkingTimeToOffice - safetyBufferMinutes

6. Result:

leaveOfficeTime

⸻

12.11 Cache Rules

Use separate cache:

OutboundCommuteCache

Store:

leaveOfficeTime
trainDepartureTime
trainArrivalTime
journeyDuration
serviceStatus
commuteDate
timestamp

Validity:

* Same commute date
* Not older than 24 hours

⸻

12.12 Settings Behavior

If outboundEnabled:

Show:

Outbound destination
Outbound arrival time
Outbound walking time
Reset outbound
Disable outbound

If outbound disabled:

* Hide outbound settings

⸻

12.13 Non-Negotiable Rules

* Outbound must never affect inbound logic
* Arrival must never be later than outboundArrivalTime
* Outbound cache must be separate from inbound cache
* Stale leave times must never be shown as fresh
* Updating outbound settings must recalculate outbound only
* Updating inbound must not break outbound (except shared station data)

⸻
---



# 13. Review Schedule Logic

## 13.1 Purpose

Review Schedule allows the user to inspect the current live train arrivals for the station where they will board the first train of the active commute journey.

It is available for both:

- Inbound: Home → Office
- Outbound: Office → Destination

The feature is informational only.

It must NOT:

- Recalculate the commute
- Modify active commute results
- Affect cache state
- Change leave times
- Modify setup data
- Persist temporary schedule filtering state

The purpose of Review Schedule is to display the real live train board for the boarding station, filtered to only trains travelling toward the commute destination.

The feature must behave similarly to how a real passenger thinks on the Underground.

Example:

If a user is travelling:

Highgate → Old Street

the schedule should display trains travelling toward:

- Morden via Bank
- Morden via Charing Cross
- Battersea Power Station

It must NOT display trains travelling toward:

- High Barnet
- Mill Hill East
- Edgware

The feature should primarily reason about train destinations and terminal directions, not only geographic northbound/southbound labels.

---

# 13.2 Entry Point

Both Inbound and Outbound commute screens must display a text button below the commute information block:

Review the schedule

The button must be visible always.

A valid commute result requires:

- A successful journey calculation
- A valid boarding train time
- A valid origin station
- A valid first-leg lineId
- A valid first-leg stopId
- A valid first-leg destination/towards value

If the app cannot determine the correct train direction for the journey, Review Schedule should not open rather than showing potentially incorrect trains.

Correctness is more important than completeness.

---

# 13.3 Core Direction Philosophy

Review Schedule exists to answer one question:

Which trains currently arriving at this station move the user toward their destination?

The system must primarily determine direction using:

- train destination
- towards value
- terminal station

rather than relying only on:

- northbound
- southbound
- eastbound
- westbound

Reason:

TfL passengers typically navigate using train destinations.

Example:

A passenger at Woodside Park travelling toward central London thinks:

"I need a Morden train."

not:

"I need a southbound train."

Terminal-based filtering is therefore the preferred direction model.

Cardinal platform direction text should be treated as supporting or fallback information.

---

# 13.4 Inbound Schedule Review

Inbound schedule review always uses inbound commute data only.

Direction:

Home → Office

Origin station:

userHomeStation

Origin stopId:

userHomeStationStopId

Destination station:

userOfficeStation

Reference line:

inboundFirstLegLineId

Reference towards value:

inboundFirstLegTowards

Reference direction:

inboundFirstLegDirection

Reference boarding train time:

inboundBoardingTrainArrivalTimeAtHomeStation

When the user taps Review the schedule:

1. Open the schedule screen or bottom sheet

2. Fetch live arrivals using:

/StopPoint/{userHomeStationStopId}/Arrivals

3. Keep only arrivals matching:

inboundFirstLegLineId

4. Determine which train destinations move toward the office station

5. Keep only arrivals whose:

- towards
- destinationName
- platformName direction text

match the active inbound journey direction

6. Remove arrivals where:

- expectedArrival is missing
- expectedArrival is already in the past

7. Sort remaining arrivals by expectedArrival ascending

8. Return the next 20 valid arrivals

Example:

If the user travels:

Totteridge & Whetstone → Battersea Power Station

valid trains include:

- Morden via Bank
- Morden via Charing Cross
- Battersea Power Station

invalid trains include:

- High Barnet
- Edgware
- Mill Hill East

Only trains travelling toward the office must be displayed.

---

# 13.5 Outbound Schedule Review

Outbound schedule review always uses outbound commute data only.

Direction:

Office → Destination

Origin station:

userOfficeStation

Origin stopId:

userOfficeStationStopId

Destination station:

outboundDestinationStation

Reference line:

outboundFirstLegLineId

Reference towards value:

outboundFirstLegTowards

Reference direction:

outboundFirstLegDirection

Reference boarding train time:

outboundBoardingTrainArrivalTimeAtOfficeStation

When the user taps Review the schedule:

1. Open the schedule screen or bottom sheet

2. Fetch live arrivals using:

/StopPoint/{userOfficeStationStopId}/Arrivals

3. Keep only arrivals matching:

outboundFirstLegLineId

4. Determine which train destinations move toward the outbound destination

5. Keep only arrivals whose:

- towards
- destinationName
- platformName direction text

match the active outbound journey direction

6. Remove arrivals where:

- expectedArrival is missing
- expectedArrival is already in the past

7. Sort remaining arrivals by expectedArrival ascending

8. Return the next 20 valid arrivals

Outbound schedule review must remain fully isolated from inbound schedule review.

Outbound direction must always be based on:

Office → Destination

never:

Home → Office

---

# 13.6 TFL API Usage

Review Schedule must use only the live arrivals endpoint:

/StopPoint/{stopId}/Arrivals

Example:

/StopPoint/940GZZLUTTW/Arrivals

Review Schedule must NOT use:

- Journey Planner recalculation
- Timetable endpoints
- Cached train boards
- Static schedules
- Synthetic train generation

The feature exists purely to display the current live station board filtered to trains moving toward the user’s destination.

---

# 13.7 Filtering Pipeline

Filtering logic must exist only inside:

- ScheduleReviewService
or
- ScheduleReviewViewModel

SwiftUI Views must never contain filtering or business logic.

Views must render already-computed schedule state only.

The filtering pipeline must execute in this order:

1. Fetch live arrivals for the selected stopId

2. Remove arrivals with missing expectedArrival

3. Remove arrivals whose expectedArrival is already in the past

4. Keep only arrivals matching the selected lineId

5. Determine the valid journey direction using:
   - towards value
   - destination station
   - terminal station
   - fallback cardinal direction if required

6. Keep only arrivals travelling toward the destination

7. Remove arrivals travelling in the opposite direction

8. Sort ascending by expectedArrival

9. Return the next 20 arrivals

Direction filtering is mandatory.

Line filtering alone is never sufficient.

If reliable direction matching cannot be established, the service should prefer excluding uncertain arrivals rather than displaying opposite-direction trains.

Showing fewer trains is preferable to showing incorrect trains.

---

# 13.8 Review Schedule Rule

The Review Schedule button shows live trains from the user’s current relevant station, filtered to the direction of the active commute.

It must answer one question:

“Which trains arriving soon are actually going toward my destination?”

Must do

* Use only TfL live arrivals:
    /StopPoint/{stopId}/Arrivals
* Use the correct commute context:
    * inbound: Home → Office
    * outbound: Office → Destination
* Filter arrivals by:
    * matching lineId
    * matching journey direction
* Direction must mainly be based on:
    * destinationName
    * towards
    * terminal station
* Remove trains:
    * with no expectedArrival
    * that already passed
    * going the wrong way
* Sort by soonest arrival
* Show up to 20 trains

Must not do

* Do not recalculate the commute
* Do not use timetable endpoints
* Do not generate fake trains
* Do not rely on lineId alone
* Do not show opposite-direction trains
* Do not mix inbound and outbound schedule state
* Do not put filtering logic inside SwiftUI Views

If direction is unclear

Do not open the schedule, or show an empty/error state.

Correctness matters more than showing lots of trains.

Simple example

If the commute is toward Morden, show:

* Morden
* Morden via Bank
* Morden via Charing Cross
* Battersea Power Station, if relevant

Do not show:

* High Barnet
* Edgware
* Mill Hill East

---

# 13.9 Matching the Active Commute Train

The schedule may visually highlight the train currently used by the active commute calculation.

Matching is optional.

Review Schedule must continue functioning normally even if no matching train is found.

A train may be considered a match when:

- lineId matches the active commute line
- direction matches the active journey direction
- expectedArrival is within ±2 minutes of the calculated boarding train time
- destinationName or towards value is reasonably similar

Matching affects visual presentation only.

It must NOT:

- Recalculate commute results
- Change leave times
- Trigger refresh logic
- Affect caching
- Modify commute state

---

# 13.10 Display Requirements

Each schedule row should display when available:

- Expected arrival time
- Minutes until arrival
- Destination name
- Towards value
- Platform name
- Line name

Rows must be sorted by nearest arriving train first.

If a train matches the active commute train, it may be visually highlighted.

Opposite-direction trains must never be rendered.

Views must display already-filtered schedule state only.

---

# 13.11 Empty & Error States

If no valid arrivals remain after filtering:

Show:

No upcoming trains found in your direction right now.

If the API request fails:

Show:

Couldn’t load current trains. Pull to refresh or try again.

If the user is offline:

Show:

You appear to be offline.

Empty and error states must never affect commute state.

---

# 13.12 Data Isolation Rules

Inbound schedule review must use inbound commute data only.

Outbound schedule review must use outbound commute data only.

Inbound and outbound schedule state must remain fully isolated.

Outbound must never reuse:

- inbound station IDs
- inbound direction filtering
- inbound line filtering
- inbound schedule state

Inbound must never reuse:

- outbound station IDs
- outbound direction filtering
- outbound line filtering
- outbound schedule state

Shared UI components are allowed.

Shared commute filtering state is not allowed.

---

# 13.13 Architecture Rules

All TfL API access must remain inside TFLService.

All schedule filtering, direction logic, destination matching, and train matching logic must remain inside:

- ScheduleReviewService
or
- ScheduleReviewViewModel

Business logic must never exist inside SwiftUI Views.

Views must render computed state only.

No hardcoded train times may exist inside Views.

All displayed times must use:

- user locale
- user timezone
- device calendar settings

---

# 13.14 Non-Negotiable Rules

- Review Schedule must use live arrivals only
- Review Schedule must filter by both line and journey direction
- Line filtering alone is never sufficient
- Opposite-direction trains must never be shown intentionally
- Destination-terminal matching is preferred over simple cardinal direction matching
- Review Schedule must never recalculate commutes
- Review Schedule must never affect active commute results
- Review Schedule must never affect cache state
- Inbound and outbound schedule state must remain isolated
- Views must render computed state only
- TfL integration must remain isolated inside TFLService
- Showing fewer trains is preferable to showing incorrect trains
- Direction correctness has priority over completeness