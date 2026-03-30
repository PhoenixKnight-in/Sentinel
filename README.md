# Sentinel

Sentinel is a privacy-first emergency reporting system disguised as a
calculator app. The current prototype is Android-first and focused on secure
evidence capture, offline-first persistence, and delayed encrypted upload.

## Current Status

Implemented:
- calculator disguise with hidden unlock flow
- image and video capture
- SHA-256 hashing and chained-hash integrity
- local AES encryption before any upload
- app-private encrypted evidence storage
- local incident ledger with retry status and timestamps
- simulated blockchain trail for demo/reviewer storytelling
- Firebase metadata sync support
- backend-facing Storacha upload client

In progress / external dependency:
- real deployment of the backend Storacha upload endpoint
- production key rotation and incident-specific key derivation
- hardened Firestore rules

## Architecture

### Mobile app
- capture image/video
- generate SHA-256 immediately
- capture timestamp and GPS immediately
- encrypt evidence locally
- save encrypted file + metadata locally first
- queue uploads for retry when online

### Local device storage
- encrypted evidence file path
- evidence type and mime type
- hash, timestamp, GPS, description
- retry count and upload status
- CID after upload succeeds
- previous hash for chain continuity
- simulated block id, block hash, and transaction id

### Backend
- receives encrypted evidence over HTTPS
- validates auth token and payload size/type
- uses Storacha agent key + UCAN delegation from server env
- uploads encrypted evidence to Storacha
- returns CID to the app

### Cloud metadata
- Firestore stores synced incident metadata
- Storacha stores encrypted file content

## Major Code Locations

- `App/lib/main.dart`
- `App/lib/screens/calculator_screen.dart`
- `App/lib/screens/report_screen.dart`
- `App/lib/screens/history_screen.dart`
- `App/lib/models/incident.dart`
- `App/lib/services/encryption_service.dart`
- `App/lib/services/hash_service.dart`
- `App/lib/services/local_evidence_service.dart`
- `App/lib/services/evidence_sync_service.dart`
- `App/lib/services/blockchain_service.dart`
- `App/lib/services/ipfs_service.dart`
- `Backend/functions/index.js`

## Security Notes

- the Flutter app no longer stores Storacha delegation credentials
- backend upload endpoint supports bearer-token auth
- server validates request method, content type, mime family, and size limit
- evidence is encrypted before storage and before upload

No app can honestly guarantee “no way of hacking,” but this prototype now
keeps the most sensitive Storacha credentials off-device and uses a safer
offline-first flow than the earlier direct-client upload design.
