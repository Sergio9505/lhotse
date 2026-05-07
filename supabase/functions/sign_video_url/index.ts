import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

// Only Bunny Stream pull-zone hostnames that belong to this project are allowed.
const ALLOWED_BUNNY_HOSTS = ['vz-44710bc5-f88.b-cdn.net'];

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const jsonHeaders = { ...corsHeaders, 'Content-Type': 'application/json' };

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: jsonHeaders,
    });
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: jsonHeaders,
    });
  }

  let body: { url?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid JSON' }), {
      status: 400,
      headers: jsonHeaders,
    });
  }

  const rawUrl = body.url;
  if (!rawUrl) {
    return new Response(JSON.stringify({ error: 'Missing url' }), {
      status: 400,
      headers: jsonHeaders,
    });
  }

  let parsed: URL;
  try {
    parsed = new URL(rawUrl);
  } catch {
    return new Response(JSON.stringify({ error: 'Invalid URL' }), {
      status: 400,
      headers: jsonHeaders,
    });
  }

  if (!ALLOWED_BUNNY_HOSTS.includes(parsed.hostname)) {
    return new Response(JSON.stringify({ error: 'Host not allowed' }), {
      status: 400,
      headers: jsonHeaders,
    });
  }

  const securityKey = Deno.env.get('BUNNY_SECURITY_KEY');
  if (!securityKey) {
    return new Response(JSON.stringify({ error: 'Server misconfigured' }), {
      status: 500,
      headers: jsonHeaders,
    });
  }

  const path = parsed.pathname;
  const expires = Math.floor(Date.now() / 1000) + 3600;

  const encoder = new TextEncoder();
  const hashInput = encoder.encode(`${securityKey}${path}${expires}`);
  const hashBuffer = await crypto.subtle.digest('SHA-256', hashInput);

  // Base64URL-encode without padding: RFC 4648 §5
  const bytes = new Uint8Array(hashBuffer);
  const base64 = btoa(String.fromCharCode(...bytes));
  const token = base64
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');

  const signedUrl = `${parsed.origin}${path}?token=${token}&expires=${expires}`;

  return new Response(JSON.stringify({ url: signedUrl }), {
    status: 200,
    headers: jsonHeaders,
  });
});
