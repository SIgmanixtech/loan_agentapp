// // import 'package:flutter/material.dart';

// // import '../../core/widgets/appBar.dart';

// // class AgentMyLoans extends StatelessWidget {
// //   final VoidCallback onLogout;

// //   const AgentMyLoans({
// //     super.key,
// //     required this.onLogout,
// //   });

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AgentAppBar(
// //         title: 'My Loans',
// //         onLogout: onLogout,
// //       ),

// //       body: const Center(
// //         child: Text(
// //           'My Loans',
// //           style: TextStyle(
// //             fontSize: 24,
// //             fontWeight: FontWeight.bold,
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }

// import 'package:flutter/material.dart';

// import '../../core/theme/appColors.dart';
// import '../../core/widgets/appBar.dart';
// import '../../services/agentLoanService.dart';

// class AgentMyLoans extends StatefulWidget {
//   final VoidCallback onLogout;

//   const AgentMyLoans({super.key, required this.onLogout});

//   @override
//   State<AgentMyLoans> createState() => _AgentMyLoansState();
// }

// class _AgentMyLoansState extends State<AgentMyLoans> {
//   List<Map<String, dynamic>> loans = [];

//   bool isLoading = true;
//   bool isRefreshing = false;

//   String? errorMessage;

//   @override
//   void initState() {
//     super.initState();
//     _loadMyLoans();
//   }

//   Future<void> _loadMyLoans() async {
//     if (!mounted) {
//       return;
//     }

//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       final result = await AgentLoanService.getMyLoans();

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         loans = result;
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         errorMessage = _cleanError(e);
//       });
//     } finally {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> _refreshLoans() async {
//     if (isRefreshing) {
//       return;
//     }

//     setState(() {
//       isRefreshing = true;
//       errorMessage = null;
//     });

//     try {
//       final result = await AgentLoanService.getMyLoans();

//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         loans = result;
//       });
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         errorMessage = _cleanError(e);
//       });
//     } finally {
//       if (!mounted) {
//         return;
//       }

//       setState(() {
//         isRefreshing = false;
//       });
//     }
//   }

//   String _cleanError(Object error) {
//     return error.toString().replaceFirst('Exception: ', '').trim();
//   }

//   dynamic _getLoanId(Map<String, dynamic> loan) {
//     return loan['id'] ?? loan['loanId'] ?? loan['loan_id'];
//   }

//   String _getStatus(Map<String, dynamic> loan) {
//     return loan['status']?.toString() ?? 'UNKNOWN';
//   }

//   String _formatStatus(String status) {
//     return status
//         .replaceAll('_', ' ')
//         .split(' ')
//         .map(
//           (word) => word.isEmpty
//               ? word
//               : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
//         )
//         .join(' ');
//   }

//   Future<void> _showLoanDetails(Map<String, dynamic> loan) async {
//     await showDialog<void>(
//       context: context,
//       builder: (dialogContext) {
//         return _MyLoanDetailsDialog(
//           loan: loan,
//           onApprove: () async {
//             Navigator.of(dialogContext).pop();

//             await _updateStatus(loan: loan, status: 'APPROVED');
//           },
//           onReject: () async {
//             Navigator.of(dialogContext).pop();

//             await _updateStatus(loan: loan, status: 'REJECTED');
//           },
//         );
//       },
//     );
//   }

//   Future<void> _updateStatus({
//     required Map<String, dynamic> loan,
//     required String status,
//   }) async {
//     final loanId = _getLoanId(loan);

//     if (loanId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Loan ID was not found in the response.')),
//       );

//       return;
//     }

//     try {
//       await AgentLoanService.updateLoanStatus(loanId: loanId, status: status);

//       if (!mounted) {
//         return;
//       }

//       await _loadMyLoans();

