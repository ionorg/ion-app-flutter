import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotFound extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${Get.routing.current} Page Not Found',
                style: TextStyle(fontSize: 30)),
            const SizedBox(height: 25),
            ElevatedButton(
              child: Text('Back to Login', style: TextStyle(fontSize: 30)),
              onPressed: () => Get.offNamed('/login'),
            )
          ],
        ),
      ),
    );
  }
}
