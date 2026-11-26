import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/features/community/community_api.dart';
import 'package:nuvtune/features/community/community_controller.dart';

/// Comunidad: cuenta propia y amistades. Es la base para compartir lo que
/// escuchas con tus amigos.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(communitySessionProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comunidad'),
        actions: [
          if (session.valueOrNull != null)
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => _run(
                context,
                ref.read(communitySessionProvider.notifier).logout,
              ),
            ),
        ],
      ),
      body: session.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorRetry(
          message: '$error',
          onRetry: () => ref.invalidate(communitySessionProvider),
        ),
        data: (value) =>
            value == null ? const _AuthForm() : _FriendsView(session: value),
      ),
    );
  }
}

/// Ejecuta una accion y muestra el error del servidor si falla.
Future<void> _run(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } on CommunityException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Tokens.space5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: Tokens.space3),
          FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

class _AuthForm extends ConsumerStatefulWidget {
  const _AuthForm();

  @override
  ConsumerState<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends ConsumerState<_AuthForm> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _registering = false;
  bool _busy = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final controller = ref.read(communitySessionProvider.notifier);
    await _run(
      context,
      () => _registering
          ? controller.register(_username.text, _password.text)
          : controller.login(_username.text, _password.text),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(Tokens.gutter),
    children: [
      Text(
        _registering ? 'Crea tu usuario' : 'Inicia sesión',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: Tokens.space2),
      Text(
        'Tu usuario te identifica ante tus amigos. Tu música no se sube a '
        'ningún servidor.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: Tokens.space4),
      TextField(
        controller: _username,
        autocorrect: false,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          labelText: 'Usuario',
          helperText: '3 a 20 letras, números o guion bajo',
        ),
      ),
      const SizedBox(height: Tokens.space3),
      TextField(
        controller: _password,
        obscureText: true,
        onSubmitted: (_) => _busy ? null : _submit(),
        decoration: const InputDecoration(
          labelText: 'Contraseña',
          helperText: 'Mínimo 8 caracteres',
        ),
      ),
      const SizedBox(height: Tokens.space4),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(_registering ? 'Crear cuenta' : 'Entrar'),
      ),
      TextButton(
        onPressed: _busy
            ? null
            : () => setState(() => _registering = !_registering),
        child: Text(
          _registering ? 'Ya tengo cuenta' : '¿No tienes cuenta? Crea una',
        ),
      ),
    ],
  );
}

class _FriendsView extends ConsumerStatefulWidget {
  const _FriendsView({required this.session});

  final CommunitySession session;

  @override
  ConsumerState<_FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends ConsumerState<_FriendsView> {
  final _newFriend = TextEditingController();

  @override
  void dispose() {
    _newFriend.dispose();
    super.dispose();
  }

  CommunityApi get _api => ref.read(communityApiProvider);
  String get _token => widget.session.token;

  Future<void> _mutate(Future<void> Function() action) async {
    await _run(context, action);
    ref.invalidate(friendsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider);
    return friends.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorRetry(
        message: '$error',
        onRetry: () => ref.invalidate(friendsProvider),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () async => ref.refresh(friendsProvider.future),
        child: ListView(
          padding: const EdgeInsets.only(bottom: Tokens.space6),
          children: [
            ListTile(
              leading: const Icon(Icons.account_circle_rounded),
              title: Text('@${widget.session.username}'),
              subtitle: const Text('Tu usuario'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newFriend,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Agregar amigo por usuario',
                      ),
                    ),
                  ),
                  const SizedBox(width: Tokens.space2),
                  IconButton.filled(
                    tooltip: 'Enviar solicitud',
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    onPressed: () {
                      final name = _newFriend.text.trim();
                      if (name.isEmpty) return;
                      _newFriend.clear();
                      _mutate(() => _api.requestFriend(_token, name));
                    },
                  ),
                ],
              ),
            ),
            if (data.incoming.isNotEmpty) ...[
              const _Label('Solicitudes recibidas'),
              for (final name in data.incoming)
                ListTile(
                  title: Text('@$name'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Rechazar',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () =>
                            _mutate(() => _api.removeFriend(_token, name)),
                      ),
                      IconButton(
                        tooltip: 'Aceptar',
                        icon: const Icon(Icons.check_rounded),
                        onPressed: () =>
                            _mutate(() => _api.acceptFriend(_token, name)),
                      ),
                    ],
                  ),
                ),
            ],
            const _Label('Amigos'),
            if (data.friends.isEmpty)
              const ListTile(
                subtitle: Text('Aún no tienes amigos. Envía una solicitud.'),
              ),
            for (final name in data.friends)
              ListTile(
                leading: const Icon(Icons.person_rounded),
                title: Text('@$name'),
                trailing: IconButton(
                  tooltip: 'Quitar amigo',
                  icon: const Icon(Icons.person_remove_rounded),
                  onPressed: () =>
                      _mutate(() => _api.removeFriend(_token, name)),
                ),
              ),
            if (data.outgoing.isNotEmpty) ...[
              const _Label('Solicitudes enviadas'),
              for (final name in data.outgoing)
                ListTile(
                  title: Text('@$name'),
                  subtitle: const Text('Esperando respuesta'),
                  trailing: IconButton(
                    tooltip: 'Cancelar',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () =>
                        _mutate(() => _api.removeFriend(_token, name)),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Tokens.gutter,
      Tokens.space4,
      Tokens.gutter,
      Tokens.space1,
    ),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}
