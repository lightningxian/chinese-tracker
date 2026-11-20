final Map<String, String> _memory = {};

String? read(String key) => _memory[key];
void write(String key, String value) => _memory[key] = value;
void remove(String key) => _memory.remove(key);
