/// Clé de référence contrat pour la table `payment_transactions.numero_police`.
class ContractPoliceKey {
  ContractPoliceKey._();

  static bool isLegacyContrat({
    String? source,
    String? codeinte,
  }) {
    final src = (source ?? '').toLowerCase().trim();
    if (src == 'legacy') return true;
    return (codeinte ?? '').trim().isNotEmpty;
  }

  static bool isAppSubscriptionContrat({
    String? source,
    int? subscriptionId,
    String? codeinte,
  }) {
    final src = (source ?? '').toLowerCase().trim();
    final hasSubscriptionId = subscriptionId != null;
    final hasLegacyCode = (codeinte ?? '').trim().isNotEmpty;
    return src == 'subscription' && hasSubscriptionId && !hasLegacyCode;
  }

  /// Legacy : `NUMEPOLI-CODEINTE`. Souscription app : `numepoli` seul.
  static String build({
    String? numepoli,
    String? codeinte,
    String? source,
    int? subscriptionId,
  }) {
    final police = (numepoli ?? '').trim();
    if (police.isEmpty) return '';

    if (isAppSubscriptionContrat(
      source: source,
      subscriptionId: subscriptionId,
      codeinte: codeinte,
    )) {
      return police.toUpperCase();
    }

    final inte = (codeinte ?? '').trim();
    if (inte.isNotEmpty) {
      return '${police.toUpperCase()}-${inte.toUpperCase()}';
    }
    return police.toUpperCase();
  }
}
