import 'package:flutter/material.dart';
import 'package:mycorislife/config/theme.dart';

/// Widget de questionnaire médical pour Coris Sérénité, Familis et Étude
class QuestionnaireMedicalWidget extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSaved;

  const QuestionnaireMedicalWidget({
    super.key,
    this.initialData,
    required this.onSaved,
  });

  @override
  State<QuestionnaireMedicalWidget> createState() =>
      _QuestionnaireMedicalWidgetState();
}

class _QuestionnaireMedicalWidgetState
    extends State<QuestionnaireMedicalWidget> {
  final _formKey = GlobalKey<FormState>();

  // Question 1: Taille et Poids
  final _tailleController = TextEditingController();
  final _poidsController = TextEditingController();

  // Question 2: Interruption travail
  bool? _q2Reponse;
  final _q2DatesController = TextEditingController();
  final _q2MotifsController = TextEditingController();

  // Question 3: Traitement médical
  bool? _q3Reponse;
  final _q3LequelController = TextEditingController();
  final _q3DepuisController = TextEditingController();

  // Question 4: Intervention chirurgicale
  bool? _q4Reponse;
  final _q4DateController = TextEditingController();
  final _q4MotifsController = TextEditingController();

  // Question 5: Infirmité/invalidité
  bool? _q5Reponse;
  final _q5LaquelleController = TextEditingController();
  final _q5DepuisController = TextEditingController();

  // Question 6: Maladies connues
  bool? _q6Reponse;
  final _q6LesquellesController = TextEditingController();
  final _q6DepuisController = TextEditingController();

  // Question 7: Infections respiratoires
  bool? _q7Reponse;
  final _q7DepuisController = TextEditingController();

  // Question 8: Dépressions/troubles psycho
  bool? _q8Reponse;
  final _q8CombienController = TextEditingController();
  final _q8QuandController = TextEditingController();

  // Question 9: Test VIH
  bool? _q9Reponse;
  final _q9DateController = TextEditingController();
  final _q9ResultatController = TextEditingController();

  // Question 10: Test hépatite
  bool? _q10Reponse;
  final _q10DatesController = TextEditingController();
  final _q10ResultatsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    if (widget.initialData != null) {
      final data = widget.initialData!;
      _tailleController.text = data['taille'] ?? '';
      _poidsController.text = data['poids'] ?? '';
      
      _q2Reponse = data['q2_reponse'];
      _q2DatesController.text = data['q2_dates'] ?? '';
      _q2MotifsController.text = data['q2_motifs'] ?? '';
      
      _q3Reponse = data['q3_reponse'];
      _q3LequelController.text = data['q3_lequel'] ?? '';
      _q3DepuisController.text = data['q3_depuis'] ?? '';
      
      _q4Reponse = data['q4_reponse'];
      _q4DateController.text = data['q4_date'] ?? '';
      _q4MotifsController.text = data['q4_motifs'] ?? '';
      
      _q5Reponse = data['q5_reponse'];
      _q5LaquelleController.text = data['q5_laquelle'] ?? '';
      _q5DepuisController.text = data['q5_depuis'] ?? '';
      
      _q6Reponse = data['q6_reponse'];
      _q6LesquellesController.text = data['q6_lesquelles'] ?? '';
      _q6DepuisController.text = data['q6_depuis'] ?? '';
      
      _q7Reponse = data['q7_reponse'];
      _q7DepuisController.text = data['q7_depuis'] ?? '';
      
      _q8Reponse = data['q8_reponse'];
      _q8CombienController.text = data['q8_combien'] ?? '';
      _q8QuandController.text = data['q8_quand'] ?? '';
      
      _q9Reponse = data['q9_reponse'];
      _q9DateController.text = data['q9_date'] ?? '';
      _q9ResultatController.text = data['q9_resultat'] ?? '';
      
      _q10Reponse = data['q10_reponse'];
      _q10DatesController.text = data['q10_dates'] ?? '';
      _q10ResultatsController.text = data['q10_resultats'] ?? '';
    }
  }

  @override
  void dispose() {
    _tailleController.dispose();
    _poidsController.dispose();
    _q2DatesController.dispose();
    _q2MotifsController.dispose();
    _q3LequelController.dispose();
    _q3DepuisController.dispose();
    _q4DateController.dispose();
    _q4MotifsController.dispose();
    _q5LaquelleController.dispose();
    _q5DepuisController.dispose();
    _q6LesquellesController.dispose();
    _q6DepuisController.dispose();
    _q7DepuisController.dispose();
    _q8CombienController.dispose();
    _q8QuandController.dispose();
    _q9DateController.dispose();
    _q9ResultatController.dispose();
    _q10DatesController.dispose();
    _q10ResultatsController.dispose();
    super.dispose();
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  Map<String, dynamic> getData() {
    return {
      'taille': _tailleController.text.trim(),
      'poids': _poidsController.text.trim(),
      'q2_reponse': _q2Reponse,
      'q2_dates': _q2DatesController.text.trim(),
      'q2_motifs': _q2MotifsController.text.trim(),
      'q3_reponse': _q3Reponse,
      'q3_lequel': _q3LequelController.text.trim(),
      'q3_depuis': _q3DepuisController.text.trim(),
      'q4_reponse': _q4Reponse,
      'q4_date': _q4DateController.text.trim(),
      'q4_motifs': _q4MotifsController.text.trim(),
      'q5_reponse': _q5Reponse,
      'q5_laquelle': _q5LaquelleController.text.trim(),
      'q5_depuis': _q5DepuisController.text.trim(),
      'q6_reponse': _q6Reponse,
      'q6_lesquelles': _q6LesquellesController.text.trim(),
      'q6_depuis': _q6DepuisController.text.trim(),
      'q7_reponse': _q7Reponse,
      'q7_depuis': _q7DepuisController.text.trim(),
      'q8_reponse': _q8Reponse,
      'q8_combien': _q8CombienController.text.trim(),
      'q8_quand': _q8QuandController.text.trim(),
      'q9_reponse': _q9Reponse,
      'q9_date': _q9DateController.text.trim(),
      'q9_resultat': _q9ResultatController.text.trim(),
      'q10_reponse': _q10Reponse,
      'q10_dates': _q10DatesController.text.trim(),
      'q10_resultats': _q10ResultatsController.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fontSize = size.width * 0.04;
    final padding = size.width * 0.04;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [bleuCoris, Color(0xFF0041A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(fontSize * 0.6),
              ),
              child: Row(
                children: [
                  Icon(Icons.medical_information,
                      color: Colors.white, size: fontSize * 2),
                  SizedBox(width: padding),
                  Expanded(
                    child: Text(
                      'Questionnaire Médical',
                      style: TextStyle(
                        fontSize: fontSize * 1.2,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: fontSize),

            // Question 1: Taille et Poids
            _buildQuestionCard(
              1,
              'Votre taille et poids',
              fontSize,
              padding,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tailleController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Taille (cm)',
                          hintText: 'Ex: 175',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fontSize * 0.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: padding),
                    Expanded(
                      child: TextFormField(
                        controller: _poidsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Poids (kg)',
                          hintText: 'Ex: 70',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(fontSize * 0.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requis';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Question 2
            _buildQuestionWithOuiNon(
              2,
              'Au cours des 5 dernières années, avez-vous dû interrompre votre travail plus de 30 jours consécutifs par maladie ou accident ?',
              _q2Reponse,
              (value) => setState(() => _q2Reponse = value),
              fontSize,
              padding,
              detailsFields: [
                TextFormField(
                  controller: _q2DatesController,
                  decoration: InputDecoration(
                    labelText: 'À quelles dates ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q2Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser les dates';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fontSize * 0.5),
                TextFormField(
                  controller: _q2MotifsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Pour quels motifs ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q2Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser les motifs';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Question 3
            _buildQuestionWithOuiNon(
              3,
              'Suivez-vous actuellement un traitement médical ou un régime quelconque ?',
              _q3Reponse,
              (value) => setState(() => _q3Reponse = value),
              fontSize,
              padding,
              detailsFields: [
                TextFormField(
                  controller: _q3LequelController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Lequel ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q3Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fontSize * 0.5),
                TextFormField(
                  controller: _q3DepuisController,
                  decoration: InputDecoration(
                    labelText: 'Depuis quand ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q3Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Question 4
            _buildQuestionWithOuiNon(
              4,
              'Avez-vous ou devez-vous subir une intervention chirurgicale ?',
              _q4Reponse,
              (value) => setState(() => _q4Reponse = value),
              fontSize,
              padding,
              detailsFields: [
                TextFormField(
                  controller: _q4DateController,
                  decoration: InputDecoration(
                    labelText: 'À quelle date ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q4Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser la date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fontSize * 0.5),
                TextFormField(
                  controller: _q4MotifsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Pour quels motifs ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q4Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser les motifs';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Question 5
            _buildQuestionWithOuiNon(
              5,
              'Êtes-vous atteint d\'infirmité, d\'une invalidité ou d\'une maladie chronique quelconque ?',
              _q5Reponse,
              (value) => setState(() => _q5Reponse = value),
              fontSize,
              padding,
              detailsFields: [
                TextFormField(
                  controller: _q5LaquelleController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Laquelle ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q5Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fontSize * 0.5),
                TextFormField(
                  controller: _q5DepuisController,
                  decoration: InputDecoration(
                    labelText: 'Depuis quand ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q5Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Question 6
            _buildQuestionWithOuiNon(
              6,
              'Avez-vous des maladies quelconques dont vous avez connaissance ?',
              _q6Reponse,
              (value) => setState(() => _q6Reponse = value),
              fontSize,
              padding,
              detailsFields: [
                TextFormField(
                  controller: _q6LesquellesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Lesquelles ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q6Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fontSize * 0.5),
                TextFormField(
                  controller: _q6DepuisController,
                  decoration: InputDecoration(
                    labelText: 'Depuis quand ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q6Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Question 7
            _buildQuestionWithOuiNon(
              7,
              'Avez-vous eu ces 3 dernières années des infections chroniques des voies respiratoires ?',
              _q7Reponse,
              (value) => setState(() => _q7Reponse = value),
              fontSize,
              padding,
              detailsFields: [
                TextFormField(
                  controller: _q7DepuisController,
                  decoration: InputDecoration(
                    labelText: 'Depuis quand ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q7Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Question 8
            _buildQuestionWithOuiNon(
              8,
              'Avez-vous eu au cours de ces 3 dernières années des dépressions ou autres troubles psycho neurologiques sans cause connue ?',
              _q8Reponse,
              (value) => setState(() => _q8Reponse = value),
              fontSize,
              padding,
              detailsFields: [
                TextFormField(
                  controller: _q8CombienController,
                  decoration: InputDecoration(
                    labelText: 'Combien ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q8Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fontSize * 0.5),
                TextFormField(
                  controller: _q8QuandController,
                  decoration: InputDecoration(
                    labelText: 'Quand ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q8Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Question 9
            _buildQuestionWithOuiNon(
              9,
              'Avez-vous fait le test de dépistage du VIH ?',
              _q9Reponse,
              (value) => setState(() => _q9Reponse = value),
              fontSize,
              padding,
              detailsFields: [
                TextFormField(
                  controller: _q9DateController,
                  decoration: InputDecoration(
                    labelText: 'Date du dernier test ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q9Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser la date';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fontSize * 0.5),
                TextFormField(
                  controller: _q9ResultatController,
                  decoration: InputDecoration(
                    labelText: 'Quel est le résultat ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q9Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser le résultat';
                    }
                    return null;
                  },
                ),
              ],
            ),

            // Question 10
            _buildQuestionWithOuiNon(
              10,
              'Avez-vous fait le test d\'hépatite B et/ou C ?',
              _q10Reponse,
              (value) => setState(() => _q10Reponse = value),
              fontSize,
              padding,
              detailsFields: [
                TextFormField(
                  controller: _q10DatesController,
                  decoration: InputDecoration(
                    labelText: 'Dates des derniers tests ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q10Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser les dates';
                    }
                    return null;
                  },
                ),
                SizedBox(height: fontSize * 0.5),
                TextFormField(
                  controller: _q10ResultatsController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Quels résultats ?',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fontSize * 0.5),
                    ),
                  ),
                  validator: (value) {
                    if (_q10Reponse == true &&
                        (value == null || value.isEmpty)) {
                      return 'Veuillez préciser les résultats';
                    }
                    return null;
                  },
                ),
              ],
            ),

            SizedBox(height: fontSize * 2),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    int numero,
    String question,
    double fontSize,
    double padding, {
    List<Widget> children = const [],
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: padding),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(fontSize * 0.6),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: fontSize * 1.8,
                  height: fontSize * 1.8,
                  decoration: const BoxDecoration(
                    color: bleuCoris,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      numero.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: padding * 0.5),
                Expanded(
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: fontSize * 0.9,
                      fontWeight: FontWeight.w600,
                      color: bleuCoris,
                    ),
                  ),
                ),
              ],
            ),
            if (children.isNotEmpty) ...[
              SizedBox(height: padding),
              ...children,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionWithOuiNon(
    int numero,
    String question,
    bool? reponse,
    Function(bool?) onChanged,
    double fontSize,
    double padding, {
    List<Widget> detailsFields = const [],
  }) {
    return _buildQuestionCard(
      numero,
      question,
      fontSize,
      padding,
      children: [
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: Text('OUI', style: TextStyle(fontSize: fontSize * 0.9)),
                value: true,
                groupValue: reponse,
                onChanged: onChanged,
                activeColor: bleuCoris,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: Text('NON', style: TextStyle(fontSize: fontSize * 0.9)),
                value: false,
                groupValue: reponse,
                onChanged: onChanged,
                activeColor: bleuCoris,
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ),
          ],
        ),
        if (reponse == true && detailsFields.isNotEmpty) ...[
          SizedBox(height: padding * 0.5),
          Container(
            padding: EdgeInsets.all(padding * 0.8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(fontSize * 0.5),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: detailsFields,
            ),
          ),
        ],
        if (reponse == null)
          Padding(
            padding: EdgeInsets.only(top: padding * 0.5),
            child: Text(
              'Veuillez sélectionner OUI ou NON',
              style: TextStyle(
                color: rougeCoris,
                fontSize: fontSize * 0.7,
              ),
            ),
          ),
      ],
    );
  }
}
