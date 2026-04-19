import '../../../core/domain/contract_status.dart';

class FixedIncomeContractData {
  const FixedIncomeContractData({
    required this.id,
    required this.offeringId,
    required this.brandId,
    required this.offeringName,
    required this.amount,
    required this.guaranteedRate,
    required this.paymentFrequency,
    this.termMonths,
    this.startDate,
    this.maturityDate,
    required this.status,
    required this.isCompleted,
  });

  final String id;
  final String offeringId;
  final String brandId;
  final String offeringName;
  final double amount;
  final double guaranteedRate;
  final String paymentFrequency;
  final int? termMonths;
  final DateTime? startDate;
  final DateTime? maturityDate;
  final ContractStatus status;

  /// Derived in `user_fixed_income_contracts` view as `maturity_date < CURRENT_DATE`.
  final bool isCompleted;

  bool get isActive => status.isSigned && !isCompleted;

  factory FixedIncomeContractData.fromJson(Map<String, dynamic> json) =>
      FixedIncomeContractData(
        id: json['id'] as String,
        offeringId: json['offering_id'] as String,
        brandId: json['brand_id'] as String,
        offeringName: json['offering_name'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
        guaranteedRate: (json['guaranteed_rate'] as num).toDouble(),
        paymentFrequency: json['payment_frequency'] as String? ?? 'monthly',
        termMonths: json['term_months'] as int?,
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'] as String)
            : null,
        maturityDate: json['maturity_date'] != null
            ? DateTime.parse(json['maturity_date'] as String)
            : null,
        status: ContractStatusX.fromString(json['status'] as String?),
        isCompleted: json['is_completed'] as bool? ?? false,
      );
}
