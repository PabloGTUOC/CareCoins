import { Pressable, Text, StyleSheet } from 'react-native';
import { Colors } from '../theme/colors';

interface Props {
  title: string;
  onPress: () => void;
}

export default function AuthButton({ title, onPress }: Props) {
  return (
    <Pressable
      accessibilityRole="button"
      onPress={onPress}
      style={styles.button}
    >
      <Text style={styles.text}>{title}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  button: {
    backgroundColor: Colors.pink500,
    padding: 12,
    borderRadius: 4,
    marginVertical: 8,
    minWidth: 200,
    alignItems: 'center'
  },
  text: {
    color: Colors.green900,
    fontWeight: 'bold'
  }
});
