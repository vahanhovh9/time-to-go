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
