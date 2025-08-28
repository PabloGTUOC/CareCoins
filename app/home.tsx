import { View, Text, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';

export default function Home() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Dashboard</Text>
      <Text style={styles.text}>Coins summary will appear here.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: Colors.bg
  },
  title: {
    fontSize: 24,
    color: Colors.text,
    marginBottom: 12
  },
  text: {
    color: Colors.muted
  }
});
