import { View, Text, StyleSheet, TextInput } from 'react-native';
import { useState } from 'react';
import AuthButton from '../components/AuthButton';
import { Colors } from '../theme/colors';

export default function SignIn() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Sign In</Text>
      <TextInput
        style={styles.input}
        value={email}
        onChangeText={setEmail}
        placeholder="Email"
        keyboardType="email-address"
        autoCapitalize="none"
      />
      <TextInput
        style={styles.input}
        value={password}
        onChangeText={setPassword}
        placeholder="Password"
        secureTextEntry
      />
      <AuthButton title="Sign In" onPress={() => {}} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    padding: 16,
    backgroundColor: Colors.bg
  },
  title: {
    fontSize: 24,
    color: Colors.text,
    marginBottom: 16,
    textAlign: 'center'
  },
  input: {
    borderWidth: 1,
    borderColor: Colors.muted,
    borderRadius: 4,
    padding: 8,
    marginBottom: 12
  }
});
