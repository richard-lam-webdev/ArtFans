import 'package:flutter/foundation.dart';
import '../services/admin_content_service.dart';

enum AdminContentStatus { initial, loading, loaded, error }

class AdminContentProvider extends ChangeNotifier {
  final AdminContentService _service;

  AdminContentProvider({required AdminContentService service})
    : _service = service;

  AdminContentStatus _status = AdminContentStatus.initial;
  List<Map<String, dynamic>> _contents = [];
  String? _errorMessage;

  AdminContentStatus get status => _status;
  List<Map<String, dynamic>> get contents => _contents;
  String? get errorMessage => _errorMessage;

  Future<void> fetchContents() async {
    _status = AdminContentStatus.loading;
    notifyListeners();
    try {
      final list = await _service.fetchContents();
      _contents = list;
      _status = AdminContentStatus.loaded;
      _errorMessage = null;
    } catch (e) {
      _status = AdminContentStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> deleteContent(String id) async {
    _status = AdminContentStatus.loading;
    notifyListeners();
    try {
      await _service.deleteContent(id);
      await fetchContents();
    } catch (e) {
      _status = AdminContentStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> approveContent(String id) async {
    _status = AdminContentStatus.loading;
    notifyListeners();
    try {
      await _service.approveContent(id);
      await fetchContents();
    } catch (e) {
      _status = AdminContentStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }

  Future<void> rejectContent(String id) async {
    _status = AdminContentStatus.loading;
    notifyListeners();
    try {
      await _service.rejectContent(id);
      await fetchContents();
    } catch (e) {
      _status = AdminContentStatus.error;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
    }
  }
}
