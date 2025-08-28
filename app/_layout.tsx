import { Stack } from 'expo-router';
import { Colors } from '../theme/colors';

export default function Layout() {
  return (
    <Stack
      screenOptions={{
        headerStyle: { backgroundColor: Colors.pink300 },
        headerTintColor: Colors.green900
      }}
    />
  );
}
