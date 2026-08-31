class AppConstants {
  static const String apiBase = 'https://emobies-backend.onrender.com';
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String emoKeyBase = 'https://emo-key.vercel.app';
  static const String cfAiBase = 'https://emobies-ai.meradivin.workers.dev';
  static const String cloudflareAiBase = 'https://emobies-ai.meradivin.workers.dev';

  static const String telegramBotToken = String.fromEnvironment('TELEGRAM_BOT_TOKEN');
  static const String telegramChatId = String.fromEnvironment('TELEGRAM_CHAT_ID');
  static const String discordWebhookUrl = String.fromEnvironment('DISCORD_WEBHOOK_URL');

  // Auth
  static const String adminPhone = '9847842172';
  static const String jwtSecret = String.fromEnvironment('JWT_SECRET');

  // Roles
  static const String roleCustomer = 'customer';
  static const String roleStaff = 'staff';
  static const String roleSupervisor = 'supervisor';
  static const String roleSuperAdmin = 'super_admin';
  static const String roleDeliveryBoy = 'delivery_boy';
  static const String roleServiceCenter = 'service_center';

  // EmoCoin settings
  static const int coinsForCryptoExchange = 1000;
  static const double cryptoExchangeRate = 0.001;
  static const double coinRupeeValue = 0.10;
  static const int dailyLoginCoins = 10;

  // SharedPreferences keys
  static const String prefEmoCoins = 'ew_emo_coins';
  static const String prefDailyCoinDate = 'ew_daily_coin_date';

  // Login security
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 15);
}
