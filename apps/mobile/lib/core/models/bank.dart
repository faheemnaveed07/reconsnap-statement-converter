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
