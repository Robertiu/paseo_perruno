import 'package:material_ui/material_ui.dart';

import '../../app_services.dart';
import '../../core/routes.dart';
import '../theme/app_theme.dart';
import 'avatar.dart';

enum AppTab { walks, form, ranking }

/// Armazón común: header (título, nivel, racha, avatar) + barra inferior.
/// Sin [tab] no muestra la barra inferior (pantallas secundarias).
class AppShell extends StatelessWidget {
  final String title;
  final AppTab? tab;
  final bool back;
  final Widget body;

  const AppShell({super.key, required this.title, required this.body, this.tab, this.back = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Tk.bg,
      appBar: _Header(title: title, back: back),
      body: body,
      bottomNavigationBar: tab == null ? null : _BottomNav(current: tab!),
    );
  }
}

class _Header extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool back;
  const _Header({required this.title, required this.back});

  @override
  Size get preferredSize => const Size.fromHeight(65);

  @override
  State<_Header> createState() => _HeaderState();
}

class _HeaderState extends State<_Header> {
  bool _requested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final services = AppServices.of(context);
    if (!_requested && services.profile.value == null) {
      _requested = true;
      services.refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = AppServices.of(context);
    return Material(
      color: Tk.bg,
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Tk.line))),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tk.pad),
              child: Row(children: [
                if (widget.back)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkResponse(
                      onTap: () => Navigator.maybePop(context),
                      child: const Icon(Icons.arrow_back, color: Tk.rust),
                    ),
                  ),
                Expanded(
                  child: Text(widget.title,
                      overflow: TextOverflow.ellipsis,
                      style: Tk.display(18, color: widget.back ? Tk.rust : Tk.ink)),
                ),
                ValueListenableBuilder(
                  valueListenable: services.profile,
                  builder: (_, profile, __) {
                    if (profile == null) return const SizedBox.shrink();
                    return Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: Tk.card, borderRadius: BorderRadius.circular(8)),
                        child: Text('Nvl ${profile.level}', style: Tk.body(10, w: FontWeight.w600)),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.local_fire_department, size: 16, color: Tk.flame),
                      Text(' ${profile.streak} d', style: Tk.body(11, w: FontWeight.w600, color: Tk.flame)),
                      const SizedBox(width: 10),
                      InkResponse(
                        onTap: () {
                          if (ModalRoute.of(context)?.settings.name != AppRoutes.profile) {
                            Navigator.pushNamed(context, AppRoutes.profile);
                          }
                        },
                        child: Avatar(name: profile.name, size: 34),
                      ),
                    ]);
                  },
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final AppTab current;
  const _BottomNav({required this.current});

  static const _items = [
    (AppTab.walks, Icons.route, 'Paseos', AppRoutes.list),
    (AppTab.form, Icons.edit_note, 'Nuevo paseo', AppRoutes.form),
    (AppTab.ranking, Icons.emoji_events_outlined, 'Ranking', AppRoutes.ranking),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Tk.bg, border: Border(top: BorderSide(color: Tk.line))),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(children: [
            for (final (tab, icon, label, route) in _items)
              Expanded(
                child: InkWell(
                  onTap: () {
                    if (tab != current) Navigator.pushReplacementNamed(context, route);
                  },
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(icon, size: 24, color: tab == current ? Tk.rust : Tk.inkSoft),
                    const SizedBox(height: 3),
                    Text(label,
                        style: Tk.body(10, w: FontWeight.w600, color: tab == current ? Tk.rust : Tk.inkSoft)),
                  ]),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
