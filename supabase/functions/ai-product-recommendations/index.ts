import { createClient } from 'jsr:@supabase/supabase-js@2';
import Anthropic from 'npm:@anthropic-ai/sdk@^0.68.0';

interface Habit {
  type: string;
  quit_date: string;
}

const jsonHeaders = { 'Content-Type': 'application/json' };

const VALID_CATEGORIES = ['nrt', 'herbal', 'fitness', 'mentalHealth'] as const;
const DEFAULT_CATEGORIES = ['herbal', 'mentalHealth'];

function daysSinceQuit(quitDate: string): number {
  return Math.max(0, Math.floor((Date.now() - new Date(quitDate).getTime()) / 86_400_000));
}

function sanitizeCategories(raw: unknown): string[] {
  const valid = Array.isArray(raw)
    ? raw.filter((c): c is string => typeof c === 'string' && VALID_CATEGORIES.includes(c as never))
    : [];
  const deduped = [...new Set(valid)];
  const padded = [...deduped, ...DEFAULT_CATEGORIES.filter((c) => !deduped.includes(c))];
  return padded.slice(0, 2);
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
  const userId = user.id;

  // ── 2. Serve a cached recommendation if one was generated within the last 23 hours ──
  const twentyThreeHoursAgo = new Date(Date.now() - 23 * 60 * 60 * 1000).toISOString();
  const { data: cached, error: cacheError } = await supabase
    .from('ai_product_recommendations')
    .select('categories')
    .eq('user_id', userId)
    .gt('generated_at', twentyThreeHoursAgo)
    .order('generated_at', { ascending: false })
    .limit(1)
    .maybeSingle<{ categories: string[] }>();

  if (cacheError) {
    console.error('Failed to read ai_product_recommendations cache', cacheError);
  } else if (cached) {
    return new Response(JSON.stringify({ categories: cached.categories }), { headers: jsonHeaders });
  }

  // ── 3. Fetch most-recently-created active habit ──
  const { data: habit, error: habitError } = await supabase
    .from('habits')
    .select('type, quit_date')
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

  // ── No active habit yet: skip Claude entirely, return gentle defaults ──
  if (!habit) {
    return new Response(
      JSON.stringify({ categories: DEFAULT_CATEGORIES }),
      { headers: jsonHeaders },
    );
  }

  // ── 4. Call Claude for a stage-appropriate category pair ──
  const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });

  let categories: string[];
  try {
    const response = await anthropic.messages.create({
      model: 'claude-opus-4-8',
      max_tokens: 200,
      output_config: {
        effort: 'low',
        format: {
          type: 'json_schema',
          schema: {
            type: 'object',
            properties: {
              categories: {
                type: 'array',
                items: { type: 'string', enum: VALID_CATEGORIES },
              },
            },
            required: ['categories'],
            additionalProperties: false,
          },
        },
      },
      system:
        'You recommend product categories for a habit-cessation wellness marketplace. ' +
        'Given a habit type and days since quitting, pick exactly 2 of the 4 categories ' +
        '(nrt, herbal, fitness, mentalHealth) most relevant to the user\'s current stage. ' +
        'Guidance: day 1-7 benefits most from nrt for acute cravings, but only when the habit ' +
        'is nicotine-based (e.g. cigarette, gutka) — nrt does not apply to habits like gambling ' +
        'or junk_food, so use herbal or mentalHealth instead for those. The first month benefits ' +
        'from herbal and mentalHealth support for withdrawal and stress. Day 30+ benefits most ' +
        'from fitness as a long-term healthy replacement habit.',
      messages: [{
        role: 'user',
        content: JSON.stringify({ habit_type: habit.type, days_free: daysSinceQuit(habit.quit_date) }),
      }],
    });

    const textBlock = response.content.find((block) => block.type === 'text');
    const parsed = textBlock && textBlock.type === 'text' ? JSON.parse(textBlock.text) : null;
    categories = sanitizeCategories(parsed?.categories);
  } catch (err) {
    console.error('Anthropic API call failed', err);
    return new Response(
      JSON.stringify({
        error: err instanceof Error ? err.message : 'Failed to generate recommendations',
      }),
      { status: 500, headers: jsonHeaders },
    );
  }

  // ── 5. Cache the newly generated recommendation (best-effort) ──
  const { error: insertError } = await supabase
    .from('ai_product_recommendations')
    .insert({ user_id: userId, categories });
  if (insertError) {
    console.error('Failed to cache ai product recommendations', insertError);
  }

  // ── 6. Return ──
  return new Response(JSON.stringify({ categories }), { headers: jsonHeaders });
});
