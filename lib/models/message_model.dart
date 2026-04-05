class MessageModel {
  final int? id;
  final int queryId;
  final String senderType; // 'Admin' or 'Employee'
  final int senderId;
  final String message;
  final String timestamp;

  MessageModel({
    this.id,
    required this.queryId,
    required this.senderType,
    required this.senderId,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'query_id': queryId,
      'sender_type': senderType,
      'sender_id': senderId,
      'message': message,
      'timestamp': timestamp,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      queryId: map['query_id'],
      senderType: map['sender_type'] ?? 'Employee',
      senderId: map['sender_id'],
      message: map['message'],
      timestamp: map['timestamp'],
    );
  }
}
