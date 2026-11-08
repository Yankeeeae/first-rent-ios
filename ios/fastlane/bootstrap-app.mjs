import { createSign } from "node:crypto";
import { readFileSync } from "node:fs";

const BUNDLE_ID = "com.firstrent.app";
const APP_NAME = "FIRST RENT";
const SKU = "firstrent-app";
const KEY_ID = process.env.APP_STORE_CONNECT_KEY_ID;
const ISSUER = process.env.APP_STORE_CONNECT_ISSUER_ID;
const KEY_PATH = process.env.APP_STORE_CONNECT_API_KEY_PATH;

function jwtToken() {
  const header = Buffer.from(JSON.stringify({ alg: "ES256", kid: KEY_ID, typ: "JWT" })).toString("base64url");
  const now = Math.floor(Date.now() / 1000);
  const payload = Buffer.from(JSON.stringify({
    iss: ISSUER,
    iat: now,
    exp: now + 19 * 60,
    aud: "appstoreconnect-v1"
  })).toString("base64url");
  const unsigned = `${header}.${payload}`;
  const signer = createSign("SHA256");
  signer.update(unsigned);
  signer.end();
  const sig = signer.sign({ key: readFileSync(KEY_PATH, "utf8"), dsaEncoding: "ieee-p1363" }).toString("base64url");
  return `${unsigned}.${sig}`;
}

const token = jwtToken();

async function api(method, path, body) {
  const res = await fetch(`https://api.appstoreconnect.apple.com/v1/${path}`, {
    method,
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/json",
      "Content-Type": "application/json"
    },
    body: body ? JSON.stringify(body) : undefined
  });
  const text = await res.text();
  let json = null;
  try { json = JSON.parse(text); } catch { json = { raw: text.slice(0, 500) }; }
  console.log(`${method} ${path} → ${res.status}`);
  if (!res.ok) console.log(JSON.stringify(json.errors || json, null, 2).slice(0, 2500));
  return { ok: res.ok, status: res.status, json };
}

function alreadyExists(json) {
  return (json?.errors || []).some((error) => {
    const detail = String(error.detail || error.title || error.code || "").toLowerCase();
    return detail.includes("already") || detail.includes("exists") || detail.includes("duplicate");
  });
}

let bundle = (await api("GET", `bundleIds?filter[identifier]=${encodeURIComponent(BUNDLE_ID)}&limit=10`)).json?.data?.find((row) => row.attributes?.identifier === BUNDLE_ID);
if (!bundle) {
  const created = await api("POST", "bundleIds", {
    data: { type: "bundleIds", attributes: { identifier: BUNDLE_ID, name: "FIRSTRENT", platform: "IOS" } }
  });
  bundle = created.json?.data;
}
if (!bundle?.id) {
  console.error("Bundle ID missing");
  process.exit(1);
}
console.log(`Bundle ${BUNDLE_ID} id=${bundle.id}`);

const existing = await api("GET", `apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=5`);
if (!existing.json?.data?.[0]?.id) {
  const createdApp = await api("POST", "apps", {
    data: { type: "apps", attributes: { bundleId: BUNDLE_ID, name: APP_NAME, primaryLocale: "fr-FR", sku: SKU } }
  });
  if (!createdApp.ok && !alreadyExists(createdApp.json)) process.exit(1);
}
const check = await api("GET", `apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=5`);
if (!check.json?.data?.[0]?.id) process.exit(1);
console.log(`FIRST RENT app id=${check.json.data[0].id}`);
