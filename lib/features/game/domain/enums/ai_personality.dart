/// Yapay zekâ oyuncuların karar ağırlıklarını değiştiren kişilik profili.
enum AiPersonality {
  /// Riskli taş atmaktan kaçınır, güvenli oyunu tercih eder.
  cautious,

  /// Yüksek riskli, yüksek getirili hamleleri tercih eder.
  aggressive,

  /// Seri oluşturmaya öncelik verir.
  runFocused,

  /// Grup oluşturmaya öncelik verir.
  groupFocused,

  /// Okeyi mümkün olduğunca elinde tutar, geç kullanır.
  okeyHoarder,

  /// 101 açmayı önceliklendirir, erken açmaya çalışır.
  fastOpener,

  /// Rakiplerin attığı/aldığı taşları yakından takip eder.
  opponentTracker,

  /// Belirsiz durumlarda yüksek riskli hamleleri göze alır.
  riskTaker,
}
