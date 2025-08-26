/// A Trie data structure for efficient search functionality
/// Used for searching materials, devices, and components in the inventory system
class TrieNode {
  Map<String, TrieNode> children = {};
  bool isEndOfWord = false;
  List<String> suggestions = [];
  
  TrieNode();
}

class SearchTrie {
  final TrieNode root = TrieNode();
  
  /// Insert a word into the trie
  void insert(String word) {
    if (word.isEmpty) return;
    
    TrieNode current = root;
    String lowerWord = word.toLowerCase().trim();
    
    for (int i = 0; i < lowerWord.length; i++) {
      String char = lowerWord[i];
      
      if (!current.children.containsKey(char)) {
        current.children[char] = TrieNode();
      }
      
      current = current.children[char]!;
      // Add the original word to suggestions at each level
      if (!current.suggestions.contains(word)) {
        current.suggestions.add(word);
      }
    }
    
    current.isEndOfWord = true;
  }
  
  /// Search for words with the given prefix
  List<String> search(String prefix) {
    if (prefix.isEmpty) return [];
    
    TrieNode current = root;
    String lowerPrefix = prefix.toLowerCase().trim();
    
    // Navigate to the node representing the prefix
    for (int i = 0; i < lowerPrefix.length; i++) {
      String char = lowerPrefix[i];
      
      if (!current.children.containsKey(char)) {
        return []; // Prefix not found
      }
      
      current = current.children[char]!;
    }
    
    // Return suggestions from this node
    return current.suggestions;
  }
  
  /// Check if a word exists in the trie
  bool contains(String word) {
    if (word.isEmpty) return false;
    
    TrieNode current = root;
    String lowerWord = word.toLowerCase().trim();
    
    for (int i = 0; i < lowerWord.length; i++) {
      String char = lowerWord[i];
      
      if (!current.children.containsKey(char)) {
        return false;
      }
      
      current = current.children[char]!;
    }
    
    return current.isEndOfWord;
  }
  
  /// Remove a word from the trie
  bool remove(String word) {
    if (word.isEmpty) return false;
    
    return _removeHelper(root, word.toLowerCase().trim(), 0, word);
  }
  
  bool _removeHelper(TrieNode node, String word, int index, String originalWord) {
    if (index == word.length) {
      // We've reached the end of the word
      if (!node.isEndOfWord) return false;
      
      node.isEndOfWord = false;
      node.suggestions.remove(originalWord);
      
      // Return true if node has no children and is not end of another word
      return node.children.isEmpty;
    }
    
    String char = word[index];
    TrieNode childNode = node.children[char]!;
    
    if (!node.children.containsKey(char)) {
      return false;
    }
    
    bool shouldDeleteChild = _removeHelper(childNode, word, index + 1, originalWord);
    
    if (shouldDeleteChild) {
      node.children.remove(char);
      // Return true if current node has no children and is not end of word
      return node.children.isEmpty && !node.isEndOfWord;
    }
    
    // Remove the original word from suggestions
    node.suggestions.remove(originalWord);
    
    return false;
  }
  
  /// Clear all data from the trie
  void clear() {
    root.children.clear();
    root.suggestions.clear();
    root.isEndOfWord = false;
  }
  
  /// Get all words stored in the trie
  List<String> getAllWords() {
    List<String> words = [];
    _getAllWordsHelper(root, '', words);
    return words;
  }
  
  void _getAllWordsHelper(TrieNode node, String prefix, List<String> words) {
    if (node.isEndOfWord) {
      words.addAll(node.suggestions);
    }
    
    for (String char in node.children.keys) {
      _getAllWordsHelper(node.children[char]!, prefix + char, words);
    }
  }
  
  /// Get suggestions with a limit
  List<String> searchWithLimit(String prefix, int limit) {
    List<String> results = search(prefix);
    return results.take(limit).toList();
  }
  
  /// Search for fuzzy matches (simple implementation)
  List<String> fuzzySearch(String query, {int maxDistance = 1}) {
    if (query.isEmpty) return [];
    
    List<String> allWords = getAllWords();
    List<String> fuzzyMatches = [];
    
    for (String word in allWords) {
      if (_calculateLevenshteinDistance(query.toLowerCase(), word.toLowerCase()) <= maxDistance) {
        fuzzyMatches.add(word);
      }
    }
    
    return fuzzyMatches;
  }
  
  /// Calculate Levenshtein distance for fuzzy matching
  int _calculateLevenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );
    
    // Initialize first row and column
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    // Fill the matrix
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = (s1[i - 1] == s2[j - 1]) ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }
  
  /// Get the size of the trie (number of unique words)
  int get size {
    return getAllWords().toSet().length;
  }
  
  /// Check if the trie is empty
  bool get isEmpty {
    return root.children.isEmpty;
  }
}