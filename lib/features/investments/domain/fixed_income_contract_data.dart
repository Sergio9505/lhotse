enum FixedIncomeStatus { active, completed, cancelled }

extension FixedIncomeStatusX on FixedIncomeStatus {
  static FixedIncomeStatus fromString(String value) => switch (value) {
        'active' => FixedIncomeStatus.active,
        'completed' => FixedIncomeStatus.completed,
        'cancelled' => FixedIncomeStatus.cancelled,
        _ => FixedIncomeStatus.active,
      };

  bool get isActive => this == FixedIncomeStatus.active;
  bool get isCompleted => this == FixedIncomeStatus.completed;
}

class FixedIncomeContractData {
  const FixedIncomeContractData({
    required this.id,
    required this.userId,
    required this.offeringId,
    required this.brandId,
    required this.brandName,
    this.brandLogoAsset,
    required this.offeringName,
    required this.amount,
    required this.guaranteedRate,
    required this.paymentFrequency,
    required this.isCapitalGuaranteed,
    this.termMonths,
    this.startDate,
    this.maturityDate,
    required this.status,
    this.periodicPaymentAmount,
    this.totalPayments,
    this.paymentsReceived = 0,
    this.accumulatedInterest = 0,
    this.nextPaymentDate,
  });

  final String id;
  final String userId;
  final String offeringId;
  final String brandId;
  final String brandName;
  final String? brandLogoAsset;
  final String offeringName;
  final double amount;
  final double guaranteedRate;
  final String paymentFrequency;
  final bool isCapitalGuaranteed;
  final int? termMonths;
  final DateTime? startDate;
  final DateTime? maturityDate;
  final FixedIncomeStatus status;
  final double? periodicPaymentAmount;
  final int? totalPayments;
  final int paymentsReceived;
  final double accumulatedInterest;
  final DateTime? nextPaymentDate;

  bool get isActive => status == FixedIncomeStatus.active;
  bool get isCompleted => status == FixedIncomeStatus.completed;

  factory FixedIncomeContractData.fromJson(Map<String, dynamic> json) =>
      FixedIncomeContractData(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        offeringId: json['offering_id'] as String,
        brandId: json['brand_id'] as String,
        brandName: json['brand_name'] as String? ?? '',
        brandLogoAsset: json['brand_logo_asset'] as String?,
        offeringName: json['offering_name'] as String? ?? '',
        amount: (json['amount'] as num).toDouble(),
        guaranteedRate: (json['guaranteed_rate'] as num).toDouble(),
        paymentFrequency: json['payment_frequency'] as String? ?? 'monthly',
        isCapitalGuaranteed: json['is_capital_guaranteed'] as bool? ?? true,
        termMonths: json['term_months'] as int?,
        startDate: json['start_date'] != null
            ? DateTime.parse(json['start_date'] as String)
            : null,
        maturityDate: json['maturity_date'] != null
            ? DateTime.parse(json['maturity_date'] as String)
            : null,
        status: FixedIncomeStatusX.fromString(
          json['status'] as String? ?? 'active',
        ),
        periodicPaymentAmount:
            (json['periodic_payment_amount'] as num?)?.toDouble(),
        totalPayments: json['total_payments'] as int?,
        paymentsReceived: (json['payments_received'] as num?)?.toInt() ?? 0,
        accumulatedInterest:
            (json['accumulated_interest'] as num?)?.toDouble() ?? 0,
        nextPaymentDate: json['next_payment_date'] != null
            ? DateTime.parse(json['next_payment_date'] as String)
            : null,
      );
}
