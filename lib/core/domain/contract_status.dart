/// Human-driven state of a contract document, unified across the 4 investment
/// domains (purchase / coinvestment / fixed_income / rental). See ADR-44.
///
/// Completion ("finalizado") is NOT a status — it is a UI projection derived
/// per-domain in each view (e.g. `sold_date IS NOT NULL` for purchase,
/// `projects.project_status = 'closed'` for coinvestment). Read it via
/// the `isCompleted` field on the contract model.
enum ContractStatus { pending, signed, cancelled }

extension ContractStatusX on ContractStatus {
  static ContractStatus fromString(String? value) => switch (value) {
        'pending' => ContractStatus.pending,
        'signed' => ContractStatus.signed,
        'cancelled' => ContractStatus.cancelled,
        _ => ContractStatus.signed,
      };

  String get wire => name;

  bool get isSigned => this == ContractStatus.signed;
  bool get isPending => this == ContractStatus.pending;
  bool get isCancelled => this == ContractStatus.cancelled;
}
