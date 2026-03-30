# Sentinel Storacha Backend Architecture

## Goal

Use Storacha properly without embedding long-lived agent keys, UCAN signing
material, or delegations in the Flutter client.

## Recommended Design

### Mobile app responsibilities

- Capture image or video
- Generate SHA-256 hash locally
- Generate chained hash using previous incident hash
- Encrypt the raw bytes locally
- Send encrypted bytes to Sentinel backend over HTTPS
- Store only returned CID + metadata in Firestore

### Backend responsibilities

- Hold Storacha agent private key securely
- Hold UCAN delegation/proof securely
- Reconstruct the Storacha agent
- Select the correct Space
- Upload encrypted evidence to Storacha
- Return CID and optional gateway URL to the client
- Optionally enforce auth, rate limiting, and audit logging

## Why This Is Safer

- Flutter APKs can be reverse engineered
- Embedded Storacha credentials can be extracted
- UCAN delegations should be treated as capabilities, not public config
- Backend-controlled uploads let you rotate and revoke credentials centrally

## Recommended Backend Endpoint

`POST /api/v1/evidence/upload`

Multipart form fields:
- `file`
- `filename`
- `mimeType`

Suggested JSON response:

```json
{
  "cid": "bafy...",
  "gatewayUrl": "https://bafy....ipfs.w3s.link"
}
```

Suggested error response:

```json
{
  "error": "upload_failed"
}
```

## Suggested Metadata Record

Store this in Firestore or MongoDB:

- `incidentId`
- `cid`
- `sha256Hash`
- `previousHash`
- `timestamp`
- `latitude`
- `longitude`
- `description`
- `status`
- `evidenceType`
- `mimeType`
- `encrypted`

## Future Hardening

- Add app authentication before upload
- Add request signing or short-lived upload tokens
- Add offline encrypted local queue
- Rotate Storacha delegations regularly
- Add server-side audit logs

## Reviewer Summary

Sentinel now treats Storacha as backend-owned infrastructure. The mobile app
never carries Storacha agent keys or UCAN delegation secrets. It hashes and
encrypts evidence locally, then sends only the encrypted payload to a backend
that uploads it to Storacha and returns the CID for metadata storage.
