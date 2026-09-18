import { createRemoteJWKSet, jwtVerify } from "jose";
import pg from "pg";

const { Pool } = pg;
const ROLE_CLAIM = "https://runway90.app/roles";
const MAX_IMAGE_BYTES = 7_000_000;

let pool;
let schemaPromise;
let jwks;

function auth0Issuer() {
  const domain = (process.env.AUTH0_DOMAIN || "").replace(/^https?:\/\//, "").replace(/\/$/, "");
  return domain ? `https://${domain}/` : null;
}

function auth0Keys() {
  if (!jwks) {
    const issuer = auth0Issuer();
    if (!issuer) throw new Error("AUTH0_DOMAIN is not configured.");
    jwks = createRemoteJWKSet(new URL(`${issuer}.well-known/jwks.json`));
  }
  return jwks;
}

function json(res, status, value) {
  res.status(status).setHeader("Content-Type", "application/json").json(value);
}

function noContent(res) {
  res.status(204).end();
}

function fail(res, error) {
  console.error("Runway 90 API error:", error?.message || error);
  json(res, error?.statusCode || 500, {
    error: error?.publicMessage || "Internal server error."
  });
}

function publicError(message, statusCode = 500) {
  const error = new Error(message);
  error.publicMessage = message;
  error.statusCode = statusCode;
  return error;
}

async function body(req) {
  if (req.body && typeof req.body === "object") return req.body;
  if (typeof req.body === "string") return JSON.parse(req.body || "{}");

  const chunks = [];
  for await (const chunk of req) chunks.push(Buffer.from(chunk));
  const raw = Buffer.concat(chunks).toString("utf8");
  return raw ? JSON.parse(raw) : {};
}

async function claimsFor(req, res) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) {
    json(res, 401, { error: "A bearer token is required." });
    return null;
  }

  try {
    const issuer = auth0Issuer();
    const audience = process.env.AUTH0_AUDIENCE;
    if (!issuer || !audience) throw publicError("Auth0 API validation is not configured.");
    const verified = await jwtVerify(token, auth0Keys(), { issuer, audience });
    if (!verified.payload.sub) throw publicError("The Auth0 token has no subject.", 401);
    return verified.payload;
  } catch (error) {
    const authError = error?.statusCode ? error : publicError("The Auth0 token is invalid or expired.", 401);
    fail(res, authError);
    return null;
  }
}

function isAdvocate(claims) {
  const roles = claims?.[ROLE_CLAIM];
  return Array.isArray(roles) && roles.includes("advocate");
}

async function database() {
  if (!process.env.TIGER_DATA_URL) {
    throw publicError("Tiger Data is not configured on the backend.");
  }

  if (!pool) {
    pool = new Pool({
      connectionString: process.env.TIGER_DATA_URL,
      max: 3,
      idleTimeoutMillis: 5_000,
      connectionTimeoutMillis: 10_000,
      ssl: { rejectUnauthorized: false }
    });
  }

  if (!schemaPromise) {
    schemaPromise = ensureSchema(pool).catch(error => {
      schemaPromise = undefined;
      throw error;
    });
  }
  await schemaPromise;
  return pool;
}

