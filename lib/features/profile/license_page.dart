import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../design/vimi_ui.dart';

class VimiLicensesPage extends StatefulWidget {
  const VimiLicensesPage({super.key});
  @override
  State<VimiLicensesPage> createState() => _VimiLicensesPageState();
}

class _VimiLicensesPageState extends State<VimiLicensesPage> {
  late final future = LicenseRegistry.licenses.toList();
  @override
  Widget build(BuildContext context) => VPage(
    title: 'Open-source licenses',
    child: FutureBuilder<List<LicenseEntry>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: Text('Opening licenses…'));
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final entry = snapshot.data![index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.packages.join(', '),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    entry.paragraphs.map((p) => p.text).join('\n\n'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}
