class Bank {
  const Bank({
    required this.id,
    required this.name,
    required this.countryCode,
    required this.supportLevel,
  });

  final String id;
  final String name;
  final String countryCode;
  final BankSupportLevel supportLevel;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'countryCode': countryCode,
    'supportLevel': supportLevel.name,
  };

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] as String,
      name: json['name'] as String,
      countryCode: json['countryCode'] as String,
      supportLevel: BankSupportLevel.values.firstWhere(
        (level) => level.name == json['supportLevel'],
        orElse: () => BankSupportLevel.requested,
      ),
    );
  }
}

enum BankSupportLevel { templateReady, beta, requested }

const launchBanks = [
  Bank(
    id: 'ae_emirates_nbd',
    name: 'Emirates NBD',
    countryCode: 'AE',
    supportLevel: BankSupportLevel.beta,
  ),
  Bank(
    id: 'ae_adcb',
    name: 'ADCB',
    countryCode: 'AE',
    supportLevel: BankSupportLevel.beta,
  ),
  Bank(
    id: 'ae_fab',
    name: 'FAB',
    countryCode: 'AE',
    supportLevel: BankSupportLevel.requested,
  ),
  Bank(
    id: 'ae_mashreq',
    name: 'Mashreq',
    countryCode: 'AE',
    supportLevel: BankSupportLevel.requested,
  ),
  Bank(
    id: 'ae_dib',
    name: 'Dubai Islamic Bank',
    countryCode: 'AE',
    supportLevel: BankSupportLevel.requested,
  ),
];
