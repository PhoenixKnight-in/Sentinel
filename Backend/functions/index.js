require("dotenv").config();
const Busboy = require("busboy");
const crypto = require("crypto");
const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

setGlobalOptions({maxInstances: 10});

const MAX_UPLOAD_BYTES = 50 * 1024 * 1024;
const ALLOWED_MIME_PREFIXES = ["image/", "video/"];
const REQUIRED_ENV_VARS = [
  "STORACHA_UCAN_KEY",
  "STORACHA_DELEGATION",
];

let storachaClientPromise;

async function getStorachaClient() {
  if (!storachaClientPromise) {
    storachaClientPromise = (async () => {
      for (const envKey of REQUIRED_ENV_VARS) {
        if (!process.env[envKey]) {
          throw new Error(`Missing required env var: ${envKey}`);
        }
      }

      const Client = await import("@storacha/client");
      const Proof = await import("@storacha/client/proof");
      const Signer = await import("@storacha/client/principal/ed25519");
      const {StoreMemory} = await import("@storacha/client/stores/memory");

      const principal = Signer.parse(process.env.STORACHA_UCAN_KEY);
      const store = new StoreMemory();
      const client = await Client.create({principal, store});

      const proof = await Proof.parse(process.env.STORACHA_DELEGATION);
      const space = await client.addSpace(proof);
      await client.setCurrentSpace(space.did());

      if (process.env.STORACHA_AGENT_DID &&
        principal.did().toString() !== process.env.STORACHA_AGENT_DID) {
        throw new Error("Storacha signer DID does not match STORACHA_AGENT_DID");
      }

      return client;
    })();
  }

  return storachaClientPromise;
}

function timingSafeEquals(left, right) {
  const leftBuffer = Buffer.from(left || "", "utf8");
  const rightBuffer = Buffer.from(right || "", "utf8");
  if (leftBuffer.length !== rightBuffer.length) {
    return false;
  }
  return crypto.timingSafeEqual(leftBuffer, rightBuffer);
}

function authorizeRequest(req) {
  const configuredToken = process.env.SENTINEL_API_TOKEN;
  if (!configuredToken) {
    return true;
  }

  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : "";
  return timingSafeEquals(token, configuredToken);
}

function parseMultipart(req) {
  return new Promise((resolve, reject) => {
    const busboy = Busboy({
      headers: req.headers,
      limits: {
        files: 1,
        fileSize: MAX_UPLOAD_BYTES,
        fields: 10,
      },
    });

    let filename = "";
    let mimeType = "application/octet-stream";
    let fileBuffer = Buffer.alloc(0);
    let fileReceived = false;
    let fileTooLarge = false;

    busboy.on("file", (fieldname, file, info) => {
      if (fieldname !== "file") {
        file.resume();
        return;
      }

      fileReceived = true;
      filename = info.filename || "evidence.enc";
      mimeType = info.mimeType || mimeType;
      const chunks = [];

      file.on("limit", () => {
        fileTooLarge = true;
      });

      file.on("data", (chunk) => {
        chunks.push(chunk);
      });

      file.on("end", () => {
        fileBuffer = Buffer.concat(chunks);
      });
    });

    busboy.on("field", (name, value) => {
      if (name === "filename" && value) {
        filename = value;
      }
      if (name === "mimeType" && value) {
        mimeType = value;
      }
    });

    busboy.on("finish", () => {
      if (!fileReceived) {
        reject(new Error("No file field received."));
        return;
      }
      if (fileTooLarge) {
        reject(new Error("File exceeds maximum allowed size."));
        return;
      }
      resolve({filename, mimeType, fileBuffer});
    });

    busboy.on("error", reject);
    req.pipe(busboy);
  });
}

function isAllowedMimeType(mimeType) {
  return ALLOWED_MIME_PREFIXES.some((prefix) => mimeType.startsWith(prefix)) ||
    mimeType === "application/octet-stream";
}

exports.api = onRequest({cors: false}, async (req, res) => {
  res.set("Cache-Control", "no-store");
  res.set("X-Content-Type-Options", "nosniff");

  if (req.method !== "POST") {
    res.status(405).json({error: "method_not_allowed"});
    return;
  }

  if (!req.headers["content-type"] ||
    !req.headers["content-type"].startsWith("multipart/form-data")) {
    res.status(400).json({error: "invalid_content_type"});
    return;
  }

  if (!authorizeRequest(req)) {
    res.status(401).json({error: "unauthorized"});
    return;
  }

  try {
    const {filename, mimeType, fileBuffer} = await parseMultipart(req);

    if (!isAllowedMimeType(mimeType)) {
      res.status(400).json({error: "unsupported_mime_type"});
      return;
    }

    if (!fileBuffer.length) {
      res.status(400).json({error: "empty_file"});
      return;
    }

    const client = await getStorachaClient();
    const file = new File([fileBuffer], filename, {type: mimeType});
    const cid = await client.uploadFile(file);

    logger.info("Evidence uploaded to Storacha", {
      filename,
      mimeType,
      cid: cid.toString(),
      size: fileBuffer.length,
    });

    res.status(200).json({
      cid: cid.toString(),
      gatewayUrl: `https://${cid}.ipfs.w3s.link`,
    });
  } catch (error) {
    logger.error("Storacha upload failed", error);
    res.status(500).json({error: "upload_failed"});
  }
});
