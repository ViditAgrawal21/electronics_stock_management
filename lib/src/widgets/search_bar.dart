import 'package:flutter/material.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final Widget? prefixIcon;
  final List<String>? suggestions;
  final Function(String)? onSuggestionTap;

  const SearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.prefixIcon,
    this.suggestions,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
              prefixIcon:
                  prefixIcon ?? Icon(Icons.search, color: Colors.grey[500]),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[500]),
                      onPressed: () {
                        controller.clear();
                        onClear?.call();
                        onChanged?.call('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),

        // Suggestions dropdown
        if (suggestions != null &&
            suggestions!.isNotEmpty &&
            controller.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions!.length,
              itemBuilder: (context, index) {
                final suggestion = suggestions![index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.search, size: 16),
                  title: Text(suggestion, style: const TextStyle(fontSize: 14)),
                  onTap: () {
                    controller.text = suggestion;
                    onSuggestionTap?.call(suggestion);
                    onChanged?.call(suggestion);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  final List<String> suggestions;
  final Function(String) onSearch;

  CustomSearchDelegate({required this.suggestions, required this.onSearch});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    onSearch(query);
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredSuggestions = suggestions
        .where(
          (suggestion) =>
              suggestion.toLowerCase().contains(query.toLowerCase()),
        )
        .take(10)
        .toList();

    return ListView.builder(
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return ListTile(
          leading: const Icon(Icons.search),
          title: RichText(
            text: TextSpan(
              text: suggestion.substring(
                0,
                suggestion.toLowerCase().indexOf(query.toLowerCase()),
              ),
              style: const TextStyle(color: Colors.black54),
              children: [
                TextSpan(
                  text: query,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: suggestion.substring(
                    suggestion.toLowerCase().indexOf(query.toLowerCase()) +
                        query.length,
                  ),
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }
}
