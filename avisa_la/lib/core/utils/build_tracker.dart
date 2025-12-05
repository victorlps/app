class BuildTracker {
  // Gera um timestamp em formato aa:mm:dd:hh:mm:ss
  static String _generateBuildTimestamp() {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(2, '0')}"
        ":${now.month.toString().padLeft(2, '0')}"
        ":${now.day.toString().padLeft(2, '0')}"
        ":${now.hour.toString().padLeft(2, '0')}"
        ":${now.minute.toString().padLeft(2, '0')}"
        ":${now.second.toString().padLeft(2, '0')}";
  }

  // Variável que guardará o timestamp da build
  static String buildTimestamp = _generateBuildTimestamp();

  /// Chama isso para forçar a renovação do timestamp (usado no Hot Reload)
  static void refresh() {
    buildTimestamp = _generateBuildTimestamp();
    print("🔄 Build Timestamp atualizado: $buildTimestamp");
  }
}
