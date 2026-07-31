import 'package:flutter/material.dart';
import 'package:nuvtune/app/localization/strings.dart';
import 'package:nuvtune/features/queue/queue_list.dart';

/// Vista de cola como pantalla propia (requerimiento seccion 11).
class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.queue)),
      body: const QueueList(),
    );
  }
}
