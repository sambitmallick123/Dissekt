// src/lib/supabase.ts — browser Supabase client for auth + queries
import { createClient } from '@supabase/supabase-js';

const url = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const anonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

export const supabase = createClient(url, anonKey, {
  auth: {
    persistSession: true,        // keep session across reloads (localStorage)
    autoRefreshToken: true,      // refresh JWT automatically
    detectSessionInUrl: true,    // handle the email-link callback tokens
  },
});
