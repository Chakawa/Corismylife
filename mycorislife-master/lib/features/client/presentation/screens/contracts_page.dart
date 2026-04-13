import 'package:flutter/material.dart';
import 'package:mycorislife/core/utils/responsive.dart';
import 'package:mycorislife/services/contract_service.dart';

/// Ã‰cran d'affichage de tous les contrats de l'utilisateur
class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});

  @override
  State<ContractsPage> createState() => _ContractsPageState();
}

class _ContractsPageState extends State<ContractsPage> {
  final ContractService _contractService = ContractService();
  
  List<dynamic> _contracts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _contractService.getContracts();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _contracts = result['contracts'] ?? [];
        } else {
          _errorMessage = result['error'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Contrats'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _contracts.isEmpty
                  ? _buildEmptyView()
                  : _buildContractsList(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            SizedBox(height: context.r(16)),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: context.sp(16)),
            ),
            SizedBox(height: context.r(24)),
            ElevatedButton(
              onPressed: _loadContracts,
              child: Text('RÃ©essayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
            SizedBox(height: context.r(16)),
            Text(
              'Aucun contrat actif',
              style: TextStyle(fontSize: context.sp(18), fontWeight: FontWeight.bold),
            ),
            SizedBox(height: context.r(8)),
            Text(
              'Vos contrats d\'assurance apparaÃ®tront ici aprÃ¨s validation de paiement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractsList() {
    return RefreshIndicator(
      onRefresh: _loadContracts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _contracts.length,
        itemBuilder: (context, index) {
          final contract = _contracts[index];
          return _buildContractCard(contract);
        },
      ),
    );
  }

  Widget _buildContractCard(Map<String, dynamic> contract) {
    final paymentStatusInfo = _contractService.formatPaymentStatus(
      contract['payment_status']
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openContractDetails(contract['id']),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tÃªte avec numÃ©ro de contrat
              Row(
                children: [
                  Expanded(
                    child: Text(
                      contract['contract_number'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: context.sp(14),
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1976D2),
                      ),
                    ),
                  ),
                  _buildStatusChip(contract['status']),
                ],
              ),
              SizedBox(height: context.r(12)),
              
              // Nom du produit
              Text(
                contract['product_name'] ?? 'Produit',
                style: TextStyle(
                  fontSize: context.sp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: context.r(8)),
              
              // Montant et pÃ©riodicitÃ©
              Row(
                children: [
                  const Icon(Icons.payments, size: 16, color: Colors.grey),
                  SizedBox(width: context.r(8)),
                  Text(
                    _contractService.formatAmount(contract['amount']),
                    style: TextStyle(
                      fontSize: context.sp(16),
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  SizedBox(width: context.r(8)),
                  Text(
                    '/ ${_contractService.formatPeriodicite(contract['periodicite'])}',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              SizedBox(height: context.r(12)),
              
              // Date de prochain paiement
              if (contract['next_payment_date'] != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(paymentStatusInfo['color']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: Color(paymentStatusInfo['color']),
                      ),
                      SizedBox(width: context.r(8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Prochain paiement',
                              style: TextStyle(
                                fontSize: context.sp(12),
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              _contractService.formatDate(contract['next_payment_date']),
                              style: TextStyle(
                                fontSize: context.sp(14),
                                fontWeight: FontWeight.w600,
                                color: Color(paymentStatusInfo['color']),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        paymentStatusInfo['text'],
                        style: TextStyle(
                          fontSize: context.sp(12),
                          fontWeight: FontWeight.w600,
                          color: Color(paymentStatusInfo['color']),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Color(0xFF4CAF50)),
                      SizedBox(width: context.r(8)),
                      Text(
                        'Paiement unique effectuÃ©',
                        style: TextStyle(
                          fontSize: context.sp(14),
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              SizedBox(height: context.r(12)),
              const Divider(),
              SizedBox(height: context.r(8)),
              
              // Informations supplÃ©mentaires
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(
                    icon: Icons.calendar_today,
                    label: 'DÃ©but',
                    value: _contractService.formatDate(contract['start_date']),
                  ),
                  _buildInfoItem(
                    icon: Icons.access_time,
                    label: 'DurÃ©e',
                    value: '${contract['duration_years'] ?? 0} ans',
                  ),
                  if (contract['payments_remaining'] != null)
                    _buildInfoItem(
                      icon: Icons.repeat,
                      label: 'Paiements restants',
                      value: '${contract['payments_remaining']}',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color;
    String text = _contractService.formatStatus(status);
    
    switch (status?.toLowerCase()) {
      case 'active':
        color = const Color(0xFF4CAF50);
        break;
      case 'suspended':
        color = const Color(0xFFFF9800);
        break;
      case 'expired':
        color = const Color(0xFF9E9E9E);
        break;
      case 'cancelled':
        color = const Color(0xFFF44336);
        break;
      default:
        color = const Color(0xFF9E9E9E);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: context.sp(12),
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            SizedBox(width: context.r(4)),
            Text(
              label,
              style: TextStyle(
                fontSize: context.sp(11),
                color: Colors.grey,
              ),
            ),
          ],
        ),
        SizedBox(height: context.r(2)),
        Text(
          value,
          style: TextStyle(
            fontSize: context.sp(13),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _openContractDetails(int contractId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContractDetailPage(contractId: contractId),
      ),
    );
  }
}

/// Page de dÃ©tails d'un contrat spÃ©cifique
class ContractDetailPage extends StatefulWidget {
  final int contractId;
  
  const ContractDetailPage({super.key, required this.contractId});

  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> {
  final ContractService _contractService = ContractService();
  
  Map<String, dynamic>? _contract;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContractDetails();
  }

  Future<void> _loadContractDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _contractService.getContractDetails(widget.contractId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _contract = result['contract'];
        } else {
          _errorMessage = result['error'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DÃ©tails du Contrat'),
        backgroundColor: const Color(0xFF1976D2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(_errorMessage!),
                  ),
                )
              : _contract == null
                  ? const Center(child: Text('Contrat non trouvÃ©'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(
                            title: 'Informations GÃ©nÃ©rales',
                            children: [
                              _buildDetailRow('NumÃ©ro de contrat', _contract!['contract_number']),
                              _buildDetailRow('Produit', _contract!['product_name']),
                              _buildDetailRow('Statut', _contractService.formatStatus(_contract!['status'])),
                              _buildDetailRow('Mode de paiement', _contract!['payment_method']),
                            ],
                          ),
                          SizedBox(height: context.r(24)),
                          
                          _buildSection(
                            title: 'Paiements',
                            children: [
                              _buildDetailRow('Montant', _contractService.formatAmount(_contract!['amount'])),
                              _buildDetailRow('PÃ©riodicitÃ©', _contractService.formatPeriodicite(_contract!['periodicite'])),
                              if (_contract!['next_payment_date'] != null)
                                _buildDetailRow('Prochain paiement', _contractService.formatDate(_contract!['next_payment_date'])),
                              _buildDetailRow('Total payÃ©', _contractService.formatAmount(_contract!['total_paid'])),
                            ],
                          ),
                          SizedBox(height: context.r(24)),
                          
                          _buildSection(
                            title: 'DurÃ©e du Contrat',
                            children: [
                              _buildDetailRow('Date de dÃ©but', _contractService.formatDate(_contract!['start_date'])),
                              if (_contract!['end_date'] != null)
                                _buildDetailRow('Date de fin', _contractService.formatDate(_contract!['end_date'])),
                              _buildDetailRow('DurÃ©e', '${_contract!['duration_years'] ?? 0} ans'),
                            ],
                          ),
                          
                          // Historique des paiements
                          if (_contract!['payment_history'] != null) ...[
                            SizedBox(height: context.r(24)),
                            _buildPaymentHistory(_contract!['payment_history']),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: context.sp(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.r(16)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: context.sp(14),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: context.sp(14),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(List<dynamic> history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique des Paiements',
            style: TextStyle(
              fontSize: context.sp(18),
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: context.r(16)),
          ...history.map((payment) {
            final statusColor = payment['statut'] == 'SUCCESS'
                ? const Color(0xFF4CAF50)
                : payment['statut'] == 'FAILED'
                    ? const Color(0xFFF44336)
                    : const Color(0xFFFF9800);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  payment['statut'] == 'SUCCESS'
                      ? Icons.check_circle
                      : payment['statut'] == 'FAILED'
                          ? Icons.error
                          : Icons.pending,
                  color: statusColor,
                ),
                title: Text(_contractService.formatAmount(payment['montant'])),
                subtitle: Text(_contractService.formatDate(payment['date'])),
                trailing: Text(
                  payment['statut'],
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

