import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://ugbhzggjxvsfsxxzlcaq.supabase.co';
const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVnYmh6Z2dqeHZzZnN4eHpsY2FxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI0NTk3NTAsImV4cCI6MjA3ODAzNTc1MH0.m6ht8GEZxVAQM1lKPnWWO6QQsaJgGrPYROpjQnk6RGA';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);