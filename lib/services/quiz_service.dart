import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:retry/retry.dart';
import 'package:englishquizapp/constants/server_config.dart';
import 'package:englishquizapp/services/auth_service.dart';

class QuizService {
  static const String endpoint = '/questions';

  /// Kiểm tra level có hợp lệ không
  static bool isValidLevel(String level) {
    return ['easy', 'normal', 'hard'].contains(level.toLowerCase());
  }

  /// Lấy danh sách câu hỏi theo level
  static Future<List<Map<String, dynamic>>> fetchQuestions(String level) async {
    if (!isValidLevel(level)) {
      return Future.error('Mức độ không hợp lệ. Chọn easy, normal hoặc hard.');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final token = await AuthService.getToken();
    final String endpoint = '/questions/random'; // ✅ Thêm dòng này

    if (token == null) {
      return Future.error('Vui lòng đăng nhập để lấy câu hỏi.');
    }

    final Uri url = Uri.parse('$baseUrl/api$endpoint?level=$level');

    try {
      final response = await retry(
            () => http.get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      print('Fetch Questions URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        return Future.error('Không được phép: Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 404) {
        return Future.error('Không tìm thấy endpoint. Vui lòng kiểm tra URL.');
      } else if (response.statusCode != 200) {
        return Future.error('Lỗi tải dữ liệu: ${response.statusCode} - ${response.body}');
      }

      if (!response.headers['content-type']!.contains('application/json')) {
        return Future.error('Phản hồi không phải JSON.');
      }

      final data = jsonDecode(response.body);
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else {
        return Future.error('Dữ liệu trả về không đúng định dạng.');
      }
    } catch (e) {
      print('Lỗi kết nối (fetch questions): $e');
      return Future.error('Lỗi kết nối: $e');
    }
  }


  /// Tạo câu hỏi mới
  static Future<void> createQuestion(Map<String, dynamic> data) async {
    if (data['question'] == null || data['answers'] == null || data['correctAnswer'] == null || data['level'] == null) {
      throw Exception('Thiếu thông tin bắt buộc để tạo câu hỏi.');
    }
    if (!isValidLevel(data['level'])) {
      throw Exception('Mức độ không hợp lệ.');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập với tài khoản admin.');
    }

    final Uri url = Uri.parse('$baseUrl/api$endpoint');

    try {
      final response = await retry(
            () => http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        ).timeout(const Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      print('Create Question URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 403) {
        throw Exception('Chỉ admin mới được tạo câu hỏi.');
      } else if (response.statusCode != 201) {
        throw Exception('Tạo câu hỏi thất bại: ${response.statusCode} - ${response.body}');
      }

      if (!response.headers['content-type']!.contains('application/json')) {
        throw Exception('Phản hồi không phải JSON.');
      }

      print('✅ Tạo câu hỏi thành công!');
    } catch (e) {
      print('Lỗi kết nối (create question): $e');
      throw Exception('Lỗi khi tạo câu hỏi: $e');
    }
  }

  /// Cập nhật câu hỏi
  static Future<void> updateQuestion(String id, Map<String, dynamic> data) async {
    if (id.isEmpty) throw Exception('ID không hợp lệ.');
    if (data['question'] == null || data['answers'] == null || data['correctAnswer'] == null || data['level'] == null) {
      throw Exception('Thiếu thông tin bắt buộc.');
    }
    if (!isValidLevel(data['level'])) {
      throw Exception('Mức độ không hợp lệ.');
    }

    final baseUrl = await ServerConfig.getBaseUrl();
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập với tài khoản admin.');
    }

    final Uri url = Uri.parse('$baseUrl/api$endpoint/$id');

    try {
      final response = await retry(
            () => http.put(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(data),
        ).timeout(const Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      print('Update Question URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 403) {
        throw Exception('Chỉ admin mới được cập nhật.');
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy câu hỏi.');
      } else if (response.statusCode != 200) {
        throw Exception('Cập nhật thất bại: ${response.statusCode} - ${response.body}');
      }

      if (!response.headers['content-type']!.contains('application/json')) {
        throw Exception('Phản hồi không phải JSON.');
      }

      print('✅ Cập nhật câu hỏi thành công!');
    } catch (e) {
      print('Lỗi kết nối (update question): $e');
      throw Exception('Lỗi khi cập nhật câu hỏi: $e');
    }
  }

  /// Xóa câu hỏi
  static Future<void> deleteQuestion(String id) async {
    if (id.isEmpty) throw Exception('ID không hợp lệ.');

    final baseUrl = await ServerConfig.getBaseUrl();
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception('Vui lòng đăng nhập với tài khoản admin.');
    }

    final Uri url = Uri.parse('$baseUrl/api$endpoint/$id');

    try {
      final response = await retry(
            () => http.delete(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 10)),
        maxAttempts: 3,
        delayFactor: const Duration(seconds: 1),
      );

      print('Delete Question URL: $url');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 401) {
        throw Exception('Không được phép: Vui lòng đăng nhập lại.');
      } else if (response.statusCode == 403) {
        throw Exception('Chỉ admin mới được xóa.');
      } else if (response.statusCode == 404) {
        throw Exception('Không tìm thấy câu hỏi.');
      } else if (response.statusCode != 200) {
        throw Exception('Xóa thất bại: ${response.statusCode} - ${response.body}');
      }

      if (!response.headers['content-type']!.contains('application/json')) {
        throw Exception('Phản hồi không phải JSON.');
      }

      print('✅ Xóa câu hỏi thành công!');
    } catch (e) {
      print('Lỗi kết nối (delete question): $e');
      throw Exception('Lỗi khi xóa câu hỏi: $e');
    }
  }
}
