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
