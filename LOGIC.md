# **TimeToGo — Logic Specification**

## **1. Purpose**

TimeToGo is a proactive commute agent.

The app calculates the exact time a user must leave home in order to arrive at their office desk at a preferred time.

The user completes onboarding once.

After that, the app automatically calculates commute timing and sends notifications without requiring the user to open external map apps.

---

## **2. Core Architecture Principles**

- Business logic must NOT live inside SwiftUI Views.
- All commute calculation logic must live inside a dedicated service (e.g., CommuteCalculationService).
- UI reads computed state only.
- TFL API integration must be isolated inside a TFLService.

Pattern: MVVM

---

## **3. Stored User Data**

Persisted after onboarding:

```
userHomeLine: String
userHomeStation: String
userWalkingTimeToStation: Int (minutes)

userOfficeLine: String
userOfficeStation: String
userWalkingTimeToOffice: Int (minutes)

userArrivalTime: Date (time-only component)
notificationDays: [Weekday]
notificationTime: Date (time-only component)
```

---

## **4. Onboarding Logic**

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

### **Step 4 — Notification**

- Store notification trigger time

---

## **5. Completion Logic**

When onboarding completes:

1. Calculate next notification date:
    - Based on selected weekdays
    - Must be the closest future matching weekday
2. Combine:
    - nextNotificationWeekday
    - notificationTime
3. Display formatted result:
    
    Example: “Tuesday 3rd March at 7:30 AM”
    

---

## **6. Main Page Logic**

### **Small Text**

Determine relative phrasing:

If next notification day == tomorrow →

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

## **11. Notification & Background Execution Logic**



11. Notification & Background Execution Logic

11.1 Purpose

Notifications are the primary delivery mechanism of TimeToGo.

The system must:
	•	Deliver accurate commute information when possible.
	•	Never send stale or potentially misleading leave times.
	•	Degrade gracefully if background execution fails.

Trust and accuracy take priority over autonomy.

⸻

11.2 Permission Handling

During onboarding completion:
	•	Request notification permission using UNUserNotificationCenter.
	•	If denied:
	•	Show a non-blocking explanation.
	•	Provide guidance to enable notifications in Settings.
	•	The app must remain stable even if permission is denied.

Notifications are required for full agent functionality.

⸻

11.3 Scheduling Strategy

After onboarding completion:
	1.	Schedule repeating weekly placeholder notifications using:
	•	notificationDays
	•	notificationTime
	2.	Register and schedule background refresh using BGTaskScheduler.
	3.	Background task must:
	•	Execute before notification time (earliestBeginDate set well in advance, e.g. ~2 hours earlier).
	•	Recalculate commute.
	•	Update cache.
	•	Replace today’s placeholder notification with a one-shot notification containing real commute data.
	•	Reschedule itself.

Background refresh is opportunistic and not guaranteed.

⸻

11.4 Background Refresh Flow

When the background task executes:
	1.	Load user settings.
	2.	Recalculate commute using CommuteCalculationService(forceRefresh: true).
	3.	Save result to CommuteCacheManager.
	4.	Replace today’s repeating notification with a one-shot notification containing:
	•	leaveHomeTime
	•	line service status
	5.	Schedule next background refresh task.

⸻

11.5 Trust-First Notification Policy

At notification time:

Case A — Fresh Same-Day Cache Exists

If a valid cached commute result exists for the same commute day:

Send notification:

Leave home at 8:24 AM. Northern line service is good.

When tapped:
	•	Open main screen.
	•	Display the exact cached result.
	•	Do NOT automatically recalculate.

⸻

Case B — No Fresh Cache Exists

If background refresh did not run or failed:

Send notification:

Open TimeToGo to calculate your commute.

When tapped:
	•	Open main screen.
	•	Force immediate commute recalculation.

The system must NEVER send stale leave times.

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
	•	It must NOT be used for notification content.
	•	It may optionally be displayed inside the app with a clear staleness indicator.

⸻

11.7 Consistency Rule

