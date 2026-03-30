import '../../domain/investment_data.dart';

final mockInvestments = [
  // Andhy
  InvestmentData(
    id: 'inv-1',
    projectId: '11',
    projectName: 'Andhy I',
    brandName: 'Andhy',
    amount: 350000,
    returnRate: 12,
    durationMonths: 36,
    expectedEndDate: DateTime(2028, 6),
    constructionPhase: 'Fase 3',
    purchaseValue: 420000,
    cashPayment: 168000,
    mortgage: 252000,
    mortgageConditions: 'RF - 3,2%',
    monthlyPayment: 1250,
    mortgageEndDate: DateTime(2048, 6),
    rentalIncome: 2100,
    revaluation: 9,
    unitName: 'Piso 4B',
  ),
  InvestmentData(
    id: 'inv-2',
    projectId: '12',
    projectName: 'Andhy II',
    brandName: 'Andhy',
    amount: 520000,
    returnRate: 15,
    durationMonths: 48,
    expectedEndDate: DateTime(2029, 3),
    constructionPhase: 'Fase 2',
    isDelayed: true,
    purchaseValue: 680000,
    cashPayment: 340000,
    mortgage: 340000,
    mortgageConditions: 'RF - 2,9%',
    monthlyPayment: 1680,
    mortgageEndDate: DateTime(2049, 3),
    rentalIncome: 3200,
    revaluation: 11,
    unitName: 'Villa 7',
  ),

  // Lacomb & Bos
  InvestmentData(
    id: 'inv-3',
    projectId: '1',
    projectName: 'Allegro',
    brandName: 'Lacomb & Bos',
    amount: 280000,
    returnRate: 18,
    durationMonths: 30,
    expectedEndDate: DateTime(2028, 1),
    constructionPhase: 'Fase 4',
    purchaseValue: 380000,
    cashPayment: 152000,
    mortgage: 228000,
    mortgageConditions: 'RF - 3%',
    monthlyPayment: 1100,
    mortgageEndDate: DateTime(2048, 1),
    rentalIncome: 2400,
    revaluation: 8,
    unitName: 'Piso 1',
  ),
  InvestmentData(
    id: 'inv-4',
    projectId: '2',
    projectName: 'Allegro 2',
    brandName: 'Lacomb & Bos',
    amount: 310000,
    returnRate: 22,
    durationMonths: 24,
    expectedEndDate: DateTime(2027, 9),
    constructionPhase: 'Fase 3',
    purchaseValue: 450000,
    cashPayment: 225000,
    mortgage: 225000,
    mortgageConditions: 'RF - 2,8%',
    monthlyPayment: 1350,
    mortgageEndDate: DateTime(2047, 9),
    unitName: 'Piso 3A',
  ),

  // Ciclo
  InvestmentData(
    id: 'inv-5',
    projectId: '13',
    projectName: 'Miami Shores',
    brandName: 'Ciclo',
    amount: 200000,
    returnRate: 18,
    durationMonths: 36,
    expectedEndDate: DateTime(2028, 12),
    constructionPhase: 'Fase 4',
  ),
  InvestmentData(
    id: 'inv-6',
    projectId: '14',
    projectName: 'Miami Bay',
    brandName: 'Ciclo',
    amount: 150000,
    returnRate: 16,
    durationMonths: 30,
    expectedEndDate: DateTime(2028, 6),
    constructionPhase: 'Fase 2',
    isDelayed: true,
  ),

  // Renta Fija
  InvestmentData(
    id: 'inv-7',
    projectId: '15',
    projectName: 'RF Capital I',
    brandName: 'Renta Fija',
    amount: 500000,
    returnRate: 5,
    durationMonths: 36,
  ),
  InvestmentData(
    id: 'inv-8',
    projectId: '16',
    projectName: 'RF Capital II',
    brandName: 'Renta Fija',
    amount: 300000,
    returnRate: 4.5,
    durationMonths: 24,
  ),

  // Vellte (coinversión)
  InvestmentData(
    id: 'inv-9',
    projectId: '8',
    projectName: 'Arcadia',
    brandName: 'Vellte',
    amount: 450000,
    returnRate: 20,
    durationMonths: 42,
    expectedEndDate: DateTime(2029, 6),
    constructionPhase: 'Fase 1',
  ),
  InvestmentData(
    id: 'inv-11',
    projectId: '4',
    projectName: 'Cabriole 2',
    brandName: 'Vellte',
    amount: 275000,
    returnRate: 17,
    durationMonths: 30,
    expectedEndDate: DateTime(2028, 9),
    constructionPhase: 'Fase 3',
  ),

  // Myttas
  InvestmentData(
    id: 'inv-10',
    projectId: '3',
    projectName: 'Cabriole',
    brandName: 'Myttas',
    amount: 180000,
    returnRate: 14,
    durationMonths: 24,
    purchaseValue: 260000,
    cashPayment: 260000,
    rentalIncome: 1500,
    revaluation: 7,
    isCompleted: true,
  ),
  InvestmentData(
    id: 'inv-12',
    projectId: '7',
    projectName: 'Velorum',
    brandName: 'Myttas',
    amount: 320000,
    returnRate: 16,
    durationMonths: 36,
    expectedEndDate: DateTime(2029, 1),
    constructionPhase: 'Fase 2',
    purchaseValue: 480000,
    cashPayment: 240000,
    mortgage: 240000,
    mortgageConditions: 'RF - 2,7%',
    monthlyPayment: 1180,
    mortgageEndDate: DateTime(2049, 1),
    rentalIncome: 2500,
    revaluation: 10,
    unitName: 'Piso 6A',
  ),
  InvestmentData(
    id: 'inv-13',
    projectId: '3',
    projectName: 'Cabriole',
    brandName: 'Myttas',
    amount: 210000,
    returnRate: 13,
    durationMonths: 28,
    expectedEndDate: DateTime(2028, 8),
    constructionPhase: 'Fase 4',
    purchaseValue: 310000,
    cashPayment: 310000,
    rentalIncome: 1800,
    revaluation: 6,
    unitName: 'Casa Poema',
  ),

  // NUVE (coinversión)
  InvestmentData(
    id: 'inv-14',
    projectId: '5',
    projectName: 'SISONE',
    brandName: 'NUVE',
    amount: 190000,
    returnRate: 15,
    durationMonths: 32,
    expectedEndDate: DateTime(2028, 10),
    constructionPhase: 'Fase 3',
  ),
  InvestmentData(
    id: 'inv-15',
    projectId: '9',
    projectName: 'Luminar',
    brandName: 'NUVE',
    amount: 260000,
    returnRate: 19,
    durationMonths: 40,
    expectedEndDate: DateTime(2029, 4),
    constructionPhase: 'Fase 1',
  ),

  // Domorato (coinversión)
  InvestmentData(
    id: 'inv-16',
    projectId: '6',
    projectName: 'SISONE II',
    brandName: 'Domorato',
    amount: 380000,
    returnRate: 21,
    durationMonths: 36,
    expectedEndDate: DateTime(2028, 12),
    constructionPhase: 'Fase 2',
  ),
  InvestmentData(
    id: 'inv-17',
    projectId: '10',
    projectName: 'Terracota',
    brandName: 'Domorato',
    amount: 290000,
    returnRate: 18,
    durationMonths: 30,
    expectedEndDate: DateTime(2028, 6),
    constructionPhase: 'Fase 3',
  ),

  // --- Completed investments (one per brand) ---

  // Andhy — completed
  InvestmentData(
    id: 'inv-c1',
    projectId: '11',
    projectName: 'Andhy I',
    brandName: 'Andhy',
    amount: 290000,
    returnRate: 14,
    durationMonths: 24,
    purchaseValue: 390000,
    cashPayment: 195000,
    mortgage: 195000,
    mortgageConditions: 'RF - 3,0%',
    monthlyPayment: 980,
    mortgageEndDate: DateTime(2046, 6),
    rentalIncome: 1900,
    revaluation: 8,
    unitName: 'Piso 2A',
    isCompleted: true,
  ),

  // Lacomb & Bos — completed
  InvestmentData(
    id: 'inv-c2',
    projectId: '1',
    projectName: 'Allegro',
    brandName: 'Lacomb & Bos',
    amount: 220000,
    returnRate: 22,
    durationMonths: 18,
    isCompleted: true,
  ),

  // Vellte — completed
  InvestmentData(
    id: 'inv-c3',
    projectId: '4',
    projectName: 'Cabriole 2',
    brandName: 'Vellte',
    amount: 310000,
    returnRate: 19,
    durationMonths: 24,
    isCompleted: true,
  ),

  // NUVE — completed
  InvestmentData(
    id: 'inv-c4',
    projectId: '5',
    projectName: 'SISONE',
    brandName: 'NUVE',
    amount: 150000,
    returnRate: 16,
    durationMonths: 20,
    isCompleted: true,
  ),

  // Domorato — completed
  InvestmentData(
    id: 'inv-c5',
    projectId: '6',
    projectName: 'SISONE II',
    brandName: 'Domorato',
    amount: 240000,
    returnRate: 20,
    durationMonths: 22,
    isCompleted: true,
  ),

  // Ciclo — completed
  InvestmentData(
    id: 'inv-c6',
    projectId: '13',
    projectName: 'Miami Shores',
    brandName: 'Ciclo',
    amount: 175000,
    returnRate: 17,
    durationMonths: 30,
    isCompleted: true,
  ),

  // Renta Fija — completed
  InvestmentData(
    id: 'inv-c7',
    projectId: '15',
    projectName: 'RF Capital I',
    brandName: 'Renta Fija',
    amount: 400000,
    returnRate: 4.5,
    durationMonths: 24,
    isCompleted: true,
  ),
];

