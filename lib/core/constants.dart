library;

class GeometryTypes {
  static const point = 'point';
  static const line = 'line';
  static const polygon = 'polygon';
}

class EnvanterStatus {
  static const aktif = 'Aktif';
  static const pasif = 'Pasif';
}

class RuleType {
  static const required = 'required';
  static const forbidden = 'forbidden';
}

class Predicate {
  static const intersects = 'intersects';
  static const within = 'within';
  static const contains = 'contains';
}

class RuleScope {
  static const any = 'ANY';
}

class FieldKeys {
  static const name = 'name';
  static const description = 'description';
}

class FieldType {
  static const text = 'text';
  static const number = 'number';
  static const dropdown = 'dropdown';
}
