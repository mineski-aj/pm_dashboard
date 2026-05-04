require('dotenv').config();
const axios = require('axios');
const fs    = require('fs');
const path  = require('path');

const { LARK_APP_ID, LARK_APP_SECRET, LARK_APP_TOKEN, LARK_TABLE_ID } = process.env;

const OUTPUT_PATH = path.join(__dirname, 'data/projects.json');

async function getToken() {
  const res = await axios.post(
    'https://open.larksuite.com/open-apis/auth/v3/tenant_access_token/internal',
    { app_id: LARK_APP_ID, app_secret: LARK_APP_SECRET }
  );
  if (res.data.code !== 0) throw new Error(`Auth failed: ${res.data.msg}`);
  return res.data.tenant_access_token;
}

async function fetchAllRecords(token) {
  const headers = { Authorization: `Bearer ${token}` };
  const baseUrl = `https://open.larksuite.com/open-apis/bitable/v1/apps/${LARK_APP_TOKEN}/tables/${LARK_TABLE_ID}/records`;

  let all = [], pageToken = null;
  do {
    const params = { page_size: 100 };
    if (pageToken) params.page_token = pageToken;
    const res = await axios.get(baseUrl, { headers, params });
    if (res.data.code !== 0) throw new Error(`Fetch failed: ${res.data.msg}`);
    const { items = [], has_more, page_token } = res.data.data;
    all = all.concat(items);
    pageToken = has_more ? page_token : null;
    process.stdout.write(`\r  Fetched ${all.length} records...`);
  } while (pageToken);
  console.log();
  return all;
}

async function sync() {
  console.log('🔄 Syncing Lark Base → projects.json...\n');

  console.log('  [1/2] Authenticating...');
  const token = await getToken();
  console.log('  ✓ Token acquired\n');

  console.log('  [2/2] Fetching records...');
  const records = await fetchAllRecords(token);
  console.log(`  ✓ ${records.length} records fetched\n`);

  fs.mkdirSync(path.dirname(OUTPUT_PATH), { recursive: true });
  fs.writeFileSync(OUTPUT_PATH, JSON.stringify(records, null, 2));
  console.log(`✅ Saved ${records.length} records to ${OUTPUT_PATH}`);
}

sync().catch(err => {
  console.error('\n❌ Error:', err.message);
  process.exit(1);
});
