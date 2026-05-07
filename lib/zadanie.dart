import 'dart:convert';

void main() {
  String jsonText = '[1, 5, 8, 3, 2]';
  final List<dynamic> data = jsonDecode(jsonText);

  int suma = 0;
  print('Wypisuję liczby:');

  for (var liczba in data) {
    print(liczba);
    suma += liczba as int;
  }

  print('Suma wszystkich liczb: $suma');

  String jsonText2 = '''
  {
    "group": "Dart",
    "students": ["Ola", "Adam", "Kasia"]
  }
  ''';

  final dane = jsonDecode(jsonText2);

  print('Nazwa grupy: ${dane["group"]}');
  print('Imiona studentów:');

  for (var student in dane["students"]) {
    print(student);
  }

  String jsonText3 = '''
  {
    "product": {
      "name": "Laptop",
      "price": 3500
    }
  }
  ''';

  final dane2 = jsonDecode(jsonText3);

  print('Nazwa produktu: ${dane2["product"]["name"]}');
  print('Cena: ${dane2["product"]["price"]}');
}

