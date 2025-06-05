import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:robot_ai/services/navigation_service.dart';

class MapStorageService {
  static final MapStorageService _instance = MapStorageService._internal();
  factory MapStorageService() => _instance;
  MapStorageService._internal();

  static const String _mapsKey = 'saved_maps';
  static const String _mapNamesKey = 'map_names';

  /// Lưu bản đồ vào localStorage
  Future<bool> saveMap(MapData mapData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Lấy danh sách maps hiện có
      final savedMaps = await getSavedMaps();
      
      // Kiểm tra trùng tên
      final existingIndex = savedMaps.indexWhere((map) => map.name == mapData.name);
      
      if (existingIndex >= 0) {
        // Cập nhật map cũ
        savedMaps[existingIndex] = mapData;
      } else {
        // Thêm map mới
        savedMaps.add(mapData);
      }
      
      // Lưu lại toàn bộ danh sách
      final mapsJson = savedMaps.map((map) => map.toJson()).toList();
      final success = await prefs.setString(_mapsKey, json.encode(mapsJson));
      
      // Cập nhật danh sách tên maps
      final mapNames = savedMaps.map((map) => map.name).toList();
      await prefs.setStringList(_mapNamesKey, mapNames);
      
      return success;
    } catch (e) {
      print('Lỗi lưu bản đồ: $e');
      return false;
    }
  }

  /// Lấy tất cả bản đồ đã lưu
  Future<List<MapData>> getSavedMaps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapsString = prefs.getString(_mapsKey);
      
      if (mapsString == null || mapsString.isEmpty) {
        return [];
      }
      
      final mapsJson = json.decode(mapsString) as List;
      return mapsJson.map((mapJson) => MapData.fromJson(mapJson)).toList();
    } catch (e) {
      print('Lỗi đọc bản đồ: $e');
      return [];
    }
  }

  /// Lấy danh sách tên các bản đồ đã lưu
  Future<List<String>> getMapNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_mapNamesKey) ?? [];
    } catch (e) {
      print('Lỗi đọc tên bản đồ: $e');
      return [];
    }
  }

  /// Lấy một bản đồ cụ thể theo tên
  Future<MapData?> getMapByName(String name) async {
    try {
      final savedMaps = await getSavedMaps();
      return savedMaps.firstWhere(
        (map) => map.name == name,
        orElse: () => throw Exception('Map not found'),
      );
    } catch (e) {
      print('Không tìm thấy bản đồ: $name');
      return null;
    }
  }

  /// Xóa một bản đồ
  Future<bool> deleteMap(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMaps = await getSavedMaps();
      
      // Xóa map khỏi danh sách
      savedMaps.removeWhere((map) => map.name == name);
      
      // Lưu lại
      final mapsJson = savedMaps.map((map) => map.toJson()).toList();
      final success = await prefs.setString(_mapsKey, json.encode(mapsJson));
      
      // Cập nhật danh sách tên
      final mapNames = savedMaps.map((map) => map.name).toList();
      await prefs.setStringList(_mapNamesKey, mapNames);
      
      return success;
    } catch (e) {
      print('Lỗi xóa bản đồ: $e');
      return false;
    }
  }

  /// Xóa tất cả bản đồ
  Future<bool> clearAllMaps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mapsKey);
      await prefs.remove(_mapNamesKey);
      return true;
    } catch (e) {
      print('Lỗi xóa tất cả bản đồ: $e');
      return false;
    }
  }

  /// Kiểm tra xem tên bản đồ đã tồn tại chưa
  Future<bool> mapExists(String name) async {
    final mapNames = await getMapNames();
    return mapNames.contains(name);
  }

  /// Export bản đồ thành JSON string (để backup)
  Future<String?> exportMapAsJson(String mapName) async {
    try {
      final mapData = await getMapByName(mapName);
      if (mapData == null) return null;
      
      return json.encode(mapData.toJson());
    } catch (e) {
      print('Lỗi export bản đồ: $e');
      return null;
    }
  }

  /// Import bản đồ từ JSON string
  Future<bool> importMapFromJson(String jsonString) async {
    try {
      final mapJson = json.decode(jsonString);
      final mapData = MapData.fromJson(mapJson);
      return await saveMap(mapData);
    } catch (e) {
      print('Lỗi import bản đồ: $e');
      return false;
    }
  }
} 