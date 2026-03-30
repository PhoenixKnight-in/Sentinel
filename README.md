```md
# Sentinel

Sentinel is a privacy-first emergency reporting system disguised as a calculator app. It is built as an Android-first Flutter application for capturing sensitive evidence and preserving its integrity.

## Project Purpose

Sentinel is designed to let a user:

- Hide the reporting system behind a normal-looking calculator interface
- Capture image evidence quickly
- Generate SHA-256 hashes for tamper-evident integrity
- Encrypt evidence before upload
- Store metadata for incidents
- Review previously submitted incidents
- Operate in constrained environments

## Current Project Status

The project is currently in a **working prototype / review stage**.

### What is already implemented

- Calculator disguise UI
- Hidden unlock flow using secret code
- Image capture from camera
- Image selection from gallery
- SHA-256 hashing of evidence
- Chained hashing using previous incident hash
- AES encryption before upload
- IPFS upload service integration
- Firebase Firestore metadata storage
- GPS tagging
- Incident history screen
- Hash-chain verification in history view
- Android Firebase configuration
- Renaming from `safecalc` to `sentinal`

### What is not fully complete yet

- Full persistent offline local storage of evidence
- Secure production-grade key management
- Production Firestore security rules
- Full iOS Firebase configuration
- Video evidence flow
- Production-safe secret handling for upload credentials

## Current Architecture

### Frontend
- Flutter
- Android-first

### Backend / Metadata
- Firebase Firestore

### Storage
- Currently: encrypted evidence uploaded to IPFS
- Current discussion direction: possible migration to MongoDB for media storage

### Security Flow
1. Capture image
2. Read image bytes
3. Generate SHA-256 hash
4. Fetch previous incident hash
5. Generate chained hash
6. Encrypt image bytes
7. Upload encrypted file
8. Store metadata in Firestore

## Important Note About Current Storage

Right now, the app does **not** persist evidence locally in secure app storage.

Current behavior:
- Image bytes are temporarily kept in memory
- Encrypted image is uploaded to IPFS
- Metadata is stored in Firestore

This means:
- The actual file is not permanently stored by the app on-device yet
- Durable offline evidence retention is still a future improvement

## Major Folder Structure

### Root folders

- `App/`  
  Main Flutter mobile application

- `Backend/`  
  Firebase configuration, Firestore rules, and backend-related setup

- `BlockChain/`  
  Currently empty / reserved for future work

- `Docs/`  
  Currently empty / reserved for documentation

## Major Code Locations

### Main App Entry
- `App/lib/main.dart`

### Screens
- `App/lib/screens/calculator_screen.dart`  
  Calculator disguise and hidden unlock flow

- `App/lib/screens/report_screen.dart`  
  Evidence capture, hash generation, encryption, upload, and metadata submission

- `App/lib/screens/history_screen.dart`  
  Incident history listing and hash-chain verification

### Models
- `App/lib/models/incident.dart`  
  Incident data model used for Firestore records

### Services
- `App/lib/services/hash_service.dart`  
  SHA-256 hashing and chained hash generation

- `App/lib/services/encryption_service.dart`  
  AES encryption and decryption logic

- `App/lib/services/ipfs_service.dart`  
  Upload logic for encrypted evidence

- `App/lib/services/firestore_service.dart`  
  Firestore read/write operations for incidents

- `App/lib/services/location_service.dart`  
  GPS/location collection logic

### Firebase / Android Configuration
- `App/lib/firebase_options.dart`  
  Flutter Firebase platform config

- `App/android/app/google-services.json`  
  Android Firebase native config

- `App/android/app/build.gradle.kts`  
  Android app build config

- `App/android/settings.gradle.kts`  
  Android project plugin config

### Backend Firebase Configuration
- `Backend/firebase.json`
- `Backend/firestore.rules`
- `Backend/firestore.indexes.json`

## File/Module Status

### `App/lib/main.dart`
Status: Implemented  
Purpose:
- Initializes Firebase
- Locks app to portrait mode
- Launches the app
- Shows calculator as entry point

### `App/lib/screens/calculator_screen.dart`
Status: Implemented  
Purpose:
- Fully working calculator UI
- Hidden access point to secure reporting system
- Secret unlock flow
- Hidden access to history

### `App/lib/screens/report_screen.dart`
Status: Implemented for image flow  
Purpose:
- Capture image from camera or gallery
- Generate SHA-256 hash
- Get previous incident hash
- Encrypt image bytes
- Upload encrypted bytes
- Save metadata

### `App/lib/screens/history_screen.dart`
Status: Implemented  
Purpose:
- Show all incidents
- Show CID, hash, location, timestamp, status
- Verify hash chain consistency

### `App/lib/models/incident.dart`
Status: Implemented  
Purpose:
- Defines incident structure for metadata storage

### `App/lib/services/hash_service.dart`
Status: Implemented  
Purpose:
- Generate SHA-256 hash
- Verify hash
- Generate chained hash

### `App/lib/services/encryption_service.dart`
Status: Implemented  
Purpose:
- Encrypt evidence before upload
- Support later decryption
- Integrity verification after decryption

### `App/lib/services/ipfs_service.dart`
Status: Implemented, prototype-level  
Purpose:
- Upload encrypted evidence to IPFS
- Return CID
- Generate public gateway URL

### `App/lib/services/firestore_service.dart`
Status: Implemented  
Purpose:
- Save incidents
- Fetch latest incident
- Fetch all incidents
- Update incident status

### `App/lib/services/location_service.dart`
Status: Implemented  
Purpose:
- Request location permission
- Fetch current GPS coordinates
- Fail gracefully if unavailable

### `Backend/firestore.rules`
Status: Temporary / development-only  
Purpose:
- Current rules are open-development style
- Needs production hardening

### `Backend/functions/index.js`
Status: Scaffold only  
Purpose:
- Placeholder Firebase Functions setup
- Not actively used in current app flow

## Current Android Firebase Status

Completed:
- `google-services.json` added
- Firebase plugin added to Gradle
- `firebase_options.dart` generated
- `main.dart` updated to initialize Firebase with platform options

Current Android package:
- `com.example.sentinal`

Firebase project:
- `sentinel102932`

## Renaming Status

The project was previously using the name `safecalc`.

Updated to:
- `sentinal`

This rename was applied to:
- Flutter package name
- Android package id
- visible app labels
- platform project names
- imports and configuration references

## Known Limitations

- No durable secure local file persistence yet
- Encryption key is still app-level, not user-derived
- IPFS credentials are prototype-level and not production-safe
- Firestore security rules are not hardened yet
- Only Android Firebase path is fully wired
- Video support not implemented yet

## Suggested Next Steps

- Implement secure local encrypted evidence storage
- Add upload retry / offline queue
- Replace prototype secret handling with safer config strategy
- Harden Firestore security rules
- Decide final storage strategy:
  - continue with IPFS, or
  - move media storage to MongoDB/GridFS/object storage
- Add video flow if required

## Short Reviewer Summary

Sentinel is a disguised calculator app that unlocks into a privacy-first reporting system. It currently supports image capture, SHA-256 integrity hashing, chained incident hashes, AES encryption, encrypted upload to IPFS, and Firestore metadata storage. The UI and core reporting flow are implemented, while production hardening and offline local persistence are still in progress.
```