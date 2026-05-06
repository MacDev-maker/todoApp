import 'package:flutter/material.dart';

import 'task_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";

  @override
  Widget build(BuildContext context) {
    List<Task> filteredTasks = TaskRepository.tasks;

    if (selectedFilter == "wykonane") {
      filteredTasks = TaskRepository.tasks
          .where((task) => task.done)
          .toList();
    } else if (selectedFilter == "do zrobienia") {
      filteredTasks = TaskRepository.tasks
          .where((task) => !task.done)
          .toList();
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 120,
        title: const Text(
          "To do App",
          style: TextStyle(
            fontSize: 48,
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, size: 40, color: Colors.red),
            onPressed: () {
              if (TaskRepository.tasks.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Brak zadań do usunięcia")),
                );
                return;
              }

              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text("Potwierdzenie"),
                    content: const Text("Czy na pewno chcesz usunąć wszystkie zadania?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Anuluj"),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            TaskRepository.tasks.clear();
                          });
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Wszystkie zadania zostały usunięte")),
                          );
                        },
                        child: const Text("Usuń"),
                      ),
                    ],
                  );
                },
              );
            },
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
              "Masz do zrobienia tyle zadań: ${filteredTasks.length}",
              style: const TextStyle(
                fontSize: 36,
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            FilterBar(
              selectedFilter: selectedFilter,
              onFilterChanged: (newFilter) {
                setState(() {
                  selectedFilter = newFilter;
                });
              },
            ),

            Text(
              "Moje zadania | Ukończone (${TaskRepository.tasks.where((task) => task.done).length})",
              style: const TextStyle(
                fontSize: 48,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            Expanded(
              child: ListView.builder(
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return Dismissible(
                      key: ValueKey(task.title),

                      direction: DismissDirection.endToStart,

                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          setState(() {
                            TaskRepository.tasks.remove(task);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Usunieto zadanie")),
                          );
                        }
                      },

                      child:TaskCard(
                        title: task.title,
                        deadline: task.deadline,
                        done: task.done,
                        onChanged: (value) {
                          setState(()  {
                            task.done = value!;
                          });
                        },
                        priority: task.priority,
                        onTap: () async {
                          final Task? updatedTask = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditTaskScreen(task: task),
                            ),
                          );

                          if (updatedTask != null) {
                            int indexInOriginal = TaskRepository.tasks.indexOf(task);
                            if (indexInOriginal != -1) {
                              TaskRepository.tasks[indexInOriginal] = updatedTask;
                            }
                          }
                        },
                      ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );

          if (newTask != null) {
            setState(() {
              TaskRepository.tasks.add(newTask);
            });
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: HomeScreen(),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nowe zadanie"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Czas do wykonania zadania",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priotytet",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: false
                );

                Navigator.pop(context, newTask);
              },
              child: Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class Task {
  final String title;
  final String deadline;
  final IconData icon = Icons.one_x_mobiledata_rounded;
  bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final String title;
  final String deadline;
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final String priority;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.deadline,
    required this.done,
    this.onChanged,
    required this.priority,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color getPriorityColor() {
      switch (priority.toLowerCase()) {
        case "wysoki":
          return Colors.red;
        case "średni":
          return Colors.orange;
        case "niski":
          return Colors.green;
        default:
          return Colors.black;
      }
    }

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: done,
          onChanged: onChanged,
        ),
        title: Text(
            title,
            style: TextStyle(
              decoration: done
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
        ),
        subtitle: Text(deadline),
        trailing: Text(
          priority,
          style: TextStyle(
            color: getPriorityColor(),
            fontWeight: FontWeight.bold,
          ),
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
  late TextEditingController titleController;
  late TextEditingController deadlineController;
  late TextEditingController priorityController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    deadlineController = TextEditingController(text: widget.task.deadline);
    priorityController = TextEditingController(text: widget.task.priority);
  }

  @override
  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edycja zadania"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Czas do wykonania zadania",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                final updatedTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: widget.task.done,
                );

                Navigator.pop(context, updatedTask);
              },
              child: const Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildFilterButton("wszystkie", "Wszystkie"),
        _buildFilterButton("do zrobienia", "Do zrobienia"),
        _buildFilterButton("wykonane", "Wykonane"),
      ],
    );
  }

  Widget _buildFilterButton(String filterValue, String label) {
    final isActive = selectedFilter == filterValue;
    return TextButton(
      onPressed: () => onFilterChanged(filterValue),
      style: TextButton.styleFrom(
        backgroundColor: isActive ? Colors.blue.withOpacity(0.2) : Colors.transparent,
        foregroundColor: isActive ? Colors.blue : Colors.grey,
        textStyle: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      child: Text(label),
    );
  }
}