async function ensureSchema(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS case_snapshots (
      owner_id text PRIMARY KEY,
      case_id text NOT NULL,
      updated_at timestamptz NOT NULL,
      payload jsonb NOT NULL
    );
  `);
  await client.query(`
    CREATE TABLE IF NOT EXISTS events (
      id text NOT NULL,
      case_id text NOT NULL,
      type text NOT NULL,
      timestamp timestamptz NOT NULL,
      payload jsonb NOT NULL
    );
  `);
  await client.query(`
    CREATE TABLE IF NOT EXISTS backboard_assistants (
      owner_id text PRIMARY KEY,
      assistant_id text NOT NULL,
      updated_at timestamptz NOT NULL DEFAULT now()
    );
  `);
}

function normalizeState(rawState, subject) {
  if (!rawState || typeof rawState !== "object" || !rawState.user || !rawState.caseRecord) {
    throw publicError("A complete case state is required.", 400);
  }

  const state = JSON.parse(JSON.stringify(rawState));
  state.user.id = subject;
  state.user.role = "survivor";
  state.caseRecord.userId = subject;
  state.caseRecord.id ||= `${subject}-case`;
  return state;
}

async function saveCase(subject, rawState) {
  const state = normalizeState(rawState, subject);
  const db = await database();
  await db.query(
    `INSERT INTO case_snapshots (owner_id, case_id, updated_at, payload)
     VALUES ($1, $2, now(), $3::jsonb)
     ON CONFLICT (owner_id) DO UPDATE SET
       case_id = EXCLUDED.case_id,
       updated_at = EXCLUDED.updated_at,
       payload = EXCLUDED.payload`,
    [subject, state.caseRecord.id, JSON.stringify(state)]
  );
  return state;
}

async function loadCase(subject) {
  const db = await database();
  const result = await db.query(
    "SELECT payload FROM case_snapshots WHERE owner_id = $1 LIMIT 1",
    [subject]
  );
  return result.rows[0]?.payload || null;
}

async function saveEvent(subject, event) {
  if (!event?.id || !event?.caseId || !event?.type) {
    throw publicError("A valid timeline event is required.", 400);
  }

  const db = await database();
  const snapshot = await db.query(
    "SELECT case_id FROM case_snapshots WHERE owner_id = $1 LIMIT 1",
    [subject]
  );
  if (!snapshot.rows[0] || snapshot.rows[0].case_id !== event.caseId) {
    throw publicError("That case does not belong to the authenticated user.", 403);
  }

  const existing = await db.query(
    "SELECT 1 FROM events WHERE id = $1 AND case_id = $2 LIMIT 1",
    [event.id, event.caseId]
  );
  if (existing.rows[0]) return;

  await db.query(
    `INSERT INTO events (id, case_id, type, timestamp, payload)
     VALUES ($1, $2, $3, $4, $5::jsonb)`,
    [event.id, event.caseId, event.type, event.timestamp || new Date(), JSON.stringify(event.payload || {})]
  );
}

async function deleteCase(subject) {
  const db = await database();
  const client = await db.connect();
  try {
    await client.query("BEGIN");
    const snapshot = await client.query(
      "SELECT case_id FROM case_snapshots WHERE owner_id = $1 LIMIT 1",
      [subject]
    );
    const caseID = snapshot.rows[0]?.case_id;
    if (caseID) await client.query("DELETE FROM events WHERE case_id = $1", [caseID]);
    await client.query("DELETE FROM case_snapshots WHERE owner_id = $1", [subject]);
    await client.query("DELETE FROM backboard_assistants WHERE owner_id = $1", [subject]);
    await client.query("COMMIT");
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}

async function extractWithGemini(input) {
  if (!process.env.GEMINI_API_KEY) throw publicError("Gemini is not configured on the backend.");
  if (!input?.imageBase64 || input.imageBase64.length > MAX_IMAGE_BYTES * 1.4) {
    throw publicError("A valid document image is required.", 400);
  }

  const model = process.env.GEMINI_MODEL || "gemini-3.6-flash";
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(process.env.GEMINI_API_KEY)}`;
  const prompt = `Extract the financial facts from this collection letter image. Respond with JSON only, matching exactly this schema: {"documentType":"collection_letter","facts":[{"counterparty":string,"accountLast4":string,"amount":number,"openedDate":"YYYY-MM","reviewStatus":"unconfirmed"}]}. Never label anything as fraud. reviewStatus is always "unconfirmed".`;
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [
        { text: prompt },
        { inline_data: { mime_type: input.mimeType || "image/jpeg", data: input.imageBase64 } }
      ] }],
      generationConfig: { response_mime_type: "application/json" }
    })
  });
  if (!response.ok) throw publicError("Gemini extraction failed.", 502);

  const envelope = await response.json();
  const text = envelope?.candidates?.[0]?.content?.parts?.map(part => part.text || "").join("");
  if (!text) throw publicError("Gemini returned no extraction.", 502);
  return JSON.parse(text.replace(/^```json\s*|\s*```$/g, ""));
}