If a notification delivers a leave time:
	•	That exact value must be marked as the active commute result.
	•	When user opens the app during the same commute day:
	•	The app must display the same leave time.
	•	No automatic recalculation.
	•	Recalculation is allowed only if:
	•	User manually refreshes.
	•	Date changes.
	•	Settings change.

⸻

11.8 Deep Linking Behavior

All notifications must include payload:

{
  "action": "openMain"
}

When a notification is tapped:
	1.	Open the main screen.
	2.	If active same-day cache exists → display it.
	3.	If no active cache exists → trigger forced recalculation immediately.

⸻

11.9 Rescheduling Rule

If user updates:
	•	Arrival time
	•	Notification time
	•	Notification days
	•	Home or office station
	•	Walking durations

Then:
	•	Cancel all scheduled notifications.
	•	Cancel all pending background tasks.
	•	Reschedule notifications and background refresh.

⸻

11.10 iOS Constraints Acknowledgment

The system must account for the following:
	•	Background tasks are opportunistic and not guaranteed.
	•	Low Power Mode may suppress background execution.
	•	Force-quit prevents background scheduling.
	•	Placeholder notification ensures delivery even if refresh fails.
	•	Trust-first policy prevents incorrect commute times from being sent.

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

* Always available after initial onboarding.
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

* Start outbound onboarding.

⸻

12.4 Outbound Onboarding

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

Ask:

When should we notify you?

Store:

outboundNotificationTime: Date
outboundNotificationDays: [Weekday]

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

Step 4 — Notification

outboundNotificationTime: Date
outboundNotificationDays: [Weekday]

⸻

12.7 Stored Data

outboundEnabled: Bool
outboundDestinationType: OutboundDestinationType
// home | otherPlace
outboundDestinationLine: String
outboundDestinationStation: String
outboundWalkingTimeFromStation: Int
outboundArrivalTime: Date
outboundNotificationDays: [Weekday]
outboundNotificationTime: Date

⸻

12.8 Completion Logic

On outbound onboarding completion:

1. Save all outbound data
2. Set:

outboundEnabled = true

3. Calculate next notification date
4. Schedule outbound notifications
5. Schedule outbound background refresh
6. Show success screen:

Outbound is ready.
We’ll tell you when to leave work.

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

12.10 Notification & Background Logic (Outbound)

Outbound follows the same trust-first notification policy as inbound.

Scheduling

* Schedule repeating weekly placeholder notifications using:
    * outboundNotificationDays
    * outboundNotificationTime
* Register background refresh task:
    * Runs before notification time
    * Recalculates outbound commute
    * Updates outbound cache
    * Replaces placeholder with one-shot notification

⸻

Notification Behavior

Case A — Fresh Cache Exists

Send:

Leave work at 5:12 PM. Central line service is good.

On tap:

* Open main screen
* Show cached outbound result
* Do NOT recalculate

⸻

Case B — No Fresh Cache

Send:

Open TimeToGo to calculate your commute.

On tap:

* Open main screen
* Force outbound recalculation

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
Outbound notification days
Outbound notification time
Outbound walking time
Reset outbound
Disable outbound

If outbound disabled:

* Hide outbound settings
* Cancel outbound notifications
* Cancel outbound background tasks

⸻

12.13 Non-Negotiable Rules

* Outbound must never affect inbound logic
* Arrival must never be later than outboundArrivalTime
* Outbound cache must be separate from inbound cache
* Notifications must never send stale leave times
* Outbound must follow trust-first policy
* Updating outbound settings must reschedule outbound only
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
- Affect notifications
- Affect cache state
- Trigger background refresh
- Change leave times
- Modify onboarding data
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
- Affect notifications
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
- Review Schedule must never affect notifications
- Review Schedule must never affect cache state
- Review Schedule must never trigger background tasks
- Inbound and outbound schedule state must remain isolated
- Views must render computed state only
- TfL integration must remain isolated inside TFLService
- Showing fewer trains is preferable to showing incorrect trains
- Direction correctness has priority over completeness