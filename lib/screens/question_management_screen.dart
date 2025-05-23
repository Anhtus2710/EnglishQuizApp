// Thêm thư viện showDialog
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../models/question_model.dart';

class QuestionManagementScreen extends StatefulWidget {
  const QuestionManagementScreen({super.key});

  @override
  State<QuestionManagementScreen> createState() => _QuestionManagementScreenState();
}

class _QuestionManagementScreenState extends State<QuestionManagementScreen> {
  List<Question> _questions = [];
  bool _isLoading = true;
  String _selectedLevel = 'easy';

  final TextEditingController _contentController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  final TextEditingController _correctAnswerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    try {
      final data = await QuizService.fetchQuestions(_selectedLevel);
      setState(() {
        _questions = data.map((e) => Question.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Lỗi khi tải câu hỏi')),
      );
      setState(() => _isLoading = false);
    }
  }

  void _openDialog({Question? question}) {
    bool isEdit = question != null;
    if (isEdit) {
      _contentController.text = question!.content;
      for (int i = 0; i < 4; i++) {
        _optionControllers[i].text = question.options[i];
      }
      _correctAnswerController.text = question.correctAnswer.toString();
    } else {
      _contentController.clear();
      for (var ctrl in _optionControllers) ctrl.clear();
      _correctAnswerController.clear();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Sửa câu hỏi' : 'Thêm câu hỏi'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: _contentController, decoration: const InputDecoration(labelText: 'Câu hỏi')),
              for (int i = 0; i < 4; i++)
                TextField(
                  controller: _optionControllers[i],
                  decoration: InputDecoration(labelText: 'Đáp án ${i + 1}'),
                ),
              TextField(
                controller: _correctAnswerController,
                decoration: const InputDecoration(labelText: 'Đáp án đúng (0-3)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              final content = _contentController.text.trim();
              final options = _optionControllers.map((e) => e.text.trim()).toList();
              final correctAnswer = int.tryParse(_correctAnswerController.text.trim());

              if (content.isEmpty || options.any((e) => e.isEmpty) || correctAnswer == null || correctAnswer < 0 || correctAnswer > 3) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❗ Vui lòng nhập đầy đủ và chính xác')),
                );
                return;
              }

              final newQuestion = Question(
                id: isEdit ? question!.id : '',
                content: content,
                options: options,
                correctAnswer: correctAnswer,
                level: _selectedLevel,
              );

              if (isEdit) {
                await QuizService.updateQuestion(question!.id, newQuestion.toJson());
              } else {
                await QuizService.createQuestion(newQuestion.toJson());
              }

              Navigator.pop(context);
              _loadQuestions();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // Hiển thị xác nhận trước khi xóa
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa câu hỏi này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await QuizService.deleteQuestion(id);
              _loadQuestions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // Hiển thị xác nhận trước khi sửa
  void _confirmEdit(Question question) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận sửa'),
        content: const Text('Bạn có chắc muốn sửa câu hỏi này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _openDialog(question: question);
            },
            child: const Text('Sửa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý câu hỏi'),
        actions: [
          DropdownButton<String>(
            value: _selectedLevel,
            underline: Container(),
            items: ['easy', 'normal', 'hard']
                .map((level) => DropdownMenuItem(value: level, child: Text(level.toUpperCase())))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedLevel = value!;
                _loadQuestions();
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
          ? const Center(child: Text('Không có câu hỏi nào.'))
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'CÂU HỎI - ${_selectedLevel.toUpperCase()}',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Câu ${index + 1}: ${q.content}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        for (int i = 0; i < q.options.length; i++)
                          Text(
                            '${i + 1}. ${q.options[i]}',
                            style: TextStyle(
                              color: i == q.correctAnswer ? Colors.green : Colors.black,
                              fontWeight: i == q.correctAnswer ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Đáp án đúng: ${q.correctAnswer + 1}',
                              style: const TextStyle(fontStyle: FontStyle.italic),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.orange),
                                  onPressed: () => _confirmEdit(q),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _confirmDelete(q.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
