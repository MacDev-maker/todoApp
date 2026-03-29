import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  final List<Task> tasks = const [
    Task(title: "Zaprojektować bazę danych", deadline: "pojutrze", done: false, priority: "średni"),
    Task(title: "Frontend strony", deadline: "za tydzień", done: true, priority: "wysoki"),
    Task(title: "Backend strony", deadline: "za da tygodnie", done: false, priority: "niski"),
    Task(title: "Przeczytać książę", deadline: "za dwa dni", done: true, priority: "wysoki")
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home:
        Scaffold (
          appBar: AppBar(
            toolbarHeight: 120,

            title:
              Text("To do App",

                style: TextStyle(
                  fontSize: 48,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
            ),
          ),

          body:
            Padding (
              padding: EdgeInsets.all(16),
              child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text("Masz do zrobienia tyle zadań: ${tasks.length}",

                      style: TextStyle(
                        fontSize: 36,
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text("Moje zadania | Ukończone(${tasks.where((task) => task.done).length})",

                    style: TextStyle(
                      fontSize: 48,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    )),

                    SizedBox(height: 40),

                    Expanded(child: ListView.builder(
                      itemCount: tasks.length,

                      itemBuilder: (context, index) {
                        return TaskCard(
                          title: tasks[index].title,
                          deadline: tasks[index].deadline,
                          icon: tasks[index].done ? Icons.check_circle : Icons.radio_button_unchecked,
                          priority: tasks[index].priority,
                        );
                      },
                    ))
                 ],
                )
              ),
            )
          );
  }
}

class Task {
  final String title;
  final String deadline;
  final IconData icon = Icons.one_x_mobiledata_rounded;
  final bool done;
  final String priority;

  const Task({required this.title, required this.deadline, required this.done, required this.priority});
}

class TaskCard extends StatelessWidget {
  final String title;
  final String deadline;
  final IconData icon;
  final String priority;

  const TaskCard({
    super.key,
    required this.title,
    required this.deadline,
    required this.icon,
    required this.priority,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(deadline),
        trailing: Text(priority),
      ),
    );
  }
}
