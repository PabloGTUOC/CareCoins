import type { ExpoConfig } from 'expo/config';

const config: ExpoConfig = {
  name: 'CareCoins',
  slug: 'carecoins',
  scheme: 'carecoins',
  extra: {
    eas: { projectId: 'REPLACE' },
    EXPO_PUBLIC_SUPABASE_URL: 'https://YOUR-PROJECT.supabase.co',
    EXPO_PUBLIC_SUPABASE_ANON_KEY: 'YOUR-ANON-KEY'
  }
};

export default config;
