import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'review_screen.dart';

class QuizScreen extends StatefulWidget {
  final String level;
  final int timeLimitSeconds;

  const QuizScreen({super.key, required this.level, required this.timeLimitSeconds});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<dynamic> questions = [];
  Map<int, int> userAnswers = {};
  Map<int, int> timeTaken = {};
  Map<int, int> questionStartTimes = {};
  int currentIndex = 0;
  bool isLoading = true;
  bool isSubmitting = false;

  final String fetchUrl = 'http://192.168.1.105:3000/api/questions/random?level=';
  final String submitUrl = 'http://192.168.2.15:3000/api/test/submit';

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  Future<void> fetchQuestions() async {
    setState(() => isLoading = true);
    try {
      final res = await http.get(Uri.parse('$fetchUrl${widget.level}'));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data is List && data.isNotEmpty) {
          questions = data;
          questionStartTimes[0] = DateTime.now().millisecondsSinceEpoch;
        }
      } else {
        throw Exception('Lỗi tải câu hỏi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ $e')));
    }
    setState(() => isLoading = false);
  }

  void selectAnswer(int index) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final duration = now - (questionStartTimes[currentIndex] ?? now);

    setState(() {
      userAnswers[currentIndex] = index;
      timeTaken[currentIndex] = duration;
    });
  }

  Future<void> submitQuiz() async {
    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    int score = 0;
    List<Map<String, dynamic>> answers = [];

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final userAns = userAnswers[i];
      final correct = q['correctAnswer'];

      if (userAns == correct) score++;

      answers.add({
        'questionId': q['_id'],
        'answer': userAns,
        'timeTaken': timeTaken[i] ?? 0,
        'level': widget.level,
      });
    }

    final body = {
      'score': score,
      'level': widget.level,
      'duration': timeTaken.values.fold(0, (a, b) => a + b),
      'submittedAnswers': answers,
    };

    try {
      final res = await http.post(
        Uri.parse(submitUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (res.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ReviewScreen(score: score, total: questions.length),
          ),
        );
      } else {
        throw Exception('Lỗi gửi bài');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Gửi bài thất bại: $e')));
    }

    setState(() => isSubmitting = false);
  }

  void showQuestionPicker() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: List.generate(questions.length, (index) {
          return ListTile(
            leading: Icon(Icons.question_answer),
            title: Text('Câu ${index + 1}'),
            tileColor: currentIndex == index ? Colors.teal.shade100 : null,
            onTap: () {
              setState(() {
                currentIndex = index;
                questionStartTimes[currentIndex] = DateTime.now().millisecondsSinceEpoch;
              });
              Navigator.pop(context);
            },
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final q = questions[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Câu ${currentIndex + 1} / ${questions.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: showQuestionPicker,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if ((q['image_url'] ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Image.network(q['image_url']),
              ),
            Text(
              q['questionText'] ?? 'Câu hỏi?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ...List.generate(4, (i) {
              return Card(
                color: userAnswers[currentIndex] == i ? Colors.green.shade100 : null,
                child: ListTile(
                  title: Text(q['options'][i]),
                  onTap: () => selectAnswer(i),
                ),
              );
            }),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Quay lại'),
                  onPressed: currentIndex > 0
                      ? () {
                    setState(() {
                      currentIndex--;
                      questionStartTimes[currentIndex] = DateTime.now().millisecondsSinceEpoch;
                    });
                  }
                      : null,
                ),
                currentIndex < questions.length - 1
                    ? ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Tiếp'),
                  onPressed: () {
                    setState(() {
                      currentIndex++;
                      questionStartTimes[currentIndex] = DateTime.now().millisecondsSinceEpoch;
                    });
                  },
                )
                    : ElevatedButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('Nộp bài'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: isSubmitting ? null : submitQuiz,
                ),
              ],
            ),
            if (isSubmitting)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
