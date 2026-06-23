import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''
);

// POST: Save a report
export async function POST(req: NextRequest) {
  try {
    const { id, analysis, input_content, mode } = await req.json();
    const { error } = await supabase.from('reports').upsert({
      id,
      analysis,
      input_content: (input_content || '').slice(0, 500),
      mode,
    });
    if (error) { console.error('REPORT SAVE ERROR:', error); return NextResponse.json({ ok: false, stage: 'save', error: error.message, details: error.details, hint: error.hint, code: error.code }, { status: 500 }); }
    return NextResponse.json({ success: true, url: `/report/${id}` });
  } catch (e: any) {
    console.error('REPORT SAVE THREW:', e);
    return NextResponse.json({ ok: false, stage: 'save_throw', error: e.message }, { status: 500 });
  }
}

// GET: Fetch a report
export async function GET(req: NextRequest) {
  const id = req.nextUrl.searchParams.get('id');
  if (!id) return NextResponse.json({ error: 'Missing id' }, { status: 400 });

  try {
    const { data, error } = await supabase
      .from('reports')
      .select('*')
      .eq('id', id)
      .single();
    if (error || !data) { console.error('REPORT READ ERROR:', error); return NextResponse.json({ ok: false, stage: 'read', error: error?.message || 'no row', code: error?.code }, { status: 404 }); }
    return NextResponse.json(data);
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
