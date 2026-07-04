import { createClient } from 'jsr:@supabase/supabase-js@2';
import { initializeApp, cert } from 'npm:firebase-admin@12/app';
import { getMessaging, type Message } from 'npm:firebase-admin@12/messaging';

const STALE_CUTOFF_MS = 48 * 60 * 60 * 1000;
const FCM_BATCH_SIZE = 500;

interface CachedMessage {
  user_id: string;
  message: string;
}

interface DeviceTokenRow {
  user_id: string;
  token: string;
}

const serviceAccount = JSON.parse(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON')!);
const firebaseApp = initializeApp({ credential: cert(serviceAccount) });
const messaging = getMessaging(firebaseApp);

const jsonHeaders = { 'Content-Type': 'application/json' };

Deno.serve(async (_req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const cutoff = new Date(Date.now() - STALE_CUTOFF_MS).toISOString();

  // ── 1. Latest cached AI message per user, within the freshness window ──
  const { data: messages, error: messagesError } = await supabase
    .from('ai_messages')
    .select('user_id, message')
    .gt('generated_at', cutoff)
    .order('generated_at', { ascending: false })
    .returns<CachedMessage[]>();

  if (messagesError) {
    console.error('Failed to load ai_messages', messagesError);
    return new Response(JSON.stringify({ error: messagesError.message }), {
      status: 500,
      headers: jsonHeaders,
    });
  }

  // Rows are newest-first, so the first time we see a user_id is their latest.
  const latestMessageByUser = new Map<string, string>();
  for (const row of messages ?? []) {
    if (!latestMessageByUser.has(row.user_id)) {
      latestMessageByUser.set(row.user_id, row.message);
    }
  }

  if (latestMessageByUser.size === 0) {
    const summary = { usersTargeted: 0, notificationsSent: 0, tokensPruned: 0, errors: [] };
    console.log(summary);
    return new Response(JSON.stringify(summary), { headers: jsonHeaders });
  }

  // ── 2. Device tokens for exactly those users ──
  const { data: tokenRows, error: tokensError } = await supabase
    .from('device_tokens')
    .select('user_id, token')
    .in('user_id', [...latestMessageByUser.keys()])
    .returns<DeviceTokenRow[]>();

  if (tokensError) {
    console.error('Failed to load device_tokens', tokensError);
    return new Response(JSON.stringify({ error: tokensError.message }), {
      status: 500,
      headers: jsonHeaders,
    });
  }

  const fcmMessages: Message[] = (tokenRows ?? []).map((row) => ({
    token: row.token,
    notification: {
      title: 'Good morning! ☀️',
      body: latestMessageByUser.get(row.user_id)!,
    },
  }));

  // ── 3. Send in batches of 500 (FCM per-call limit) ──
  let notificationsSent = 0;
  const staleTokens: string[] = [];
  const errors: { token: string; message: string }[] = [];

  for (let i = 0; i < fcmMessages.length; i += FCM_BATCH_SIZE) {
    const batch = fcmMessages.slice(i, i + FCM_BATCH_SIZE);
    const result = await messaging.sendEach(batch);
    result.responses.forEach((res, idx) => {
      const token = batch[idx].token as string;
      if (res.success) {
        notificationsSent++;
        return;
      }
      const code = res.error?.code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        staleTokens.push(token);
      } else {
        errors.push({ token, message: res.error?.message ?? 'unknown error' });
      }
    });
  }

  // ── 4. Prune dead tokens ──
  if (staleTokens.length > 0) {
    const { error: pruneError } = await supabase
      .from('device_tokens')
      .delete()
      .in('token', staleTokens);
    if (pruneError) console.error('Failed to prune stale tokens', pruneError);
  }

  const summary = {
    usersTargeted: latestMessageByUser.size,
    notificationsSent,
    tokensPruned: staleTokens.length,
    errors,
  };
  console.log(summary);

  return new Response(JSON.stringify(summary), { headers: jsonHeaders });
});