//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             status == 'APPROVED'
//                 ? 'Loan approved successfully.'
//                 : 'Loan rejected successfully.',
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) {
//         return;
//       }

//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text(_cleanError(e))));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AgentAppBar(title: 'My Loans', onLogout: widget.onLogout),
//       body: _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     if (isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (errorMessage != null && loans.isEmpty) {
//       return _buildErrorState();
//     }

//     if (loans.isEmpty) {
//       return RefreshIndicator(
//         onRefresh: _refreshLoans,
//         child: ListView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           children: [
//             SizedBox(height: MediaQuery.of(context).size.height * 0.25),
//             _buildEmptyState(),
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: _refreshLoans,
//       child: ListView(
//         physics: const AlwaysScrollableScrollPhysics(),
//         padding: const EdgeInsets.all(16),
//         children: [
//           _buildHeader(),

//           const SizedBox(height: 16),

//           if (errorMessage != null) _buildErrorBanner(),

//           ...loans.map(
//             (loan) => Padding(
//               padding: const EdgeInsets.only(bottom: 12),
//               child: _buildLoanCard(loan),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'My Loans',
//           style: TextStyle(
//             fontSize: 22,
//             fontWeight: FontWeight.w700,
//             color: AppColors.textPrimary,
//           ),
//         ),
//         const SizedBox(height: 6),
//         Text(
//           '${loans.length} assigned loan${loans.length == 1 ? '' : 's'}',
//           style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
//         ),
//       ],
//     );
//   }

//   Widget _buildLoanCard(Map<String, dynamic> loan) {
//     final status = _getStatus(loan);
//     final loanId = _getLoanId(loan);

//     final canUpdate = status == 'UNDER_REVIEW';

//     return InkWell(
//       onTap: () => _showLoanDetails(loan),
//       borderRadius: BorderRadius.circular(14),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           color: AppColors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: AppColors.border),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Container(
//                   height: 46,
//                   width: 46,
//                   decoration: BoxDecoration(
//                     color: _statusColor(status).withOpacity(0.10),
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(_statusIcon(status), color: _statusColor(status)),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         loanId != null ? 'Loan #$loanId' : 'Loan',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: AppColors.textPrimary,
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       _buildStatusChip(status),
//                     ],
//                   ),
//                 ),
//                 const Icon(Icons.chevron_right, color: AppColors.textSecondary),
//               ],
//             ),

//             if (canUpdate) ...[
//               const SizedBox(height: 16),

//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () {
//                         _updateStatus(loan: loan, status: 'REJECTED');
//                       },
//                       style: OutlinedButton.styleFrom(
//                         foregroundColor: AppColors.error,
//                         side: const BorderSide(color: AppColors.error),
//                       ),
//                       child: const Text('Reject'),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         _updateStatus(loan: loan, status: 'APPROVED');
//                       },
//                       child: const Text('Approve'),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusChip(String status) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//       decoration: BoxDecoration(
//         color: _statusColor(status).withOpacity(0.10),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text(
//         _formatStatus(status),
//         style: TextStyle(
//           color: _statusColor(status),
//           fontSize: 12,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'SUBMITTED':
//         return AppColors.primary;

//       case 'UNDER_REVIEW':
//         return AppColors.warning;

//       case 'APPROVED':
//         return AppColors.success;

//       case 'REJECTED':
//         return AppColors.error;

//       default:
//         return AppColors.textSecondary;
//     }
//   }

//   IconData _statusIcon(String status) {
//     switch (status) {
//       case 'SUBMITTED':
//         return Icons.send_outlined;

//       case 'UNDER_REVIEW':
//         return Icons.pending_actions;

//       case 'APPROVED':
//         return Icons.check_circle_outline;

//       case 'REJECTED':
//         return Icons.cancel_outlined;

//       default:
//         return Icons.receipt_long_outlined;
//     }
//   }

//   Widget _buildEmptyState() {
//     return Padding(
//       padding: const EdgeInsets.all(24),
//       child: Column(
//         children: [
//           Container(
//             height: 76,
//             width: 76,
//             decoration: BoxDecoration(
//               color: AppColors.primary.withOpacity(0.10),
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.receipt_long_outlined,
//               size: 38,
//               color: AppColors.primary,
//             ),
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             'No loans assigned',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w700,
//               color: AppColors.textPrimary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'You do not have any accepted loans yet.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
//           ),
//           const SizedBox(height: 20),
//           OutlinedButton.icon(
//             onPressed: _refreshLoans,
//             icon: const Icon(Icons.refresh),
//             label: const Text('Refresh'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.error_outline, size: 52, color: AppColors.error),
//             const SizedBox(height: 16),
//             Text(
//               errorMessage ?? 'Unable to load your loans.',
//               textAlign: TextAlign.center,
//               style: const TextStyle(
//                 fontSize: 15,
//                 color: AppColors.textPrimary,
//               ),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton(onPressed: _loadMyLoans, child: const Text('Retry')),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorBanner() {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 16),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: AppColors.error.withOpacity(0.08),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.error_outline, color: AppColors.error),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               errorMessage!,
//               style: const TextStyle(color: AppColors.error, fontSize: 13),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MyLoanDetailsDialog extends StatelessWidget {
//   final Map<String, dynamic> loan;
//   final VoidCallback onApprove;
//   final VoidCallback onReject;

//   const _MyLoanDetailsDialog({
//     required this.loan,
//     required this.onApprove,
//     required this.onReject,
//   });

//   dynamic _getLoanId() {
//     return loan['id'] ?? loan['loanId'] ?? loan['loan_id'];
//   }

//   String _getStatus() {
//     return loan['status']?.toString() ?? 'UNKNOWN';
//   }

//   String _formatKey(String key) {
//     final result = key.replaceAllMapped(
//       RegExp(r'([a-z])([A-Z])'),
//       (match) => '${match.group(1)} ${match.group(2)}',
//     );

//     return result
//         .replaceAll('_', ' ')
//         .split(' ')
//         .map(
//           (word) => word.isEmpty
//               ? word
//               : '${word[0].toUpperCase()}${word.substring(1)}',
//         )
//         .join(' ');
//   }

//   String _formatValue(dynamic value) {
//     if (value == null) {
//       return '-';
//     }

//     return value.toString();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final loanId = _getLoanId();
//     final status = _getStatus();

//     final canUpdate = status == 'UNDER_REVIEW';

//     return AlertDialog(
//       title: Text(loanId != null ? 'Loan #$loanId' : 'Loan Details'),
//       content: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _detailRow('Status', status.replaceAll('_', ' ')),
//             const SizedBox(height: 16),

//             ...loan.entries
//                 .where(
//                   (entry) =>
//                       entry.key != 'id' &&
//                       entry.key != 'loanId' &&
//                       entry.key != 'loan_id' &&
//                       entry.key != 'status',
//                 )
//                 .map(
//                   (entry) => Padding(
//                     padding: const EdgeInsets.only(bottom: 10),
//                     child: _detailRow(
//                       _formatKey(entry.key),
//                       _formatValue(entry.value),
//                     ),
//                   ),
//                 ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () {
//             Navigator.of(context).pop();
//           },
//           child: const Text('Close'),
//         ),
//         if (canUpdate)
//           TextButton(
//             onPressed: onReject,
//             style: TextButton.styleFrom(foregroundColor: AppColors.error),
//             child: const Text('Reject'),
//           ),
//         if (canUpdate)
//           ElevatedButton(onPressed: onApprove, child: const Text('Approve')),
//       ],
//     );
//   }

//   Widget _detailRow(String label, String value) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label,
//           style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
//         ),
//         const SizedBox(height: 3),
//         Text(
//           value,
//           style: const TextStyle(
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//             color: AppColors.textPrimary,
//           ),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../core/widgets/appBar.dart';
import '../../services/agentLoanService.dart';

class AgentMyLoans extends StatefulWidget {
  final VoidCallback onLogout;

  const AgentMyLoans({super.key, required this.onLogout});

  @override
  State<AgentMyLoans> createState() => _AgentMyLoansState();
}

class _AgentMyLoansState extends State<AgentMyLoans> {
  List<Map<String, dynamic>> loans = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyLoans();
  }

  Future<void> _loadMyLoans() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await AgentLoanService.getMyLoans();

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

  String _getStatus(Map<String, dynamic> loan) {
    return loan['status']?.toString().toUpperCase() ?? 'UNKNOWN';
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

  Future<void> _updateStatus({
    required Map<String, dynamic> loan,
    required String status,
  }) async {
    final loanId = _getLoanId(loan);

    if (loanId == null) {
      return;
    }

    try {
      await AgentLoanService.updateLoanStatus(loanId: loanId, status: status);

      if (!mounted) {
        return;
      }

      // Refresh the list from the backend so the UI
      // always reflects the actual server state.
      await _loadMyLoans();

      if (!mounted) {
        return;
      }

      if (status == 'APPROVED') {
        await _showSuccessDialog(message: 'Loan approved successfully.');
      } else if (status == 'REJECTED') {
        await _showSuccessDialog(message: 'Loan rejected successfully.');
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      await _showErrorDialog(
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showLoanDetails(Map<String, dynamic> loan) {
    final loanId = _getLoanId(loan);
    final status = _getStatus(loan);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loanId != null ? 'Loan #$loanId' : 'Loan Details'),
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
            if (status == 'UNDER_REVIEW') ...[
              TextButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  await _updateStatus(loan: loan, status: 'REJECTED');
                },
                child: const Text(
                  'Reject',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  await _updateStatus(loan: loan, status: 'APPROVED');
                },
                child: const Text('Approve'),
              ),
            ],
          ],
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'SUBMITTED':
        return Colors.blue;
      case 'UNDER_REVIEW':
        return Colors.orange;
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'SUBMITTED':
        return Icons.schedule;
      case 'UNDER_REVIEW':
        return Icons.hourglass_top;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
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
    final status = _getStatus(loan);
    final statusColor = _statusColor(status);

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
                  Icon(_statusIcon(status), color: statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...loan.entries
                  .where(
                    (entry) =>
                        entry.key != 'id' &&
                        entry.key != 'loanId' &&
                        entry.key != 'loan_id' &&
                        entry.key != 'status',
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
              if (status == 'UNDER_REVIEW') ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _updateStatus(loan: loan, status: 'REJECTED');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _updateStatus(loan: loan, status: 'APPROVED');
                        },
                        child: const Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AgentAppBar(title: 'My Loans', onLogout: widget.onLogout),
      body: RefreshIndicator(onRefresh: _loadMyLoans, child: _buildBody()),
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
                    onPressed: _loadMyLoans,
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
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 56,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No loans assigned',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Loans you accept from My Area will appear here.',
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
