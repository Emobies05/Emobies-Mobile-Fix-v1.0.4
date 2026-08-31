class ChatRoom {
  final String id;
  final String name;
  final String? lastMessage;
  final DateTime? updatedAt;
  final List<String> participants;

  ChatRoom({
    required this.id,
    required this.name,
    this.lastMessage,
    this.updatedAt,
    this.participants = const [],
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      lastMessage: json['last_message'],
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
      participants: (json['participants'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'last_message': lastMessage,
      'updated_at': updatedAt?.toIso8601String(),
      'participants': participants,
    };
  }
}
