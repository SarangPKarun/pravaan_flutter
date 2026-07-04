import { createClient } from 'jsr:@supabase/supabase-js@2';

const IST_OFFSET_MS = 5.5 * 60 * 60 * 1000;

interface Habit {
  id: string;
  user_id: string;
  daily_units: number;
  cost_per_unit: number;
}

function targetIstDay(now: Date) {
  const istNow = new Date(now.getTime() + IST_OFFSET_MS);
  // "Yesterday" in IST — the calendar day that just closed when this runs at 00:01 IST.
  const targetDateObj = new Date(
    Date.UTC(istNow.getUTCFullYear(), istNow.getUTCMonth(), istNow.getUTCDate() - 1),
  );
  const targetDateStr = targetDateObj.toISOString().slice(0, 10);
  const dayStartUtc = new Date(targetDateObj.getTime() - IST_OFFSET_MS);
  const dayEndUtc = new Date(dayStartUtc.getTime() + 24 * 60 * 60 * 1000);
  return { targetDateStr, dayStartUtc, dayEndUtc };
}

Deno.serve(async (_req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { targetDateStr, dayStartUtc, dayEndUtc } = targetIstDay(new Date());

  const { data: habits, error: habitsError } = await supabase
    .from('habits')
    .select('id, user_id, daily_units, cost_per_unit')
    .eq('is_active', true)
    .returns<Habit[]>();

  if (habitsError) {
    console.error('Failed to load active habits', habitsError);
    return new Response(
      JSON.stringify({ date: targetDateStr, error: habitsError.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  const activeHabits = habits ?? [];
  if (activeHabits.length === 0) {
    const summary = { date: targetDateStr, habitsChecked: 0, credited: 0, skipped: 0, errors: [] };
    console.log(summary);
    return new Response(JSON.stringify(summary), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const userIds = [...new Set(activeHabits.map((h) => h.user_id))];

  const { data: cleanCheckins, error: checkinsError } = await supabase
    .from('checkins')
    .select('user_id')
    .eq('is_clean', true)
    .gte('date', dayStartUtc.toISOString())
    .lt('date', dayEndUtc.toISOString())
    .in('user_id', userIds)
    .returns<{ user_id: string }[]>();

  if (checkinsError) {
    console.error('Failed to load clean check-ins', checkinsError);
    return new Response(
      JSON.stringify({ date: targetDateStr, error: checkinsError.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }

  const cleanUserIds = new Set((cleanCheckins ?? []).map((c) => c.user_id));
  const eligibleHabits = activeHabits.filter((h) => cleanUserIds.has(h.user_id));

  let credited = 0;
  let skipped = 0;
  const errors: { habitId: string; message: string }[] = [];

  for (const habit of eligibleHabits) {
    const amount = habit.daily_units * habit.cost_per_unit;
    const { data: didCredit, error: creditError } = await supabase.rpc('credit_habit_wallet', {
      p_habit_id: habit.id,
      p_amount: amount,
      p_credit_date: targetDateStr,
    });

    if (creditError) {
      errors.push({ habitId: habit.id, message: creditError.message });
      continue;
    }

    if (didCredit) {
      credited++;
    } else {
      skipped++;
    }
  }

  const summary = {
    date: targetDateStr,
    habitsChecked: activeHabits.length,
    credited,
    skipped,
    errors,
  };
  console.log(summary);

  return new Response(JSON.stringify(summary), {
    headers: { 'Content-Type': 'application/json' },
  });
});
