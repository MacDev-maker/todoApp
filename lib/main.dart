import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'dart:math';

import 'task_local_database.dart';
import 'task_sync_service.dart';

class Task {
  final int id;
  final String title;
  final String deadline;
  final String priority;
  bool done;

  Task({
    required this.id,
    required this.title,
    required this.deadline,
    required this.priority,
    required this.done,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "deadline": deadline,
      "priority": priority,
      "done": done,
    };
  }

  factory Task.fromMap(Map map) {
    return Task(
      id: map["id"],
      title: map["title"],
      deadline: map["deadline"],
      priority: map["priority"],
      done: map["done"],
    );
  }
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("tasks");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'To Do App',
      home: HomeScreen(),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";


  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  final GlobalKey<TaskListScreenState> _taskListKey = GlobalKey<TaskListScreenState>();

  void updateCounters(List<Task> tasks) {
    final newAll = tasks.length;
    final newDone = tasks.where((task) => task.done).length;
    final newTodo = tasks.where((task) => !task.done).length;

    if (allTasksCount != newAll || doneTasksCount != newDone || todoTasksCount != newTodo) {
      setState(() {
        allTasksCount = newAll;
        doneTasksCount = newDone;
        todoTasksCount = newTodo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        title: const Text(
          "To do App",
          style: TextStyle(fontSize: 48, color: Colors.blue, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, size: 40, color: Colors.red),
            onPressed: () => _confirmDeleteAll(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Wszystkie zadania ogółem: $allTasksCount",
              style: const TextStyle(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Pozostało do zrobienia: $todoTasksCount",
              style: const TextStyle(fontSize: 20, color: Colors.purple, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Już wykonane: $doneTasksCount",
              style: const TextStyle(fontSize: 20, color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            FilterBar(
              selectedFilter: selectedFilter,
              onFilterChanged: (val) => setState(() => selectedFilter = val),
            ),
            const SizedBox(height: 10),
            Text(
              "Moje zadania | Ukończone ($doneTasksCount)",
              style: const TextStyle(fontSize: 24, color: Colors.blue, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),


            Expanded(
              child: TaskListScreen(
                key: _taskListKey,
                selectedFilter: selectedFilter,
                onTasksLoaded: updateCounters,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddTaskScreen()),
          );
          if (newTask != null) {
            await TaskLocalDatabase.addTask(newTask);
            _taskListKey.currentState?.refreshTasks();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Potwierdzenie"),
        content: const Text("Usunąć wszystkie zadania lokalne?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Anuluj")),
          TextButton(
            onPressed: () async {
              await TaskLocalDatabase.deleteAllTasks();
              Navigator.pop(ctx);
              _taskListKey.currentState?.refreshTasks();
            },
            child: const Text("Usuń"),
          ),
        ],
      ),
    );
  }
}


class TaskListScreen extends StatefulWidget {
  final String selectedFilter;
  final ValueChanged<List<Task>> onTasksLoaded;

  const TaskListScreen({
    super.key,
    required this.selectedFilter,
    required this.onTasksLoaded,
  });

  @override
  State<TaskListScreen> createState() => TaskListScreenState();
}

class TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }


  void refreshTasks() {
    setState(() {
      tasksFuture = Future.value(TaskLocalDatabase.getTasks());
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Błąd: ${snapshot.error}"));
        }

        final tasks = snapshot.data ?? [];


        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onTasksLoaded(tasks);
          }
        });

        List<Task> filteredTasks = tasks;
        if (widget.selectedFilter == "wykonane") {
          filteredTasks = tasks.where((t) => t.done).toList();
        } else if (widget.selectedFilter == "do zrobienia") {
          filteredTasks = tasks.where((t) => !t.done).toList();
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            return Dismissible(
              key: ValueKey(task.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) async {
                await TaskLocalDatabase.deleteTask(task.id);
                refreshTasks();
              },
              child: TaskCard(
                title: task.title,
                deadline: task.deadline,
                done: task.done,
                priority: task.priority,
                onChanged: (val) async {
                  task.done = val ?? false;
                  await TaskLocalDatabase.updateTask(task);
                  refreshTasks();
                },
                onTap: () async {
                  final updated = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditTaskScreen(task: task)),
                  );
                  if (updated != null) {
                    await TaskLocalDatabase.updateTask(updated);
                    refreshTasks();
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  final priorityController = TextEditingController();

  AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowe zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł")),
            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin")),
            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final task = Task(
                  id: Random().nextInt(1000000),
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: false,
                );
                Navigator.pop(context, task);
              },
              child: const Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;
  const EditTaskScreen({super.key, required this.task});
  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController tCtrl, dCtrl, pCtrl;

  @override
  void initState() {
    super.initState();
    tCtrl = TextEditingController(text: widget.task.title);
    dCtrl = TextEditingController(text: widget.task.deadline);
    pCtrl = TextEditingController(text: widget.task.priority);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: tCtrl, decoration: const InputDecoration(labelText: "Tytuł")),
            TextField(controller: dCtrl, decoration: const InputDecoration(labelText: "Termin")),
            TextField(controller: pCtrl, decoration: const InputDecoration(labelText: "Priorytet")),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final updated = Task(
                  id: widget.task.id,
                  title: tCtrl.text,
                  deadline: dCtrl.text,
                  priority: pCtrl.text,
                  done: widget.task.done,
                );
                Navigator.pop(context, updated);
              },
              child: const Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title, deadline, priority;
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.title, required this.deadline, required this.done, required this.priority, this.onChanged, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: done, onChanged: onChanged),
        title: Text(title, style: TextStyle(decoration: done ? TextDecoration.lineThrough : null)),
        subtitle: Text(deadline),
        trailing: Text(priority, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const FilterBar({super.key, required this.selectedFilter, required this.onFilterChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: ["wszystkie", "do zrobienia", "wykonane"].map((f) {
        final active = selectedFilter == f;
        return TextButton(
          onPressed: () => onFilterChanged(f),
          style: TextButton.styleFrom(foregroundColor: active ? Colors.blue : Colors.grey),
          child: Text(f[0].toUpperCase() + f.substring(1)),
        );
      }).toList(),
    );
  }
}