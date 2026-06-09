import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

export async function POST(req: NextRequest) {
  try {
    const { analysis_id, technique_name, vote, comment } = await req.json();
    if (!analysis_id || !technique_name || !vote) {
      return NextResponse.json({ error: 'Missing fields' }, { status: 400 });
    }
    const { error } = await supabase.from('corrections').insert({
      analysis_id, technique_name, vote, comment,
    });
    if (error) throw error;
    return NextResponse.json({ success: true });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
