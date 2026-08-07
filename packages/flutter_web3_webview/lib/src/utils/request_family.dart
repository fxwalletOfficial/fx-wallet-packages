/// Which chain family a provider request belongs to.
///
/// EVM and Solana provider requests share one [SerialEventQueue], but a host's
/// authorization (grant/session) is invalidated *per chain* — switching the
/// Solana account must not tear down an in-flight EVM signing request, and vice
/// versa. Each queued request is tagged with its family (see
/// `Web3RequestDispatcher.familyOf`, which mirrors the routing switch) so the
/// host can cancel only the requests of the chain that just changed.
enum Web3RequestFamily { evm, solana }
