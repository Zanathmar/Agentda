class AppUser {
  final String  id;
  final String  email;
  final String? name;

  const AppUser({required this.id, required this.email, this.name});

  String get displayName => name ?? email.split('@').first;

  Map<String, dynamic> toJson() => {'id': id, 'email': email, 'name': name};

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id:    j['id']    as String,
        email: j['email'] as String,
        name:  j['name']  as String?,
      );
}