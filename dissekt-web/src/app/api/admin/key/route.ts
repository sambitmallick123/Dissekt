// Vends DISSEKT_ADMIN_KEY ONLY to a logged-in user whose app_metadata.role === 'admin'.
// Verifies the caller's Supabase access token server-side with the service client.
import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

export async function POST(req: NextRequest) {
  let accessToken = '';
  try {
    const body = await req.json();
    accessToken = body.accessToken || '';
  } catch {
    /* ignore */
  }
  if (!accessToken) return NextResponse.json({ error: 'no token' }, { status: 401 });

  const serviceKey = process.env.SUPABASE_SERVICE_KEY || '';
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
  if (!serviceKey || !url) {
    return NextResponse.json({ error: 'server misconfigured' }, { status: 500 });
  }

  const admin = createClient(url, serviceKey);
  const { data, error } = await admin.auth.getUser(accessToken);
  if (error || !data.user) {
    return NextResponse.json({ error: 'invalid token' }, { status: 401 });
  }

  const role = (data.user.app_metadata as Record<string, unknown>)?.role;
  if (role !== 'admin') {
    return NextResponse.json({ error: 'not admin' }, { status: 403 });
  }

  return NextResponse.json({ adminKey: process.env.DISSEKT_ADMIN_KEY || '' });
}