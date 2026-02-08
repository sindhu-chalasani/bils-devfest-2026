# bils — MVP Plan (Demo-Ready)

Date: 2026-02-07

This doc defines a demo-ready MVP for **bils** focused on:
- A realistic *core user flow* (transactions → split → history)
- A *simulated notification system* for:
  1) “Payment detected” notifications
  2) “Incoming split request” notifications

The goal is: **a reliable demo with no backend required** (yet), while keeping the architecture aligned with an eventual launch.

---

## 1) MVP Goals (What the demo should prove)

### Product story
1. User opens bils and sees recent card transactions (dummy data OK).
2. User taps a transaction → chooses friends → chooses split method → sends request.
3. User sees split requests in history (unresolved/resolved).
4. Notifications simulate:
   - Payment detected: “Split this bill?”
   - Incoming request: “Alex requested $X from you”

### Non-goals (explicitly deferred)
- Real card syncing (Plaid, Apple Card, etc.)
- Real push notifications between devices via APNs/FCM
- User authentication and accounts
- Contact book sync

---

## 2) Current Code Baseline (what already exists)

### Screens
- Home screen UI: Views/HomeView.swift
- Split screen: Views/SplitView.swift
- History list (payments list today): Views/HistoryView.swift
- Demo buttons: Views/SettingsView.swift
- Navigation + tabs: Views/ContentView.swift

### Models / Stores
- Payment + category + status: Models/Payment.swift
- PaymentStore (in-memory): Models/PaymentStore.swift
- Preset friends (dummy contacts): Models/Preset.swift

### Notifications
- Local notifications + interactive actions: Services/NotificationService.swift
- Delegate wired via AppDelegate.swift
- Action routing via ContentView.onReceive

**Already implemented demo scheduling:**
- `scheduleDemoNotificationA()`
- `scheduleDemoNotificationB()`

These currently simulate “payment detected” by creating a Payment and scheduling a local notification that routes into SplitView.

---

## 3) MVP User Flow (final behavior)

### A) Home (Transactions)
**MVP behavior**
- Show a list of transactions (dummy OK).
- Tapping a transaction routes to Split for that specific payment.

**Implementation notes**
- Prefer using `PaymentStore.shared.payments` as the source-of-truth.
- If the UI is mock-only, still create a corresponding Payment and store it so SplitView can load the correct `paymentID`.

### B) Split a transaction
**MVP behavior**
- Select friends (from preset list).
- Choose split method:
  - Split evenly
  - Custom amounts
- Tap “Send” → creates split request entries + marks request “sent”.

**MVP output**
- A split request (or set of requests) should appear in Split History.

### C) Split History (Requests)
**MVP behavior**
- A list of past split requests.
- Segmented control: Resolved / Unresolved.
- Per row: who, amount owed, merchant, timestamp.
- Optional: tap row → request detail.

---

## 4) Notification Simulation (MVP)

### 4.1 Payment detected (local notification)
**What it simulates**
- “We detected a new card payment. Do you want to split it?”

**How we simulate**
- Add a Payment to PaymentStore
- Schedule a local notification with `userInfo["paymentID"] = payment.id.uuidString`
- Tap notification routes into SplitView

**Where it lives**
- Services/NotificationService.swift
- Triggered manually via SettingsView buttons

**Demo script**
1. Open Settings tab.
2. Tap “Send Demo Notification 1”.
3. Notification banner appears.
4. Tap it → app opens SplitView for that payment.

### 4.2 Incoming split request (local notification)
**What it simulates**
- Another person requesting money from you.

**MVP approach (no backend, reliable demo)**
- Device A (payer) and Device B (receiver) both run the app.
- On Device B, you press a button: “Simulate Incoming Request”.
  - This schedules a local notification like:
    - Title: “Split request from Alex”
    - Body: “Alex requested $5.44 for Raising Cane’s Chicken Fingers”
  - Tapping routes to a *Split Request Detail* screen or *Split History* focused view.

**Why this is the best MVP choice**
- Works offline.
- Works with device locked/backgrounded.
- No APNs / Firebase setup needed.

**Optional ‘wow’ upgrade (still MVP-ish)**
- If both devices stay in the foreground: use a lightweight realtime sync (Firestore) to show request appearing automatically.
  - Still not true push if the receiver is backgrounded.

---

## 5) Data Model Additions (needed for Split History)

Right now Payment has a `splitStatus`, but **Split History needs request objects**.

### Proposed models
1) `SplitRequest`
- `id: UUID`
- `paymentID: UUID`
- `createdAt: Date`
- `note: String?`
- `participants: [SplitParticipant]`
- `status: SplitRequestStatus` (unresolved/resolved/canceled)

2) `SplitParticipant`
- `presetID: UUID`
- `nameSnapshot: String` (so it still displays if presets change)
- `amountOwed: Double`
- `status: SplitParticipantStatus` (requested/paid)

3) Store
- `SplitRequestStore: ObservableObject` (in-memory first)

---

## 6) Screens to Add (minimum)

1) Split History screen (requests)
- Replace or supplement the current HistoryView (which is payments-only).

2) Split Request Detail screen
- Shows:
  - Merchant + total
  - Participant owed amount
  - Status
  - “Mark as resolved”
  - “Remind” (simulated local notification)

3) Settings (already present)
- Add buttons for:
  - Payment detected notification A/B (already present)
  - Incoming split request 1/2 (to be added)

---

## 7) Implementation Plan (step-by-step)

### Phase 1 — Navigation + Home tap → Split
- Ensure each transaction on Home is backed by a real Payment with a stable `paymentID`.
- Make rows tappable and route to SplitView.

### Phase 2 — SplitRequest model + store
- Add new model files under Models/:
  - SplitRequest.swift
  - SplitRequestStore.swift

### Phase 3 — Create split requests on “Send”
- On SplitView “Send”, create SplitRequest entries in SplitRequestStore.

### Phase 4 — Split History UI
- Implement requests list with Resolved/Unresolved toggle.
- Add navigation to detail screen.

### Phase 5 — Notification simulation
- Add NotificationService methods:
  - `scheduleIncomingSplitRequestDemoA()`
  - `scheduleIncomingSplitRequestDemoB()`
- Add Settings buttons to trigger them.
- Tap notification routes into:
  - Split request detail OR filtered history

---

## 8) Two-Device Demo Guidance

### Reliable two-device demo (recommended)
- Run bils on 2 devices/simulators.
- Device A:
  - Trigger “payment detected” → tap it → send split.
- Device B:
  - Trigger “incoming request” → tap it → open request detail/history.

This is **staged** but looks like the real workflow and is extremely stable.

### If you want true cross-device communication later
- Add accounts + device tokens + backend + APNs (or Firebase).
- That’s a separate milestone after the MVP.

---

## 9) Launch-Oriented Enhancements (after MVP)

- Persistence (SwiftData/CoreData) for Payments and SplitRequests
- Real friend identity (accounts) + phone/email linking
- Real cross-device notifications (APNs/FCM)
- Real transaction ingestion (Plaid, issuer APIs)
- Security + privacy: opt-in contact access, data retention, encryption
- Edge cases: partial payments, rounding rules, refunds

---

## 10) Acceptance Checklist (MVP done when)

- Home shows transactions and tapping one opens Split.
- Split allows selecting friends and even/custom splits.
- Sending creates split request(s) and shows up in Split History.
- Settings can trigger:
  - Payment detected notification A/B
  - Incoming request notification A/B
- Tapping either notification routes to the correct in-app screen.
