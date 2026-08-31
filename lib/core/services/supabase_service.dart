import 'dart:typed_data';
import '../models/chat_room_model.dart';
import 'dart:typed_data';
import '../models/chat_room_model.dart';
import 'dart:async';
import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/constants.dart';
import '../models/chat_model.dart';
import '../models/complaint_model.dart';

class SupabaseService {
  static SupabaseService? _instance;
  late final SupabaseClient _client;

  SupabaseService._internal();

  static Future<SupabaseService> initialize() async {
    if (_instance != null) return _instance!;
    
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
    
    _instance = SupabaseService._internal();
    _instance!._client = Supabase.instance.client;
    return _instance!;
  }

  static SupabaseService get instance {
    if (_instance == null) {
      throw Exception('Supabase not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  SupabaseClient get client => _client;

  // ─── Auth ───
  GoTrueClient get auth => _client.auth;

  Future<AuthResponse> signInWithPassword(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password, {Map<String, dynamic>? data}) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;
  String? get currentUserId => _client.auth.currentUser?.id;
  String? get sessionToken => _client.auth.currentSession?.accessToken;

  // ─── Realtime ───
  
  RealtimeChannel subscribeToComplaintUpdates(String complaintId, void Function(PostgresChangePayload) callback) {
    final channel = _client.channel('complaint_$complaintId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'complaints',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: complaintId,
        ),
        callback: callback,
      )
      .subscribe();
    return channel;
  }

  RealtimeChannel subscribeToChatMessages(String roomId, void Function(ChatMessage) callback) {
    final channel = _client.channel('chat_$roomId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (payload) {
          final msg = ChatMessage.fromJson(payload.newRecord);
          callback(msg);
        },
      )
      .subscribe();
    return channel;
  }

  RealtimeChannel subscribeToLocation(String userId, void Function(double lat, double lng) callback) {
    final channel = _client.channel('loc_$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'staff_locations',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          final lat = payload.newRecord['latitude']?.toDouble();
          final lng = payload.newRecord['longitude']?.toDouble();
          if (lat != null && lng != null) callback(lat, lng);
        },
      )
      .subscribe();
    return channel;
  }

  void unsubscribe(String channelName) {
    _client.removeChannel(_client.channel(channelName));
  }

  // ─── Database ───

  Future<List<ComplaintModel>> getComplaints({String? userId, String? status, String? assigneeId}) async {
    var query = _client.from('complaints').select();
    
    if (userId != null) query = query.eq('customer_id', userId);
    if (status != null) query = query.eq('status', status);
    if (assigneeId != null) {
      query = query.or('assigned_delivery_boy_id.eq.$assigneeId,assigned_service_center_id.eq.$assigneeId');
    }

    final res = await query.order('created_at', ascending: false);
    return (res).map((e) => ComplaintModel.fromJson(e)).toList();
  }

  Future<ComplaintModel?> getComplaint(String id) async {
    final res = await _client.from('complaints').select().eq('id', id).single();
    if (res == null) return null;
    return ComplaintModel.fromJson(res);
  }

  Future<void> createComplaint(Map<String, dynamic> data) async {
    await _client.from('complaints').insert(data);
  }

  Future<void> updateComplaint(String id, Map<String, dynamic> data) async {
    await _client.from('complaints').update(data).eq('id', id);
  }

  Future<void> deleteComplaint(String id) async {
    await _client.from('complaints').delete().eq('id', id);
  }

  // ─── Chat ───

  Future<String> createChatRoom(Map<String, dynamic> data) async {
    final res = await _client.from('chat_rooms').insert(data).select('id').single();
    return res['id'] as String;
  }

  Future<List<ChatRoom>> getChatRooms(String userId) async {
    final res = await _client
        .from('chat_rooms')
        .select()
        .contains('participants', [userId])
        .order('updated_at', ascending: false);
    return (res).map((e) => ChatRoom.fromJson(e)).toList();
  }

  Future<List<ChatMessage>> getChatMessages(String roomId, {int limit = 50}) async {
    final res = await _client
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: false)
        .limit(limit);
    return (res).map((e) => ChatMessage.fromJson(e)).toList();
  }

  Future<void> sendMessage(Map<String, dynamic> data) async {
    await _client.from('chat_messages').insert(data);
    await _client.from('chat_rooms')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', data['room_id']);
  }

  // ─── Location ───

  Future<void> updateStaffLocation(String userId, double lat, double lng) async {
    await _client.from('staff_locations').upsert({
      'user_id': userId,
      'latitude': lat,
      'longitude': lng,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> getStaffLocation(String userId) async {
    final res = await _client.from('staff_locations')
        .select()
        .eq('user_id', userId)
        .single();
    return res;
  }

  // ─── Storage ───

  Future<String> uploadImage(String bucket, String path, List<int> bytes, {String? contentType}) async {
    await _client.storage.from(bucket).uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(
        contentType: contentType ?? 'image/jpeg',
        upsert: true,
      ),
    );
    return _client.storage.from(bucket).getPublicUrl(path);
  }

  // ─── EmoCoins ───

  Future<Map<String, dynamic>> getCoinData(String userId) async {
    final res = await _client.from('emocoins')
        .select()
        .eq('user_id', userId)
        .single();
    return res;
  }

  Future<void> updateCoinBalance(String userId, int newBalance) async {
    await _client.from('emocoins')
        .update({'balance': newBalance, 'updated_at': DateTime.now().toIso8601String()})
        .eq('user_id', userId);
  }

  Future<void> addCoinTransaction(Map<String, dynamic> data) async {
    await _client.from('coin_transactions').insert(data);
  }
}