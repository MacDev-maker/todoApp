import 'main.dart';

class TaskRepository {
  static List<Task> tasks = [
    Task(
        title: "Zaprojektować bazę danych",
        deadline: "pojutrze",
        done: false,
        priority: "średni"),
    Task(
        title: "Frontend strony",
        deadline: "za tydzień",
        done: true,
        priority: "wysoki"),
    Task(
        title: "Backend strony",
        deadline: "za dwa tygodnie",
        done: false,
        priority: "niski"),
    Task(
        title: "Przeczytać książkę",
        deadline: "za dwa dni",
        done: true,
        priority: "wysoki")
  ];
}