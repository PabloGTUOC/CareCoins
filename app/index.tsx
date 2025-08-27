import { Link } from 'expo-router';
import { View, Text, StyleSheet } from 'react-native';
import AuthButton from '../components/AuthButton';
import { Colors } from '../theme/colors';

export default function Landing() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>CareCoins</Text>
      <AuthButton title="Continue with Google" onPress={() => {}} />
      <Link href="/sign-in" style={styles.link}>
        Sign in with Email
      </Link>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: Colors.bg,
    padding: 16
  },
  title: {
    fontSize: 32,
    color: Colors.text,
    marginBottom: 24
  },
  link: {
    color: Colors.green700,
    marginTop: 8,
    textDecorationLine: 'underline'
  }
});
