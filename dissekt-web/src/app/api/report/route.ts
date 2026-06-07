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
    if (error) throw error;
    return NextResponse.json({ success: true, url: `/report/${id}` });
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
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
    if (error || !data) return NextResponse.json({ error: 'Report not found' }, { status: 404 });
    return NextResponse.json(data);
  } catch (e: any) {
    return NextResponse.json({ error: e.message }, { status: 500 });
  }
}
