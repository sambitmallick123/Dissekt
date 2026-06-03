import { supabase } from './supabase';

export async function getDailyUsage(): Promise<number> {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return 0;
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const { count } = await supabase
    .from('scan_usage')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', user.id)
    .gte('created_at', today.toISOString());
  return count || 0;
}

export async function logScan(data: {
  content_preview: string;
  mode: string;
  threat_score: number;
  techniques_count: number;
  analysis_time_ms: number;
}) {
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return;
  await supabase.from('scan_usage').insert({ user_id: user.id, ...data });
}
