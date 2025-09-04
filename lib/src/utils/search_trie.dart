class TrieNode {
  Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
  List<String> materialIds = []; // Store material IDs that contain this prefix
}

class SearchTrie {
  late TrieNode _root;

  SearchTrie() {
    _root = TrieNode();
  }

  // Insert a material into the trie
  void insert(String materialName, String materialId) {
    TrieNode current = _root;
    String cleanName = materialName.toLowerCase().trim();

    // Insert the full name
    for (int i = 0; i < cleanName.length; i++) {
      String char = cleanName[i];
      current.children[char] ??= TrieNode();
      current = current.children[char]!;
      current.materialIds.add(materialId);
    }
    current.isEndOfWord = true;

    // Also insert individual words for better search
    List<String> words = cleanName.split(RegExp(r'\s+'));
    for (String word in words) {
      if (word.isNotEmpty) {
        _insertWord(word, materialId);
      }
    }
  }

  // Insert individual word
  void _insertWord(String word, String materialId) {
    TrieNode current = _root;
    for (int i = 0; i < word.length; i++) {
      String char = word[i];
      current.children[char] ??= TrieNode();
      current = current.children[char]!;
      if (!current.materialIds.contains(materialId)) {
        current.materialIds.add(materialId);
      }
    }
  }

  // Search for materials with given prefix
  List<String> search(String prefix) {
    if (prefix.isEmpty) return [];

    TrieNode current = _root;
    String cleanPrefix = prefix.toLowerCase().trim();

    // Navigate to the prefix
    for (int i = 0; i < cleanPrefix.length; i++) {
      String char = cleanPrefix[i];
      if (!current.children.containsKey(char)) {
        return []; // Prefix not found
      }
      current = current.children[char]!;
    }

    // Return all material IDs with this prefix
    return List.from(current.materialIds.toSet()); // Remove duplicates
  }

  // Get all suggestions for a prefix (useful for autocomplete)
  List<String> getSuggestions(String prefix, {int maxSuggestions = 10}) {
    List<String> materialIds = search(prefix);
    return materialIds.take(maxSuggestions).toList();
  }

  // Clear all data
  void clear() {
    _root = TrieNode();
  }

  // Remove a material from the trie
  void remove(String materialName, String materialId) {
    String cleanName = materialName.toLowerCase().trim();
    _removeFromTrie(cleanName, materialId);

    // Also remove from individual words
    List<String> words = cleanName.split(RegExp(r'\s+'));
    for (String word in words) {
      if (word.isNotEmpty) {
        _removeFromTrie(word, materialId);
      }
    }
  }

  // Helper method to remove material ID from trie
  void _removeFromTrie(String text, String materialId) {
    TrieNode current = _root;
    List<TrieNode> path = [current];

    // Navigate and build path
    for (int i = 0; i < text.length; i++) {
      String char = text[i];
      if (!current.children.containsKey(char)) {
        return; // Text not found
      }
      current = current.children[char]!;
      path.add(current);
    }

    // Remove material ID from all nodes in path
    for (TrieNode node in path) {
      node.materialIds.remove(materialId);
    }
  }

  // Update material in trie (remove old, insert new)
  void update(String oldName, String newName, String materialId) {
    remove(oldName, materialId);
    insert(newName, materialId);
  }

  // Check if trie contains any materials with given prefix
  bool hasPrefix(String prefix) {
    if (prefix.isEmpty) return true;

    TrieNode current = _root;
    String cleanPrefix = prefix.toLowerCase().trim();

    for (int i = 0; i < cleanPrefix.length; i++) {
      String char = cleanPrefix[i];
      if (!current.children.containsKey(char)) {
        return false;
      }
      current = current.children[char]!;
    }

    return current.materialIds.isNotEmpty;
  }

  // Get total number of unique materials in trie
  int get totalMaterials {
    Set<String> allIds = {};
    _collectAllIds(_root, allIds);
    return allIds.length;
  }

  // Helper method to collect all material IDs
  void _collectAllIds(TrieNode node, Set<String> allIds) {
    allIds.addAll(node.materialIds);
    for (TrieNode child in node.children.values) {
      _collectAllIds(child, allIds);
    }
  }
}
