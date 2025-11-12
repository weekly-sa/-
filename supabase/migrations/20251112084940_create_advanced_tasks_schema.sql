/*
  # Create Advanced Tasks Schema

  1. New Tables
    - `advanced_tasks`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key to auth.users)
      - `title` (text)
      - `description` (text)
      - `frequency` (text) - 'daily', 'weekly', 'monthly', 'yearly'
      - `start_date` (date)
      - `end_date` (date, optional)
      - `duration_minutes` (integer) - المدة الزمنية بالدقائق
      - `reminders` (json array) - {time: '08:00', type: 'notification'}
      - `created_at` (timestamp)
      - `updated_at` (timestamp)
    
    - `task_reminders`
      - `id` (uuid, primary key)
      - `task_id` (uuid, foreign key)
      - `reminder_time` (text) - Time in HH:MM format
      - `reminder_type` (text) - 'notification', 'email'
      - `is_active` (boolean)
      - `created_at` (timestamp)
    
    - `weekly_progress`
      - `id` (uuid, primary key)
      - `user_id` (uuid, foreign key)
      - `week_number` (integer)
      - `year` (integer)
      - `completed_tasks` (integer)
      - `total_tasks` (integer)
      - `completion_rate` (decimal)
      - `created_at` (timestamp)

  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated users to manage their own data
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'advanced_tasks'
  ) THEN
    CREATE TABLE advanced_tasks (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      title text NOT NULL,
      description text,
      frequency text DEFAULT 'daily',
      start_date date NOT NULL,
      end_date date,
      duration_minutes integer DEFAULT 0,
      reminders jsonb DEFAULT '[]'::jsonb,
      created_at timestamptz DEFAULT now(),
      updated_at timestamptz DEFAULT now()
    );

    ALTER TABLE advanced_tasks ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "Users can manage their own advanced tasks"
      ON advanced_tasks
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'task_reminders'
  ) THEN
    CREATE TABLE task_reminders (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      task_id uuid NOT NULL REFERENCES advanced_tasks(id) ON DELETE CASCADE,
      reminder_time text NOT NULL,
      reminder_type text DEFAULT 'notification',
      is_active boolean DEFAULT true,
      created_at timestamptz DEFAULT now()
    );

    ALTER TABLE task_reminders ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "Users can manage reminders for their tasks"
      ON task_reminders
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM advanced_tasks 
          WHERE advanced_tasks.id = task_reminders.task_id 
          AND advanced_tasks.user_id = auth.uid()
        )
      );

    CREATE POLICY "Users can insert reminders for their tasks"
      ON task_reminders
      FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM advanced_tasks 
          WHERE advanced_tasks.id = task_reminders.task_id 
          AND advanced_tasks.user_id = auth.uid()
        )
      );

    CREATE POLICY "Users can delete reminders for their tasks"
      ON task_reminders
      FOR DELETE
      USING (
        EXISTS (
          SELECT 1 FROM advanced_tasks 
          WHERE advanced_tasks.id = task_reminders.task_id 
          AND advanced_tasks.user_id = auth.uid()
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'weekly_progress'
  ) THEN
    CREATE TABLE weekly_progress (
      id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
      user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
      week_number integer NOT NULL,
      year integer NOT NULL,
      completed_tasks integer DEFAULT 0,
      total_tasks integer DEFAULT 0,
      completion_rate decimal(5,2) DEFAULT 0,
      created_at timestamptz DEFAULT now(),
      UNIQUE(user_id, week_number, year)
    );

    ALTER TABLE weekly_progress ENABLE ROW LEVEL SECURITY;

    CREATE POLICY "Users can view their own weekly progress"
      ON weekly_progress
      FOR SELECT
      USING (auth.uid() = user_id);

    CREATE POLICY "Users can insert their own weekly progress"
      ON weekly_progress
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);

    CREATE POLICY "Users can update their own weekly progress"
      ON weekly_progress
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;