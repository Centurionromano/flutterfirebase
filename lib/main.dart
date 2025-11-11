import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tareas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TaskListPage(),
    );
  }
}

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference tasks =
      FirebaseFirestore.instance.collection('tasks');

  void _addTask() async {
    if (_controller.text.isNotEmpty) {
      await tasks.add({
        'title': _controller.text,
        'done': false,
      });
      _controller.clear();
    }
  }

  void _toggleDone(String id, bool currentStatus) {
    tasks.doc(id).update({'done': !currentStatus});
  }

  void _deleteTask(String id) {
    tasks.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista de Tareas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'Nueva tarea',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _addTask,
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: tasks.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar tareas'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final taskDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: taskDocs.length,
                  itemBuilder: (context, index) {
                    final task = taskDocs[index];
                    final taskId = task.id;
                    final data = task.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(
                        data['title'],
                        style: TextStyle(
                          decoration: data['done']
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      leading: Checkbox(
                        value: data['done'],
                        onChanged: (_) =>
                            _toggleDone(taskId, data['done'] ?? false),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTask(taskId),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
