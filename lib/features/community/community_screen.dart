import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nuvtune/app/theme/design_tokens.dart';
import 'package:nuvtune/features/community/community_controller.dart';
import 'package:nuvtune/features/community/community_exception.dart';
import 'package:nuvtune/features/community/community_service.dart';
import 'package:nuvtune/features/community/nostr/nostr_keys.dart';
import 'package:nuvtune/shared/widgets/confirm_dialog.dart';
import 'package:share_plus/share_plus.dart';

/// Comunidad: tu usuario y tus amigos. No hay cuentas ni servidor propio: tu
/// usuario es una clave guardada en este telefono y los mensajes viajan firmados
/// por relays publicos de Nostr.
class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final identity = ref.watch(identityProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Comunidad')),
      body: identity.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorRetry(
          message: '$error',
          onRetry: () => ref.invalidate(identityProvider),
        ),
        data: (keys) =>
            keys == null ? const _CreateIdentity() : _Home(keys: keys),
      ),
    );
  }
}

/// Ejecuta [action] y muestra el mensaje si falla con un error de comunidad.
Future<bool> _run(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } on CommunityException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    return false;
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

class _CreateIdentity extends ConsumerStatefulWidget {
  const _CreateIdentity();

  @override
  ConsumerState<_CreateIdentity> createState() => _CreateIdentityState();
}

class _CreateIdentityState extends ConsumerState<_CreateIdentity> {
  final _name = TextEditingController();
  final _secret = TextEditingController();
  bool _restoring = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final controller = ref.read(identityProvider.notifier);
    await _run(
      context,
      () => _restoring
          ? controller.restore(_secret.text)
          : controller.create(_name.text),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(Tokens.gutter),
    children: [
      Text(
        _restoring ? 'Recupera tu usuario' : 'Crea tu usuario',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: Tokens.space2),
      Text(
        _restoring
            ? 'Pega la clave secreta (nsec…) que guardaste.'
            : 'Solo eliges un nombre. No hay contraseña ni correo: tu usuario '
                  'es una clave que se guarda en este teléfono, y tu música '
                  'no se sube a ningún servidor.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: Tokens.space4),
      if (_restoring)
        TextField(
          controller: _secret,
          autocorrect: false,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Clave secreta'),
        )
      else
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Tu nombre',
            helperText: 'De 2 a 30 caracteres. Lo verán tus amigos.',
          ),
        ),
      const SizedBox(height: Tokens.space4),
      FilledButton(
        onPressed: _busy ? null : _submit,
        child: Text(_restoring ? 'Recuperar' : 'Crear usuario'),
      ),
      TextButton(
        onPressed: _busy
            ? null
            : () => setState(() => _restoring = !_restoring),
        child: Text(
          _restoring ? 'Crear uno nuevo' : 'Ya tengo una clave secreta',
        ),
      ),
    ],
  );
}

class _Home extends ConsumerStatefulWidget {
  const _Home({required this.keys});

  final NostrKeys keys;

  @override
  ConsumerState<_Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<_Home> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  CommunityService get _service => ref.read(communityServiceProvider)!;

  Future<void> _mutate(Future<void> Function() action) async {
    await _run(context, action);
    ref.invalidate(friendsProvider);
  }

  Future<void> _add() async {
    final text = _code.text.trim();
    if (text.isEmpty) return;
    if (await _run(context, () => _service.addFriend(text))) _code.clear();
    ref.invalidate(friendsProvider);
  }

  Future<void> _copySecret() async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Copiar clave secreta',
      message:
          'Quien tenga esta clave puede hacerse pasar por ti. Guárdala en un '
          'lugar privado; es la única forma de recuperar tu usuario.',
      confirmLabel: 'Copiar',
    );
    if (!confirmed) return;
    await Clipboard.setData(ClipboardData(text: widget.keys.nsec));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clave secreta copiada')));
    }
  }

  Future<void> _signOut() async {
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Salir de Comunidad',
      message:
          'Se borrará tu clave de este teléfono. Si no copiaste tu clave '
          'secreta, no podrás recuperar este usuario ni tus amistades.',
      confirmLabel: 'Salir',
    );
    if (confirmed) await ref.read(identityProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider);
    final name = ref.watch(myNameProvider).valueOrNull;
    final npub = widget.keys.npub;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myNameProvider);
        ref.invalidate(friendsProvider);
        await ref.read(friendsProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: Tokens.space6),
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_rounded),
            title: Text(name ?? 'Tu usuario'),
            subtitle: Text(
              '${npub.substring(0, 16)}…',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
            child: Wrap(
              spacing: Tokens.space2,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copiar mi código'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: npub));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Código copiado')),
                      );
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Compartir'),
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: 'Agrégame en NuvTune con este código:\n$npub',
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Tokens.gutter,
              Tokens.space4,
              Tokens.gutter,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _code,
                    autocorrect: false,
                    onSubmitted: (_) => _add(),
                    decoration: const InputDecoration(
                      labelText: 'Código de tu amigo (npub…)',
                    ),
                  ),
                ),
                const SizedBox(width: Tokens.space2),
                IconButton.filled(
                  tooltip: 'Agregar amigo',
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  onPressed: _add,
                ),
              ],
            ),
          ),
          friends.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(Tokens.space5),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _ErrorRetry(
              message: '$error',
              onRetry: () => ref.invalidate(friendsProvider),
            ),
            data: (data) => _FriendLists(data: data, onMutate: _mutate),
          ),
          const Divider(height: Tokens.space6),
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: const Text('Copiar mi clave secreta'),
            subtitle: const Text('Para recuperar tu usuario en otro teléfono'),
            onTap: _copySecret,
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Salir de Comunidad'),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}

class _FriendLists extends ConsumerWidget {
  const _FriendLists({required this.data, required this.onMutate});

  final Friends data;
  final Future<void> Function(Future<void> Function()) onMutate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(communityServiceProvider)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.incoming.isNotEmpty) ...[
          const _Label('Solicitudes recibidas'),
          for (final person in data.incoming)
            ListTile(
              title: Text(person.label),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Rechazar',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () =>
                        onMutate(() => service.removeFriend(person.pubkey)),
                  ),
                  IconButton(
                    tooltip: 'Aceptar',
                    icon: const Icon(Icons.check_rounded),
                    onPressed: () =>
                        onMutate(() => service.addFriend(person.npub)),
                  ),
                ],
              ),
            ),
        ],
        const _Label('Amigos'),
        if (data.friends.isEmpty)
          const ListTile(
            subtitle: Text('Aún no tienes amigos. Pega el código de alguien.'),
          ),
        for (final person in data.friends)
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: Text(person.label),
            trailing: IconButton(
              tooltip: 'Quitar amigo',
              icon: const Icon(Icons.person_remove_rounded),
              onPressed: () =>
                  onMutate(() => service.removeFriend(person.pubkey)),
            ),
          ),
        if (data.outgoing.isNotEmpty) ...[
          const _Label('Solicitudes enviadas'),
          for (final person in data.outgoing)
            ListTile(
              title: Text(person.label),
              subtitle: const Text('Esperando que te agregue'),
              trailing: IconButton(
                tooltip: 'Cancelar',
                icon: const Icon(Icons.close_rounded),
                onPressed: () =>
                    onMutate(() => service.removeFriend(person.pubkey)),
              ),
            ),
        ],
      ],
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