async function syncBackboard(subject, state) {
  if (!process.env.BACKBOARD_API_KEY) throw publicError("Backboard is not configured on the backend.");
  const base = (process.env.BACKBOARD_BASE_URL || "https://app.backboard.io/api").replace(/\/$/, "");
  const headers = {
    "Content-Type": "application/json",
    "X-API-Key": process.env.BACKBOARD_API_KEY
  };
  const db = await database();
  const existing = await db.query("SELECT assistant_id FROM backboard_assistants WHERE owner_id = $1", [subject]);
  let assistantID = existing.rows[0]?.assistant_id;

  if (!assistantID) {
    const response = await fetch(`${base}/assistants`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        name: `runway90-${subject}`,
        instructions: "You store case memory for a synthetic demo. Remember only the case facts provided by the authenticated user."
      })
    });
    if (!response.ok) throw publicError("Backboard assistant creation failed.", 502);
    const created = await response.json();
    assistantID = created.assistant_id || created.id;
    if (!assistantID) throw publicError("Backboard returned no assistant ID.", 502);
    await db.query(
      `INSERT INTO backboard_assistants (owner_id, assistant_id)
       VALUES ($1, $2) ON CONFLICT (owner_id) DO UPDATE SET assistant_id = EXCLUDED.assistant_id, updated_at = now()`,
      [subject, assistantID]
    );
  }

  const memoryText = (state.memory || []).map(item => `${item.key}: ${item.value}`).join("\n");
  const response = await fetch(`${base}/threads/messages`, {
    method: "POST",
    headers,
    body: JSON.stringify({
      assistant_id: assistantID,
      content: `Case memory update for ${state.caseRecord.id} (synthetic demo data):\n${memoryText}`,
      memory: "auto"
    })
  });
  if (!response.ok) throw publicError("Backboard memory sync failed.", 502);
}

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Headers", "Authorization, Content-Type");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
  if (req.method === "OPTIONS") return noContent(res);

  const rawPath = req.query?.path;
  const route = (Array.isArray(rawPath) ? rawPath.join("/") : String(rawPath || "")).replace(/^\/+|\/+$/g, "");

  try {
    if (req.method === "GET" && route === "health") {
      return json(res, 200, { ok: true, service: "runway90-api" });
    }

    const claims = await claimsFor(req, res);
    if (!claims) return;
    const subject = claims.sub;

    if (req.method === "GET" && route === "me") {
      return json(res, 200, { subject, roles: claims[ROLE_CLAIM] || [] });
    }

    if (route === "case" && req.method === "GET") {
      const state = await loadCase(subject);
      return state ? json(res, 200, state) : noContent(res);
    }

    if (route === "case" && req.method === "PUT") {
      const saved = await saveCase(subject, (await body(req)).state);
      return json(res, 200, { ok: true, caseID: saved.caseRecord.id });
    }

    if (route === "case" && req.method === "DELETE") {
      await deleteCase(subject);
      return noContent(res);
    }

    if (route === "events" && req.method === "POST") {
      await saveEvent(subject, (await body(req)).event);
      return json(res, 200, { ok: true });
    }

    if (route === "extract" && req.method === "POST") {
      const result = await extractWithGemini(await body(req));
      return json(res, 200, { result, isLive: true });
    }

    if (route === "memory" && req.method === "POST") {
      await syncBackboard(subject, (await body(req)).state);
      return json(res, 200, { ok: true });
    }

    return json(res, 404, { error: "Route not found." });
  } catch (error) {
    return fail(res, error);
  }
}