/// Total patrimony across all investments.
double get totalPatrimony =>
    mockInvestments.fold(0, (sum, inv) => sum + inv.amount);

/// Group investments by brand with summary.
List<BrandInvestmentSummary> get brandSummaries {
  final grouped = <String, List<InvestmentData>>{};
  for (final inv in mockInvestments) {
    grouped.putIfAbsent(inv.brandName, () => []).add(inv);
  }

  return grouped.entries.map((entry) {
    final investments = entry.value;
    final total = investments.fold(0.0, (sum, inv) => sum + inv.amount);
    final avgReturn = investments.fold(0.0, (sum, inv) => sum + inv.returnRate) /
        investments.length;

    return BrandInvestmentSummary(
      brandName: entry.key,
      totalAmount: total,
      averageReturn: avgReturn,
      investments: investments,
    );
  }).toList();
}

/// Active (non-completed) investments.
List<BrandInvestmentSummary> get activeBrandSummaries {
  return brandSummaries
      .map((s) => BrandInvestmentSummary(
            brandName: s.brandName,
            totalAmount: s.investments
                .where((i) => !i.isCompleted)
                .fold(0.0, (sum, inv) => sum + inv.amount),
            averageReturn: s.averageReturn,
            investments:
                s.investments.where((i) => !i.isCompleted).toList(),
          ))
      .where((s) => s.investments.isNotEmpty)
      .toList();
}

/// Completed investments.
List<InvestmentData> get completedInvestments =>
    mockInvestments.where((i) => i.isCompleted).toList();
