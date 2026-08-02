# Sentinel 

**A stealth personal safety app that doesn't look like one.**

Sentinel is disguised as a normal calculator utility, letting users seek help discreetly without drawing attention from anyone nearby. Behind the disguise, it runs a distress-detection chatbot, live-location alerting, and an encrypted, tamper-proof evidence and report trail — built for situations where opening an obvious "SOS" app isn't safe.

Built at **WomenTechies**, a hackathon hosted at VIT and organized by the **Google Developer Group (GDG) VIT**.

---

## The Problem

Most personal safety apps are recognizable at a glance — a red panic button, a siren icon, a name like "SafeMe." In an actual threat scenario (stalking, harassment, an unsafe commute), pulling out a visibly-labeled safety app can escalate risk rather than reduce it. Sentinel's core idea: safety tooling should be invisible until the user needs it, and simple to trigger without hesitation once they do.

---

## Key Features

- **Calculator Disguise** — the app opens as a fully functional calculator; the real interface sits behind it.
- **Distress Chatbot** — a quick, conversational flow captures what's happening (incident type, surroundings, whether to raise a silent alert) without requiring the user to fill out a form under pressure.
- **Live Location Alerts** — triggers real-time location sharing to configured contacts/authorities when distress is detected.
- **Smart Safe-Route Finder** — recommends routes based on a weighted threshold score combining street lighting, crowd density, and path length, so a user can choose the *safest* walk home, not just the shortest one. *(This is the module I built — details below.)*
- **Encrypted, Tamper-Proof Storage** — reports and evidence are stored with encryption so records can't be silently altered or deleted after the fact.
- **Report Filing & Status Tracking** — every incident gets a case ID and moves through a visible lifecycle: `Submitted → Under Review → Investigating → Resolved → Closed`, with severity tagging (Low/Medium/High) and a running log of status updates.

---

## My Role — Backend & Safe-Route Algorithm

I worked primarily on the backend logic and the route-safety scoring system:

- **Threshold scoring model** — evaluates candidate routes against multiple weighted factors (street lighting, crowd/foot-traffic density, path distance) and combines them into a single safety threshold score, rather than optimizing for distance alone.
- **Route selection logic** — compares the shortest path against the highest-scoring "safe" path and surfaces both, so the user can make an informed trade-off between speed and safety instead of the app silently picking one.
- **Report data pipeline** — structured incident data (`ReportModel`) for persistence, mapping fields like incident type, coordinates, surroundings, and alert choice into a storage-ready format for the case-tracking system.
- **Report lifecycle backend** — the state model behind the case status tracker (submitted → review → investigating → resolved → closed), including severity classification and status-update history.

---

## Tech Stack

- **Flutter / Dart** — cross-platform app (Android, iOS, plus web/desktop targets in the repo)
- **Cloud data storage** — structured report persistence (Firestore-shaped data model)
- **Custom routing & scoring logic** — safety-weighted route evaluation on top of map/location data

*(Stack details reflect what's in the repo structure — update the storage/maps provider names here if you want the README to name the exact services used, e.g. Firebase, Google Maps Directions API.)*

---

## Project Structure

```
Sentinel/
├── lib/
│   ├── chatbot/              # Distress-detection chatbot flow
│   ├── calculator.dart       # Decoy calculator UI (app's public face)
│   ├── home_page.dart        # Core home screen, shared UI (AppColors, layout helpers)
│   ├── main.dart             # App entry point
│   ├── report_status_page.dart  # Case tracking: filing, lifecycle, status updates
│   └── routes.dart           # App route table + report data model
├── android/ ios/ linux/ macos/ web/ windows/   # Platform targets
├── test/
└── pubspec.yaml
```

---

## Report Lifecycle

Each filed report is tracked through a clear pipeline so users know their case isn't a black box:

`Submitted` → `Under Review` → `Investigating` → `Resolved` → `Closed`

Each report carries:
- A unique case ID (e.g. `TSC-2026-33235`)
- A severity level (Low / Medium / High)
- Location and timestamp (with graceful fallback when location is unavailable, e.g. on web preview)
- A running log of status updates from filing to resolution

---

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run on a connected device / emulator
flutter run
```

Requires Flutter SDK (stable channel) and platform tooling for your target (Android/iOS/desktop/web).

---

## Team

Built by **Aman Golani** and **Parthiban M** at WomenTechies (VIT, organized by GDG VIT).

This was a hackathon build — it didn't place, but it was a strong exercise in shipping a security-conscious, real-world-usable safety product under time pressure.

---

## Roadmap / Future Work

- Wire live crowd-density and lighting data into the route scorer from real map/city data sources rather than static weighting
- Push notification integration for emergency contacts
- Offline-first fallback for distress alerts when connectivity is poor
- Admin-side dashboard for case reviewers to update report status
