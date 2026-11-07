import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

void main() => runApp(const OpenBeat());

class OpenBeat extends StatelessWidget {
  const OpenBeat({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'OpenBeat',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.tealAccent,
        brightness: Brightness.dark,
      ),
    ),
    home: const Library(),
  );
}

typedef Track = ({String name, Uri uri});

class Library extends StatefulWidget {
  const Library({super.key});

  @override
  State<Library> createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  final _player = AudioPlayer();
  final _tracks = <Track>[
    (
      name: 'Demonstração online · MDN',
      uri: Uri.parse(
        'https://interactive-examples.mdn.mozilla.net/media/cc0-audio/t-rex-roar.mp3',
      ),
    ),
  ];
  late final StreamSubscription<PlayerException> _errors;
  Track? _selected;
  String _search = '';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _errors = _player.errorStream.listen((_) {
      if (!_loading) _showError('Falha durante a reprodução.');
    });
  }

  @override
  void dispose() {
    unawaited(_errors.cancel());
    unawaited(_player.dispose());
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _import() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (!mounted || result == null) return;
      setState(() {
        for (final file in result.files) {
          final path = file.path;
          if (path == null) continue;
          final uri = Uri.file(path);
          if (_tracks.any((track) => track.uri == uri)) continue;
          _tracks.add((name: file.name, uri: uri));
        }
      });
    } catch (_) {
      _showError('Não foi possível importar os ficheiros.');
    }
  }

  Future<void> _select(Track track) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _selected = null;
    });
    try {
      await _player.pause();
      await _player.setAudioSource(AudioSource.uri(track.uri));
      if (!mounted) return;
      setState(() => _selected = track);
      unawaited(_play());
    } catch (_) {
      _showError('Não foi possível abrir o áudio.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _play() async {
    try {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      if (mounted) await _player.play();
    } on PlayerInterruptedException {
      // A seleção de outra faixa pode interromper a reprodução.
    } catch (_) {
      _showError('Não foi possível reproduzir o áudio.');
    }
  }

  Future<void> _control(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      _showError('Não foi possível controlar a reprodução.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _tracks
        .where((track) => track.name.toLowerCase().contains(_search))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('OpenBeat')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Pesquisar na biblioteca',
                ),
                onChanged: (value) =>
                    setState(() => _search = value.trim().toLowerCase()),
              ),
            ),
            FilledButton.icon(
              onPressed: _import,
              icon: const Icon(Icons.library_music),
              label: const Text('Importar áudio'),
            ),
            if (_loading) const LinearProgressIndicator(),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('Nenhuma faixa encontrada'))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final track = visible[index];
                        return ListTile(
                          leading: Icon(
                            track.uri.isScheme('file')
                                ? Icons.music_note
                                : Icons.cloud_outlined,
                          ),
                          title: Text(track.name),
                          selected: track == _selected,
                          enabled: !_loading,
                          onTap: () => _select(track),
                        );
                      },
                    ),
            ),
            if (_selected != null) _controls(),
          ],
        ),
      ),
    );
  }

  Widget _controls() => Column(
    children: [
      Text(_selected!.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      StreamBuilder<Duration?>(
        stream: _player.durationStream,
        builder: (context, duration) {
          final total = duration.data?.inMilliseconds ?? 0;
          return StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, position) {
              final elapsed = position.data?.inMilliseconds ?? 0;
              return Slider(
                max: total > 0 ? total.toDouble() : 1,
                value: elapsed.clamp(0, total).toDouble(),
                onChanged: total <= 0
                    ? null
                    : (value) => _control(
                        () => _player.seek(Duration(milliseconds: value.round())),
                      ),
              );
            },
          );
        },
      ),
      StreamBuilder<PlayerState>(
        stream: _player.playerStateStream,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _player.playerState;
          final playing =
              state.playing && state.processingState != ProcessingState.completed;
          return IconButton(
            tooltip: playing ? 'Pausar' : 'Reproduzir',
            onPressed: playing ? () => _control(_player.pause) : _play,
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
          );
        },
      ),
    ],
  );
}
