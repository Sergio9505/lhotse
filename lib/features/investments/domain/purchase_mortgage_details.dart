/// Per-contract mortgage data shown in the FINANCIACIÓN tab of the L3 direct
/// purchase detail screen. Loaded lazily via
/// `purchaseMortgageDetailProvider(purchaseContractId)` only when the tab opens.
///
/// One row per purchase contract (no row if the contract has no mortgage —
/// gate via `PurchaseContractData.hasFinancing`).
class PurchaseMortgageDetails {
  const PurchaseMortgageDetails({
    required this.purchaseContractId,
    this.mortgagePrincipal,
    this.mortgageMonthlyPayment,
    this.mortgageEndDate,
    this.mortgageConditions,
  });

  final String purchaseContractId;
  final double? mortgagePrincipal;
  final double? mortgageMonthlyPayment;
  final DateTime? mortgageEndDate;
  final String? mortgageConditions;

  factory PurchaseMortgageDetails.fromJson(Map<String, dynamic> json) =>
      PurchaseMortgageDetails(
        purchaseContractId: json['purchase_contract_id'] as String,
        mortgagePrincipal: (json['mortgage_principal'] as num?)?.toDouble(),
        mortgageMonthlyPayment:
            (json['mortgage_monthly_payment'] as num?)?.toDouble(),
        mortgageEndDate: json['mortgage_end_date'] != null
            ? DateTime.parse(json['mortgage_end_date'] as String)
            : null,
        mortgageConditions: json['mortgage_conditions'] as String?,
      );
}
