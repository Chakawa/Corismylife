import 'package:flutter/material.dart';
import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';
import 'package:mycorislife/models/contrat.dart';
import 'package:mycorislife/services/contrat_service.dart';

class ContractPaymentFlow {
  static const Color _bleuCoris = Color(0xFF002B6B);
  static const Color _bleuSecondaire = Color(0xFF1E4A8C);
  static const Color _fondCarte = Color(0xFFF8FAFC);
  static const Color _grisTexte = Color(0xFF64748B);

  static Future<void> showSearchAndAmountDialog(
    BuildContext context, {
    String? initialPolicyNumber,
    int? knownSubscriptionId,
    double? initialAmount,
    VoidCallback? onPaymentSuccess,
  }) async {
    final policyController =
        TextEditingController(text: initialPolicyNumber ?? '');
    final amountController = TextEditingController(
      text: initialAmount != null && initialAmount > 0
          ? initialAmount.toStringAsFixed(0)
          : '',
    );

    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              title: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [_bleuCoris, _bleuSecondaire],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.payments, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Payer mon contrat',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saisissez le numéro de police et le montant à payer.',
                    style: TextStyle(
                      color: _grisTexte,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: policyController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Numéro de police',
                      hintText: 'Ex: CI-2026-000123',
                      prefixIcon:
                          const Icon(Icons.badge_outlined, color: _bleuCoris),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE5F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE5F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _bleuCoris, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant (FCFA)',
                      hintText: 'Ex: 10000',
                      prefixIcon:
                          const Icon(Icons.attach_money, color: _bleuCoris),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE5F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFDDE5F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: _bleuCoris, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSearching
                              ? null
                              : () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _bleuCoris,
                            side: const BorderSide(color: _bleuCoris),
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Annuler',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isSearching
                              ? null
                              : () async {
                                  final numeroPolice =
                                      policyController.text.trim();
                                  final montant = double.tryParse(
                                      amountController.text.trim());

                                  if (numeroPolice.isEmpty) {
                                    _showInfo(
                                      context,
                                      'Veuillez saisir le numéro de police.',
                                      isError: true,
                                    );
                                    return;
                                  }

                                  if (montant == null || montant <= 0) {
                                    _showInfo(
                                      context,
                                      'Veuillez saisir un montant valide.',
                                      isError: true,
                                    );
                                    return;
                                  }

                                  setDialogState(() => isSearching = true);

                                  final contract = await _resolveContract(
                                    numeroPolice: numeroPolice,
                                    knownSubscriptionId: knownSubscriptionId,
                                  );

                                  if (!context.mounted) return;

                                  setDialogState(() => isSearching = false);

                                  if (contract == null) {
                                    _showInfo(
                                      context,
                                      'Aucun contrat trouvé pour ce numéro de police.',
                                      isError: true,
                                    );
                                    return;
                                  }

                                  Navigator.of(dialogContext).pop();

                                  final resolvedSubscriptionId =
                                      knownSubscriptionId ?? contract.id;

                                  await _showPaymentOptions(
                                    context,
                                    subscriptionId: resolvedSubscriptionId,
                                    numeroPolice:
                                        contract.numepoli ?? numeroPolice,
                                    montant: montant,
                                    onPaymentSuccess: onPaymentSuccess,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _bleuCoris,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isSearching
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Choisir le mode de paiement',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: const [
                SizedBox.shrink(),
              ],
              actionsPadding: const EdgeInsets.only(right: 0, bottom: 0),
              buttonPadding: EdgeInsets.zero,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              scrollable: true,
            );
          },
        );
      },
    );
  }

  static String _normalizePolicy(String value) {
    final lower = value.toLowerCase().trim();
    return lower.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static Future<Contrat?> _resolveContract({
    required String numeroPolice,
    required int? knownSubscriptionId,
  }) async {
    final service = ContratService();
    final contrats = await service.getContrats();

    final normalizedInput = _normalizePolicy(numeroPolice);
    if (normalizedInput.isEmpty) return null;

    if (knownSubscriptionId != null) {
      for (final contrat in contrats) {
        if (contrat.id == knownSubscriptionId) {
          return contrat;
        }
      }
    }

    for (final contrat in contrats) {
      final policy = _normalizePolicy(contrat.numepoli ?? '');
      if (policy == normalizedInput) {
        return contrat;
      }
    }

    for (final contrat in contrats) {
      final policy = _normalizePolicy(contrat.numepoli ?? '');
      if (policy.contains(normalizedInput) ||
          normalizedInput.contains(policy)) {
        return contrat;
      }
    }

    return null;
  }

  static Future<void> _showPaymentOptions(
    BuildContext context, {
    required int? subscriptionId,
    required String numeroPolice,
    required double montant,
    VoidCallback? onPaymentSuccess,
  }) async {
    if (subscriptionId == null) {
      _showInfo(
        context,
        'Ce contrat ne possède pas de référence de souscription exploitable.',
        isError: true,
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    children: [
                      Icon(Icons.payment, color: _bleuCoris, size: 28),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Options de Paiement',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: _bleuCoris,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Police: $numeroPolice • Montant: ${montant.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _grisTexte,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPaymentOptionWithImage(
                    context,
                    'Wave',
                    'assets/images/icone_wave.jpeg',
                    Colors.blue,
                    'Paiement mobile sécurisé',
                    onTap: () {
                      Navigator.pop(context);
                      _showInfo(
                        context,
                        'Paiement Wave bientôt disponible. Utilisez CORIS Money pour le moment.',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOptionWithImage(
                    context,
                    'Orange Money',
                    'assets/images/icone_orange_money.jpeg',
                    Colors.orange,
                    'Paiement mobile Orange',
                    onTap: () {
                      Navigator.pop(context);
                      _showInfo(
                        context,
                        'Paiement Orange Money bientôt disponible. Utilisez CORIS Money pour le moment.',
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOptionWithImage(
                    context,
                    'CORIS Money',
                    'assets/images/icone_corismoney.jpeg',
                    const Color(0xFF1E3A8A),
                    'Paiement via CORIS Money',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => CorisMoneyPaymentModal(
                          subscriptionId: subscriptionId,
                          montant: montant,
                          description:
                              'Paiement contrat $numeroPolice (${montant.toStringAsFixed(0)} FCFA)',
                          onPaymentSuccess: () {
                            _showInfo(
                                context, 'Paiement effectué avec succès.');
                            onPaymentSuccess?.call();
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildPaymentOptionWithImage(
    BuildContext context,
    String title,
    String imagePath,
    Color color,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _fondCarte,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Image.asset(
                imagePath,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.image_not_supported,
                  size: 32,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _bleuCoris,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _grisTexte,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: _grisTexte, size: 16),
          ],
        ),
      ),
    );
  }

  static void _showInfo(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : _bleuCoris,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
