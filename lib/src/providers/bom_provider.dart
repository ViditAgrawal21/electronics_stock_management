import 'package:flutter_riverpod/flutter_riverpod.dart';

final bomStatusProvider =
    StateNotifierProvider<BomStatusNotifier, Map<String, bool>>((ref) {
      return BomStatusNotifier();
    });

class BomStatusNotifier extends StateNotifier<Map<String, bool>> {
  BomStatusNotifier() : super({});

  void updateBomStatus(String pcbId, bool hasUploadedBom) {
    state = {...state, pcbId: hasUploadedBom};
  }

  bool getBomStatus(String pcbId) {
    return state[pcbId] ?? false;
  }
}
