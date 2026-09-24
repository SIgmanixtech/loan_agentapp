import 'package:flutter/material.dart';

import '../../core/widgets/appBar.dart';
import '../../services/agentLoanService.dart';

class AgentMyArea extends StatefulWidget {
  final VoidCallback onLogout;

  const AgentMyArea({super.key, required this.onLogout});

  @override
  State<AgentMyArea> createState() => _AgentMyAreaState();
}

class _AgentMyAreaState extends State<AgentMyArea> {
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNearbyLoans();
  }

  Future<void> _loadNearbyLoans() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await AgentLoanService.getNearbyLoans();

      if (!mounted) {
        return;
      }

      setState(() {
        loans = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  dynamic _getLoanId(Map<String, dynamic> loan) {
    return loan['id'] ?? loan['loanId'] ?? loan['loan_id'];
  }

  Future<void> _showSuccessDialog({required String message}) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Success'),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptLoan(Map<String, dynamic> loan) async {
    final loanId = _getLoanId(loan);

    if (loanId == null) {
      return;
    }

    try {
      await AgentLoanService.acceptLoan(loanId);

      if (!mounted) {
        return;
      }

      setState(() {
        loans.remove(loan);
      });

      await _showSuccessDialog(message: 'Loan accepted successfully.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      await _showErrorDialog(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _showErrorDialog({required String message}) async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Text('Error'),
            ],
          ),
          content: Text(message, style: const TextStyle(fontSize: 16)),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showLoanDetails(Map<String, dynamic> loan) {
    final loanId = _getLoanId(loan);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Loan Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...loan.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatLabel(entry.key),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(entry.value?.toString() ?? '-'),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
            if (loanId != null)
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  await _acceptLoan(loan);
                },
                child: const Text('Accept Loan'),
              ),
          ],
        );
      },
    );
  }

  String _formatLabel(String value) {
    final formatted = value.replaceAll('_', ' ').replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) {
        return '${match.group(1)} ${match.group(2)}';
      },
    );

    if (formatted.isEmpty) {
      return value;
    }

    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final loanId = _getLoanId(loan);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _showLoanDetails(loan);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: Colors.blue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      loanId != null ? 'Loan #$loanId' : 'Loan',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 12),
              ...loan.entries
                  .where(
                    (entry) =>
                        entry.key != 'id' &&
                        entry.key != 'loanId' &&
                        entry.key != 'loan_id',
                  )
                  .take(4)
                  .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              _formatLabel(entry.key),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              entry.value?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _acceptLoan(loan);
                  },
                  child: const Text('Accept Loan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AgentAppBar(title: 'My Area', onLogout: widget.onLogout),
      body: RefreshIndicator(onRefresh: _loadNearbyLoans, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNearbyLoans,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (loans.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.location_searching, size: 56, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No nearby loans',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'New loan applications in your area will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        return _buildLoanCard(loans[index]);
      },
    );
  }
}
