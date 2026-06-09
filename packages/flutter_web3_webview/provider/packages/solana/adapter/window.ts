export interface FxWalletEvent {
  connect(...args: unknown[]): unknown;
  disconnect(...args: unknown[]): unknown;
  accountChanged(...args: unknown[]): unknown;
}

export interface FxWalletEventEmitter {
  on<E extends keyof FxWalletEvent>(
    event: E,
    listener: FxWalletEvent[E],
    context?: any,
  ): void;
  off<E extends keyof FxWalletEvent>(
    event: E,
    listener: FxWalletEvent[E],
    context?: any,
  ): void;
}
