import 'package:flutter/material.dart';

class ReviewScreen extends StatelessWidget {
  final int score;
  final int total;

  const ReviewScreen({super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả bài làm')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Điểm số của bạn:', style: TextStyle(fontSize: 20)),
            Text('$score / $total', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.home),
              label: Text('Về trang chủ'),
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            )
          ],
        ),
      ),
    );
  }
}
