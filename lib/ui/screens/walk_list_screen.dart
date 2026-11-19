import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

import '../../app_services.dart';
import '../../core/routes.dart';
import '../../domain/models/walk_entry.dart';
import '../widgets/app_drawer.dart';
import '../widgets/walk_image.dart';

/// Vista de lista: carga los paseos con [FutureBuilder].
class WalkListScreen extends StatefulWidget {
  const WalkListScreen({super.key});

  @override
  State<WalkListScreen> createState() => _WalkListScreenState();
}

class _WalkListScreenState extends State<WalkListScreen> {
  Future<List<WalkEntry>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppServices.of(context).walks.getAll();
  }

  void _reload() {
    final future = AppServices.of(context).walks.getAll();
    setState(() {
      _future = future;
    });
  }

  Future<void> _openForm() async {
    final saved = await Navigator.pushNamed(context, AppRoutes.form);
    if (saved == true) _reload();
  }

  Future<void> _openDetail(WalkEntry entry) async {
    final changed =
        await Navigator.pushNamed(context, AppRoutes.detail, arguments: entry);
    if (changed == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis paseos')),
      drawer: const AppDrawer(currentRoute: AppRoutes.list),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo paseo'),
      ),
      body: FutureBuilder<List<WalkEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: _reload, child: const Text('Reintentar')),
                  ],
                ),
              ),
            );
          }
          final walks = snapshot.data ?? [];
          if (walks.isEmpty) {
            return const Center(
                child: Text('Aún no hay paseos. ¡Registra el primero!'));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: walks.length,
            itemBuilder: (_, i) =>
                _WalkTile(entry: walks[i], onTap: () => _openDetail(walks[i])),
          );
        },
      ),
    );
  }
}

class _WalkTile extends StatelessWidget {
  final WalkEntry entry;
  final VoidCallback onTap;

  const _WalkTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM y, HH:mm', 'es').format(entry.createdAt);
    final text = Theme.of(context).textTheme;
    // Solo imagen y texto: sin tarjeta, sin bordes ni esquinas redondeadas.
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WalkImage(entry: entry, width: double.infinity, height: 220),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.dogName, style: text.titleLarge),
                  Text('$date · ${entry.durationMinutes} min',
                      style: text.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
