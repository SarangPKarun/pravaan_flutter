import { createClient } from 'jsr:@supabase/supabase-js@2';
import Anthropic from 'npm:@anthropic-ai/sdk@^0.68.0';

interface Habit {
  id: string;
  type: string;
  quit_date: string;
}

interface UserStats {
  current_streak: number;
  longest_streak: number;
}

interface GoalWallet {
  goal_name: string;
  target_amount: number;
  current_balance: number;
}

const jsonHeaders = { 'Content-Type': 'application/json' };

function daysSinceQuit(quitDate: string): number {
  return Math.max(0, Math.floor((Date.now() - new Date(quitDate).getTime()) / 86_400_000));
}

Deno.serve(async (req) => {
  // ── 1. Verify caller identity from JWT (never trust body.userId for auth) ──
  const authHeader = req.headers.get('Authorization') ?? '';
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: authError } = await supabase.auth.getUser();
  if (authError || !user) {
    console.error('Auth failed', authError);
    return new Response(JSON.stringify({ error: 'Unauthorized' }), {
      status: 401,
      headers: jsonHeaders,
    });
  }

  // ── 2. Optional defensive cross-check against body.userId ──
  let body: { userId?: string } = {};
  try {
    body = await req.json();
  } catch {
    // empty/absent body is fine — userId is optional
  }
  if (body.userId && body.userId !== user.id) {
    return new Response(
      JSON.stringify({ error: 'userId does not match authenticated user' }),
      { status: 400, headers: jsonHeaders },
    );
  }
  const userId = user.id;
  const fullName = (user.user_metadata?.full_name as string | undefined)?.trim();
  const displayName = fullName && fullName.length > 0 ? fullName : 'there';

  // ── 3. Serve a cached message if one was generated within the last 23 hours ──
  const twentyThreeHoursAgo = new Date(Date.now() - 23 * 60 * 60 * 1000).toISOString();
  const { data: cached, error: cacheError } = await supabase
    .from('ai_messages')
    .select('message')
    .eq('user_id', userId)
    .gt('generated_at', twentyThreeHoursAgo)
    .order('generated_at', { ascending: false })
    .limit(1)
    .maybeSingle<{ message: string }>();

  if (cacheError) {
    console.error('Failed to read ai_messages cache', cacheError);
  } else if (cached) {
    return new Response(JSON.stringify({ message: cached.message }), { headers: jsonHeaders });
  }

  // ── 4. Fetch most-recently-created active habit ──
  const { data: habit, error: habitError } = await supabase
    .from('habits')
    .select('id, type, quit_date')
    .eq('user_id', userId)
    .eq('is_active', true)
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle<Habit>();

  if (habitError) {
    console.error('Failed to load habit', habitError);
    return new Response(JSON.stringify({ error: habitError.message }), {
      status: 500,
      headers: jsonHeaders,
    });
  }

  // ── No active habit yet: skip Claude entirely, return a static welcome message ──
  if (!habit) {
    return new Response(
      JSON.stringify({
        message: `Welcome, ${displayName}! Set up your first habit to start tracking your progress and savings.`,
      }),
      { headers: jsonHeaders },
    );
  }

  // ── 5. Fetch streak stats (zero-default if no row yet) ──
  const { data: stats, error: statsError } = await supabase
    .from('user_stats')
    .select('current_streak, longest_streak')
    .eq('user_id', userId)
    .maybeSingle<UserStats>();

  if (statsError) {
    console.error('Failed to load user_stats', statsError);
    return new Response(JSON.stringify({ error: statsError.message }), {
      status: 500,
      headers: jsonHeaders,
    });
  }

  // ── 6. Fetch the goal wallet for this habit, if any ──
  const { data: wallet, error: walletError } = await supabase
    .from('goal_wallets')
    .select('goal_name, target_amount, current_balance')
    .eq('habit_id', habit.id)
    .maybeSingle<GoalWallet>();

  if (walletError) {
    console.error('Failed to load goal_wallets', walletError);
    return new Response(JSON.stringify({ error: walletError.message }), {
      status: 500,
      headers: jsonHeaders,
    });
  }

  // ── 7. Build structured user context ──
  const currentStreak = stats?.current_streak ?? 0;
  const longestStreak = stats?.longest_streak ?? 0;

  const userContext = {
    name: displayName,
    habit_type: habit.type,
    days_free: daysSinceQuit(habit.quit_date),
    current_streak_days: currentStreak,
    longest_streak_days: longestStreak,
    goal_name: wallet?.goal_name ?? null,
    target_amount: wallet?.target_amount ?? null,
    current_balance: wallet?.current_balance ?? null,
    currency: 'INR',
  };

  // ── 8. Call Claude ──
  const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });

  let message: string;
  try {
    const response = await anthropic.messages.create({
      model: 'claude-sonnet-4-6',
      max_tokens: 200,
      system:
        'You are a compassionate health coach for VitalWallet. Write exactly 2 sentences. ' +
        'Be specific, warm, never generic. Reference real numbers. Never say the word quit. ' +
        'Focus on what they are gaining, not what they are losing.',
      messages: [{ role: 'user', content: JSON.stringify(userContext) }],
    });

    const textBlock = response.content.find((block) => block.type === 'text');
    message = textBlock && textBlock.type === 'text' ? textBlock.text.trim() : '';
    message = message.replace(/^["']+|["']+$/g, '').trim();
    if (!message) throw new Error('Empty response from Claude');
  } catch (err) {
    console.error('Anthropic API call failed', err);
    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : 'Failed to generate message',
      }),
      { status: 500, headers: jsonHeaders },
    );
  }

  // ── 9. Cache the newly generated message (best-effort — failure shouldn't fail the request) ──
  const { error: insertError } = await supabase
    .from('ai_messages')
    .insert({ user_id: userId, message });
  if (insertError) {
    console.error('Failed to cache ai message', insertError);
  }

  // ── 10. Return ──
  return new Response(JSON.stringify({ message }), { headers: jsonHeaders });
});
