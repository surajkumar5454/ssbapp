import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/main_layout.dart';
import '../../services/posting_service.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class ServiceDetailsScreen extends StatefulWidget {
  const ServiceDetailsScreen({super.key});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPostings();
    });
  }

  Future<void> _loadPostings() async {
    final postingService = context.read<PostingService>();
    final authService = context.read<AuthService>();
    await postingService.loadPostings(authService.uin!);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Service Details'),
        ),
        body: Consumer<PostingService>(
          builder: (context, postingService, _) {
            if (postingService.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (postingService.error != null) {
              return Center(child: Text(postingService.error!));
            }

            final postings = postingService.postings;
            if (postings.isEmpty) {
              return const Center(child: Text('No posting history found'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: postings.length,
              itemBuilder: (context, index) {
                final posting = postings[index];
                return Card(
                  child: ListTile(
                    title: Text('Unit: ${posting.unitName ?? 'N/A'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rank: ${posting.rankName ?? 'N/A'}'),
                        Text('Branch: ${posting.branchName ?? 'N/A'}'),
                        if (posting.dateofjoin != null)
                          Text('Date of Joining: ${DateFormat('dd-MM-yyyy').format(posting.dateofjoin!)}'),
                        if (posting.dateofrelv != null)
                          Text('Date of Relieving: ${DateFormat('dd-MM-yyyy').format(posting.dateofrelv!)}'),
                        if (posting.joiningremark != null)
                          Text('Remarks: ${posting.joiningremark}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
} 