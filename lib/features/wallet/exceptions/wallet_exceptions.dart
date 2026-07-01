class WalletLockedException implements Exception {
  const WalletLockedException([
    this.message = 'Wallet is locked or target balance not yet reached',
  ]);

  final String message;

  @override
  String toString() => 'WalletLockedException: $message';
}
