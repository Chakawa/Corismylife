import 'package:flutter/material.dart';
import 'package:mycorislife/services/questionnaire_medical_service.dart';

/// Widget dynamique du questionnaire médical qui charge les questions depuis l'API
class QuestionnaireMedicalDynamicWidget extends StatefulWidget {
  final int? subscriptionId; // Pour charger des réponses existantes
  final Function(List<Map<String, dynamic>>) onValidated;
  final VoidCallback? onCancel;
  final bool showActions;
  final Function(Future<bool> Function())? registerValidate;
  final List<Map<String, dynamic>>? initialReponses; // Réponses pré-existantes à pré-remplir

  const QuestionnaireMedicalDynamicWidget({
    super.key,
    this.subscriptionId,
    required this.onValidated,
    this.onCancel,
    this.showActions = true,
    this.registerValidate,
    this.initialReponses,
  });

  @override
  State<QuestionnaireMedicalDynamicWidget> createState() =>
      _QuestionnaireMedicalDynamicWidgetState();
}

class _QuestionnaireMedicalDynamicWidgetState
    extends State<QuestionnaireMedicalDynamicWidget> {
  final QuestionnaireMedicalService _service = QuestionnaireMedicalService();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _questions = [];
  Map<String, Map<String, dynamic>> _reponses = {};

  Map<String, dynamic>? _getResp(dynamic questionId) {
    if (questionId == null) return null;
    return _reponses[questionId.toString()];
  }

  void _setResp(dynamic questionId, Map<String, dynamic> value) {
    if (questionId == null) return;
    _reponses[questionId.toString()] = value;
  }
  bool _isLoading = true;
  String? _errorMessage;

  // Charte graphique CORIS
  static const Color bleuCoris = Color(0xFF002B6B);
  static const Color rougeCoris = Color(0xFFE30613);
  static const Color bleuSecondaire = Color(0xFF1E4A8C);
  static const Color blanc = Colors.white;
  // fondCarte previously declared but unused; removed to avoid analyzer warnings
  static const Color grisTexte = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 5),
    );
    return picked;
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final questions = await _service.getQuestions();
      
      // Charger les réponses initiales pré-existantes (du parent)
      if (widget.initialReponses != null) {
        for (var reponse in widget.initialReponses!) {
          final qid = reponse['question_id'] ?? reponse['questionId'] ?? reponse['id'];
          if (qid != null) _setResp(qid, Map<String, dynamic>.from(reponse));
        }
      }
      
      // Charger les réponses existantes si subscriptionId fourni (depuis la base de données)
      if (widget.subscriptionId != null) {
        final reponses = await _service.getReponses(widget.subscriptionId!);
        if (reponses != null) {
          for (var reponse in reponses) {
            final qid = reponse['question_id'] ?? reponse['questionId'] ?? reponse['id'];
            if (qid != null) _setResp(qid, Map<String, dynamic>.from(reponse));
          }
        }
      }

      // Normalize fields (coerce 'obligatoire' to boolean)
      final normalized = questions.map((q) {
        final oblig = q['obligatoire'];
        bool obligBool = false;
        if (oblig is bool) obligBool = oblig;
        else if (oblig != null) {
          final s = oblig.toString().toLowerCase();
          obligBool = s == 't' || s == '1' || s == 'true';
        }
        q['obligatoire'] = obligBool;
        return q;
      }).toList();

      setState(() {
        _questions = normalized;
        _isLoading = false;
      });
      // Register validation callback so parent can trigger validation when needed
      if (widget.registerValidate != null) {
        widget.registerValidate!(_validateAndSubmitInternal);
      }
    } catch (e) {
      final errorMsg = e.toString();
      print('❌ Erreur détaillée: $e');
      setState(() {
        _errorMessage = errorMsg.contains('404')
            ? 'Endpoint non trouvé. Le serveur n\'a pas le questionnaire médical.'
            : errorMsg.contains('401') || errorMsg.contains('403')
                ? 'Erreur d\'authentification. Veuillez vous reconnecter.'
                : 'Erreur lors du chargement des questions: $e';
        _isLoading = false;
      });
    }
  }
  void _validateAndSubmit() {
    _validateAndSubmitInternal();
  }

  Future<bool> _validateAndSubmitInternal() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    // Préparer les réponses au format attendu par l'API
    List<Map<String, dynamic>> reponsesFormatted = [];
    
    for (var question in _questions) {
      final questionId = question['id'];
      final reponse = _getResp(questionId);
      
      if (reponse != null) {
        reponsesFormatted.add({
          'question_id': questionId,
          'reponse_oui_non': reponse['reponse_oui_non'],
          'reponse_text': reponse['reponse_text'],
          'reponse_detail_1': reponse['reponse_detail_1'],
          'reponse_detail_2': reponse['reponse_detail_2'],
          'reponse_detail_3': reponse['reponse_detail_3'],
        });
      } else if (question['obligatoire'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Question obligatoire non répondue: ${question['libelle']}'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    // Debug log to help trace validation flow
    print('✅ Questionnaire valid, réponses: $reponsesFormatted');
    widget.onValidated(reponsesFormatted);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Questionnaire Médical'),
          backgroundColor: bleuCoris,
          foregroundColor: blanc,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Questionnaire Médical'),
          backgroundColor: bleuCoris,
          foregroundColor: blanc,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: widget.showActions
          ? AppBar(
              title: const Text('Questionnaire Médical'),
              backgroundColor: bleuCoris,
              foregroundColor: blanc,
              leading: widget.onCancel != null
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: widget.onCancel,
                    )
                  : null,
            )
          : null,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // En-tête informatif
                    Container(
                      padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bleuSecondaire.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bleuSecondaire.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: bleuCoris),
                          SizedBox(width: 12),
                  Expanded(
                    child: Text(
                              'Veuillez répondre avec précision à toutes les questions. Ces informations sont essentielles pour votre couverture.',
                              style: TextStyle(fontSize: 14, color: grisTexte),
                    ),
                  ),
                ],
              ),
            ),
                    const SizedBox(height: 4),

            // Afficher chaque question dynamiquement
            ..._questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return _buildQuestionWidget(index + 1, question);
            }).toList(),

            const SizedBox(height: 12),

            // Boutons d'action (optionnels) — lorsqu'on utilise la navigation externe, masquez-les
            if (widget.showActions)
              Row(
                children: [
                  if (widget.onCancel != null)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: grisTexte),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                  if (widget.onCancel != null) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _validateAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bleuCoris,
                        foregroundColor: blanc,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Suivant',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWidget(int numero, Map<String, dynamic> question) {
    final questionId = question['id'];
    final typeQuestion = question['type_question'];
    final libelle = question['libelle'] ?? '';
    final obligatoire = question['obligatoire'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: blanc,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la question
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: bleuCoris,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$numero',
                    style: const TextStyle(
                      color: blanc,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      libelle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: bleuCoris,
                      ),
                    ),
                    if (obligatoire)
                      const Text(
                        '* Obligatoire',
                        style: TextStyle(
                          fontSize: 11,
                          color: rougeCoris,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Champs selon le type de question
          if (typeQuestion == 'taille_poids')
            _buildTaillePoidsFields(questionId, question)
          else if (typeQuestion == 'oui_non_details')
            _buildOuiNonDetailsFields(questionId, question, obligatoire),
        ],
      ),
    );
  }

  Widget _buildTaillePoidsFields(int questionId, Map<String, dynamic> question) {
    final reponse = _getResp(questionId) ?? {};
    
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: reponse['reponse_detail_1'] ?? '',
            decoration: InputDecoration(
              labelText: question['champ_detail_1_label'] ?? 'Taille (cm)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: blanc,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (question['obligatoire'] == true && (value == null || value.isEmpty)) {
                return 'Requis';
              }
              return null;
            },
              onChanged: (value) {
                setState(() {
                  _setResp(questionId, {
                    ...(_getResp(questionId) ?? {}),
                    'reponse_detail_1': value,
                    'reponse_text': '$value cm',
                  });
                });
              },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            initialValue: reponse['reponse_detail_2'] ?? '',
            decoration: InputDecoration(
              labelText: question['champ_detail_2_label'] ?? 'Poids (kg)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: blanc,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (question['obligatoire'] == true && (value == null || value.isEmpty)) {
                return 'Requis';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _setResp(questionId, {
                  ...(_getResp(questionId) ?? {}),
                  'reponse_detail_2': value,
                  'reponse_text': ((_getResp(questionId)?['reponse_text']) ?? '') + ', $value kg',
                });
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOuiNonDetailsFields(
      int questionId, Map<String, dynamic> question, bool obligatoire) {
    final reponse = _getResp(questionId) ?? {};
    final reponseOuiNon = reponse['reponse_oui_non'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Boutons OUI/NON
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _setResp(questionId, {
                      ...(_getResp(questionId) ?? {}),
                      'reponse_oui_non': 'OUI',
                    });
                  });
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: reponseOuiNon == 'OUI' ? rougeCoris : blanc,
                  foregroundColor: reponseOuiNon == 'OUI' ? blanc : rougeCoris,
                  side: BorderSide(
                    color: reponseOuiNon == 'OUI' ? rougeCoris : Colors.grey,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('OUI', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _setResp(questionId, {
                      ...(_getResp(questionId) ?? {}),
                      'reponse_oui_non': 'NON',
                      'reponse_detail_1': null,
                      'reponse_detail_2': null,
                      'reponse_detail_3': null,
                      'reponse_text': null,
                    });
                  });
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: reponseOuiNon == 'NON' ? Colors.green : blanc,
                  foregroundColor: reponseOuiNon == 'NON' ? blanc : Colors.green,
                  side: BorderSide(
                    color: reponseOuiNon == 'NON' ? Colors.green : Colors.grey,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('NON', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),

        // Champs de détails si OUI
        if (reponseOuiNon == 'OUI') ...[
          const SizedBox(height: 16),
          if (question['champ_detail_1_label'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDetailField(questionId, 'reponse_detail_1', question['champ_detail_1_label'], reponse?['reponse_detail_1'], obligatoire),
            ),
          if (question['champ_detail_2_label'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDetailField(questionId, 'reponse_detail_2', question['champ_detail_2_label'], reponse?['reponse_detail_2'], false),
            ),
          if (question['champ_detail_3_label'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildDetailField(questionId, 'reponse_detail_3', question['champ_detail_3_label'], reponse?['reponse_detail_3'], false),
            ),
        ],

        // Validation pour réponse obligatoire
        if (obligatoire && reponseOuiNon == null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Veuillez sélectionner OUI ou NON',
              style: TextStyle(color: rougeCoris, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailField(int questionId, String fieldKey, String? label, dynamic value, bool obligatoire) {
    final lowerLabel = (label ?? '').toLowerCase();
    // If the label suggests a date, render a date picker
    // Detect various date-related keywords: date, depuis, quand, à partir
    if (lowerLabel.contains('date') || 
      lowerLabel.contains('depuis') || 
      lowerLabel.contains('quand') || 
      lowerLabel.contains('à partir') ||
      lowerLabel.contains('a partir')) {
      return InkWell(
        onTap: () async {
          final parsed = DateTime.tryParse(value ?? '');
          final picked = await _pickDate(context, parsed);
          if (picked != null) {
            final iso = picked.toIso8601String();
            setState(() {
              _setResp(questionId, {
                ...(_getResp(questionId) ?? {}),
                fieldKey: iso,
                'reponse_text': (label ?? '') + ': ' + '${picked.day.toString().padLeft(2,'0')}/${picked.month.toString().padLeft(2,'0')}/${picked.year}'
              });
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: blanc,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            isDense: true,
          ),
          child: Text(value is String && value.isNotEmpty
              ? '${DateTime.tryParse(value)?.day.toString().padLeft(2,'0')}/${DateTime.tryParse(value)?.month.toString().padLeft(2,'0')}/${DateTime.tryParse(value)?.year}'
              : 'Sélectionner une date'),
        ),
      );
    }

    // Default: text input
    return TextFormField(
      initialValue: value ?? '',
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: blanc,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      ),
      maxLines: 1,
      validator: obligatoire ? (v) => (v == null || v.isEmpty) ? 'Requis' : null : null,
      onChanged: (v) {
        setState(() {
          _setResp(questionId, {
            ...(_getResp(questionId) ?? {}),
            fieldKey: v,
          });
        });
      },
    );
  }
}
