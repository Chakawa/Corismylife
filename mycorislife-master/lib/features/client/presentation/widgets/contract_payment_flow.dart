import 'package:flutter/material.dart';
import 'package:mycorislife/models/contrat.dart';
import 'package:mycorislife/services/contrat_service.dart';
import 'package:mycorislife/core/utils/error_message_helper.dart';
import 'package:mycorislife/services/wave_service.dart';
import 'package:mycorislife/utils/test_mode_helper.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:mycorislife/services/orange_money_payment_handler.dart';
// import 'package:mycorislife/core/widgets/corismoney_payment_modal.dart';

class ContractPaymentFlow {
  static const Color _bleuCoris = Color(0xFF002B6B);

  static const Color _bleuSecondaire = Color(0xFF1E4A8C);

  static const Color _fondCarte = Color(0xFFF8FAFC);

  static const Color _grisTexte = Color(0xFF64748B);

  static Future<void> showSearchAndAmountDialog(
    BuildContext context, {
    String? initialPolicyNumber,
    String? initialCodeinte,
    String? initialSource,
    int? knownSubscriptionId,
    double? initialAmount,
    bool skipSearchDialog = false,
    VoidCallback? onPaymentSuccess,
  }) async {
    if (skipSearchDialog) {
      final numeroPolice = (initialPolicyNumber ?? '').trim();
      final montant = initialAmount;
      if (numeroPolice.isEmpty) {
        _showInfo(
          context,
          'Numéro de police manquant pour le paiement.',
          isError: true,
        );
        return;
      }
      if (montant == null || montant <= 0) {
        _showInfo(
          context,
          'Montant invalide pour le paiement.',
          isError: true,
        );
        return;
      }

      final effectiveMontant = TestModeHelper.applyTestModeIfNeeded(
        montant,
        context: 'ContractPaymentFlow.skipSearchDialog',
      );

      final contract = await _resolveContract(
        numeroPolice: numeroPolice,
        knownSubscriptionId: knownSubscriptionId,
        codeinte: initialCodeinte,
      );

      if (!context.mounted) return;

      if (contract == null) {
        _showInfo(
          context,
          'Aucun contrat trouvé pour ce numéro de police.',
          isError: true,
        );
        return;
      }

      int? resolvedSubscriptionId;
      if (knownSubscriptionId != null) {
        // Si knownSubscriptionId correspond bien à une subscriptionId (et non à l'id du contrat),
        // on l'utilise uniquement dans ce cas.
        if (contract.subscriptionId != null && contract.subscriptionId == knownSubscriptionId) {
          resolvedSubscriptionId = knownSubscriptionId;
        } else {
          resolvedSubscriptionId = null;
        }
      } else {
        resolvedSubscriptionId = contract.subscriptionId;
      }

      if (resolvedSubscriptionId == null) {
        // Pas de subscriptionId — on tente quand même le paiement via numéro de police et codeinte.
        await _showPaymentOptions(
          context,
          subscriptionId: null,
          numeroPolice: contract.numepoli ?? numeroPolice,
          codeinte: contract.codeinte,
          montant: effectiveMontant,
          onPaymentSuccess: onPaymentSuccess,
        );
        return;
      }

      await _showPaymentOptions(
        context,
        subscriptionId: resolvedSubscriptionId,
        numeroPolice: contract.numepoli ?? numeroPolice,
        codeinte: contract.codeinte,
        montant: effectiveMontant,
        onPaymentSuccess: onPaymentSuccess,
      );
      return;
    }

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
                        'Payer mes cotisations',
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

                                  // Forçage 10 XOF en mode test (tous produits).
                                  final effectiveMontant =
                                      TestModeHelper.applyTestModeIfNeeded(
                                    montant,
                                    context: 'ContractPaymentFlow.searchDialog',
                                  );

                                  setDialogState(() => isSearching = true);

                                  final contract = await _resolveContract(
                                    numeroPolice: numeroPolice,
                                    knownSubscriptionId: knownSubscriptionId,
                                    codeinte: initialCodeinte,
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

                                  int? resolvedSubscriptionId;
                                  if (knownSubscriptionId != null) {
                                    if (contract.subscriptionId != null && contract.subscriptionId == knownSubscriptionId) {
                                      resolvedSubscriptionId = knownSubscriptionId;
                                    } else {
                                      resolvedSubscriptionId = null;
                                    }
                                  } else {
                                    resolvedSubscriptionId = contract.subscriptionId;
                                  }

                                  if (resolvedSubscriptionId == null) {
                                    // Pas de subscriptionId — on tente le paiement via numéro de police et codeinte.
                                    await _showPaymentOptions(
                                      context,
                                      subscriptionId: null,
                                      numeroPolice: contract.numepoli ?? numeroPolice,
                                      codeinte: contract.codeinte,
                                      montant: effectiveMontant,
                                      onPaymentSuccess: onPaymentSuccess,
                                    );
                                    return;
                                  }

                                  await _showPaymentOptions(
                                    context,
                                    subscriptionId: resolvedSubscriptionId,
                                    numeroPolice:
                                        contract.numepoli ?? numeroPolice,
                                    codeinte: contract.codeinte,
                                    montant: effectiveMontant,
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
    String? codeinte,
  }) async {
    final service = ContratService();
    final contrats = await service.getContrats();

    final normalizedInput = _normalizePolicy(numeroPolice);
    if (normalizedInput.isEmpty) return null;

    final normalizedCodeinte = (codeinte ?? '').trim().toUpperCase();

    if (knownSubscriptionId != null) {
      for (final contrat in contrats) {
        if (contrat.id == knownSubscriptionId ||
            contrat.subscriptionId == knownSubscriptionId) {
          return contrat;
        }
      }
    }

    bool matchesPolicy(Contrat contrat) {
      final policy = _normalizePolicy(contrat.numepoli ?? '');
      if (policy != normalizedInput) return false;
      if (normalizedCodeinte.isEmpty) return true;
      final contratCodeinte = (contrat.codeinte ?? '').trim().toUpperCase();
      return contratCodeinte == normalizedCodeinte;
    }

    for (final contrat in contrats) {
      if (matchesPolicy(contrat)) {
        return contrat;
      }
    }

    if (normalizedCodeinte.isNotEmpty) {
      for (final contrat in contrats) {
        final policy = _normalizePolicy(contrat.numepoli ?? '');
        if (policy.contains(normalizedInput) ||
            normalizedInput.contains(policy)) {
          final contratCodeinte = (contrat.codeinte ?? '').trim().toUpperCase();
          if (contratCodeinte == normalizedCodeinte) {
            return contrat;
          }
        }
      }
    }

    if (normalizedCodeinte.isNotEmpty) {
      return null;
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
    String? codeinte,
    required double montant,
    VoidCallback? onPaymentSuccess,
  }) async {
    // On autorise le paiement même si la `subscriptionId` est absente:
    // dans ce cas, la création de session Wave se fera via `numeroPolice`.

    final parentContext = context;

    await showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
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
                      style: TextStyle(
                        fontSize: 13,
                        color: _grisTexte,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildPaymentOptionWithImage(
                    sheetContext,
                    'Wave',
                    'assets/images/icone_wave.jpeg',
                    Colors.blue,
                    'Paiement mobile sécurisé',
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await _startWavePayment(
                        parentContext,
                        subscriptionId: subscriptionId,
                        numeroPolice: numeroPolice,
                        codeinte: codeinte,
                        montant: montant,
                        onPaymentSuccess: onPaymentSuccess,
                      );
                    },
                  ),
                  // const SizedBox(height: 12),
                  // _buildPaymentOptionWithImage(
                  //   context,
                  //   'Orange Money',
                  //   'assets/images/icone_orange_money.jpeg',
                  //   Colors.orange,
                  //   'Paiement mobile Orange',
                  //   onTap: () async {
                  //     Navigator.pop(context);
                  //     try {
                  //       await OrangeMoneyPaymentHandler.startPayment(
                  //         context,
                  //         subscriptionId: subscriptionId!,
                  //         amount: montant,
                  //         description:
                  //             'Paiement contrat $numeroPolice (${montant.toStringAsFixed(0)} FCFA)',
                  //         onSuccess: () {
                  //           onPaymentSuccess?.call();
                  //         },
                  //       );
                  //     } catch (e) {
                  //       _showInfo(context, 'Erreur lancement Orange Money: $e', isError: true);
                  //     }
                  //   },
                  // ),
                  // const SizedBox(height: 12),
                  // _buildPaymentOptionWithImage(
                  //   context,
                  //   'CORIS Money',
                  //   'assets/images/icone_corismoney.jpeg',
                  //   const Color(0xFF1E3A8A),
                  //   'Paiement via CORIS Money',
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     showDialog(
                  //       context: context,
                  //       barrierDismissible: false,
                  //       builder: (_) => CorisMoneyPaymentModal(
                  //         subscriptionId: subscriptionId,
                  //         montant: montant,
                  //         description:
                  //             'Paiement contrat $numeroPolice (${montant.toStringAsFixed(0)} FCFA)',
                  //         onPaymentSuccess: () {
                  //           _showInfo(
                  //               context, 'Paiement effectué avec succès.');
                  //           onPaymentSuccess?.call();
                  //         },
                  //       ),
                  //     );
                  //   },
                  // ),
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
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _bleuCoris,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
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

  static Future<void> _startWavePayment(
    BuildContext context, {
    int? subscriptionId,
    String? numeroPolice,
    String? codeinte,
    required double montant,
    VoidCallback? onPaymentSuccess,
  }) async {
    try {
      if (!context.mounted) return;

      final waveService = WaveService();

      _showInfo(context, 'Initialisation du paiement Wave...');

      final createResult = await waveService.createCheckoutSession(
        subscriptionId: subscriptionId,
        amount: montant,
        description:
            'Paiement contrat ${numeroPolice ?? ''} (${montant.toStringAsFixed(0)} FCFA)',
        numeroPolice: numeroPolice,
        codeinte: codeinte,
      );

      if (!context.mounted) return;

      if (!(createResult['success'] == true)) {
        _showInfo(
          context,
          ErrorMessageHelper.sanitizeServerMessage(
            createResult['message']?.toString(),
            fallback: ErrorMessageHelper.paymentFailed,
          ),
          isError: true,
        );
        return;
      }

      final data = createResult['data'] as Map<String, dynamic>? ?? {};
      final launchUrlValue = data['launchUrl']?.toString();
      final sessionId = data['sessionId']?.toString() ?? '';
      final transactionId = data['transactionId']?.toString();

      if (launchUrlValue == null ||
          launchUrlValue.isEmpty ||
          sessionId.isEmpty) {
        _showInfo(
          context,
          ErrorMessageHelper.paymentIncomplete,
          isError: true,
        );
        return;
      }

      final waveUri = Uri.tryParse(launchUrlValue);
      if (waveUri == null) {
        _showInfo(context, 'URL Wave invalide.', isError: true);
        return;
      }

      bool launched = false;
      if (await canLaunchUrl(waveUri)) {
        launched = await launchUrl(
          waveUri,
          mode: LaunchMode.externalApplication,
        );
      }

      if (!launched) {
        launched = await launchUrl(
          waveUri,
          mode: LaunchMode.platformDefault,
        );
      }

      if (!launched) {
        launched = await launchUrl(
          waveUri,
          mode: LaunchMode.inAppWebView,
        );
      }

      if (!launched) {
        _showInfo(
          context,
          'Impossible d\'ouvrir l\'application Wave. Vérifiez qu\'elle est installée.',
          isError: true,
        );
        return;
      }

      if (!context.mounted) return;

      _showInfo(
        context,
        'Paiement Wave lancé. Retournez à l\'application après paiement.',
      );

      for (int attempt = 0; attempt < 40; attempt++) {
        await Future.delayed(const Duration(seconds: 3));

        if (!context.mounted) return;

        final statusResult = await waveService.getCheckoutStatus(
          sessionId: sessionId,
          subscriptionId: subscriptionId,
          transactionId: transactionId,
        );

        if (!(statusResult['success'] == true)) {
          continue;
        }

        final statusData = statusResult['data'] as Map<String, dynamic>? ?? {};
        final status = (statusData['status'] ?? '').toString().toUpperCase();

        if (status == 'SUCCESS') {
          // Si nous avons une subscriptionId, tenter la confirmation serveur.
          if (subscriptionId != null) {
            try {
              final confirmResult = await waveService.confirmWavePayment(subscriptionId);
              if (confirmResult['success'] == true) {
                _showInfo(context, 'Paiement Wave confirmé avec succès.');
                onPaymentSuccess?.call();
                return;
              } else {
                _showInfo(context, 'Paiement Wave confirmé localement. Vérifiez la confirmation serveur.',);
                onPaymentSuccess?.call();
                return;
              }
            } catch (_) {
              _showInfo(context, 'Paiement Wave confirmé localement. Vérifiez la confirmation serveur.',);
              onPaymentSuccess?.call();
              return;
            }
          } else {
            _showInfo(context, 'Paiement Wave confirmé (numéro police).');
            onPaymentSuccess?.call();
            return;
          }
        }

        if (status == 'FAILED') {
          _showInfo(
            context,
            'Le paiement Wave a échoué ou a été annulé.',
            isError: true,
          );
          return;
        }
      }

      if (!context.mounted) return;

      _showInfo(
        context,
        'Paiement initié. Confirmation en attente, vérifiez à nouveau dans quelques instants.',
      );
    } catch (e) {
      if (!context.mounted) return;

      _showInfo(
        context,
        ErrorMessageHelper.forUser(
          e,
          fallback: ErrorMessageHelper.paymentFailed,
          context: 'ContractPaymentFlow._startWavePayment',
        ),
        isError: true,
      );
    }
  }
}
