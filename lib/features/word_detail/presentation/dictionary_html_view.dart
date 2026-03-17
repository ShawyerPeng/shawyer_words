import 'package:flutter/material.dart';
import 'package:shawyer_words/features/word_detail/domain/dictionary_entry_detail.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_document.dart';
import 'package:shawyer_words/features/word_detail/presentation/dictionary_html_file_store.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class DictionaryHtmlView extends StatefulWidget {
  const DictionaryHtmlView({
    super.key,
    required this.panel,
    this.onEntryLinkTap,
    this.onSoundLinkTap,
  });

  final DictionaryEntryDetail panel;
  final ValueChanged<String>? onEntryLinkTap;
  final ValueChanged<String>? onSoundLinkTap;

  @override
  State<DictionaryHtmlView> createState() => _DictionaryHtmlViewState();
}

class _DictionaryHtmlViewState extends State<DictionaryHtmlView> {
  static const double _minContentHeight = 120;

  late final WebViewController _controller;
  late final DictionaryHtmlFileStore _fileStore;
  late String _loadedSignature;
  int _loadRevision = 0;
  double _contentHeight = _minContentHeight;

  @override
  void initState() {
    super.initState();
    _fileStore = DictionaryHtmlFileStore();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'ShawyerResize',
        onMessageReceived: (message) {
          final height = double.tryParse(message.message);
          if (height == null) {
            return;
          }
          final normalizedHeight = height < _minContentHeight
              ? _minContentHeight
              : height;
          if ((normalizedHeight - _contentHeight).abs() < 8) {
            return;
          }
          if (!mounted) {
            return;
          }
          setState(() {
            _contentHeight = normalizedHeight;
          });
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final targetWord = _entryTargetWord(request.url);
            if (targetWord != null) {
              widget.onEntryLinkTap?.call(targetWord);
              return NavigationDecision.prevent;
            }
            final soundUrl = _soundTargetUrl(request.url);
            if (soundUrl != null) {
              widget.onSoundLinkTap?.call(soundUrl);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      platformController.setAllowFileAccess(true);
    }
    _loadedSignature = '';
    _loadCurrentDocument();
  }

  @override
  void didUpdateWidget(covariant DictionaryHtmlView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_signatureFor(widget.panel) != _loadedSignature) {
      _loadCurrentDocument();
    }
  }

  Future<void> _loadCurrentDocument() async {
    final document = buildDictionaryHtmlDocument(widget.panel);
    final signature = _signatureFor(widget.panel);
    final revision = ++_loadRevision;
    _loadedSignature = signature;
    if (mounted) {
      setState(() {
        _contentHeight = _minContentHeight;
      });
    }
    final htmlFile = await _fileStore.writeDocument(
      detail: widget.panel,
      document: document,
      signature: signature,
    );
    if (!mounted || revision != _loadRevision) {
      return;
    }
    await _controller.loadFile(htmlFile.absolute.path);
  }

  String _signatureFor(DictionaryEntryDetail detail) {
    return [
      detail.dictionaryId,
      detail.word,
      detail.rawContent,
      detail.resourcesPath ?? '',
      ...detail.stylesheetPaths,
      ...detail.scriptPaths,
    ].join('|');
  }

  String? _entryTargetWord(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'entry') {
      return null;
    }
    final rawTarget = uri.path.isNotEmpty ? uri.path : uri.host;
    final normalizedTarget = Uri.decodeComponent(rawTarget).trim();
    if (normalizedTarget.isEmpty) {
      return null;
    }
    return normalizedTarget;
  }

  String? _soundTargetUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'sound') {
      return null;
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _contentHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: WebViewWidget(
          key: ValueKey('dictionary-html-webview-${widget.panel.dictionaryId}'),
          controller: _controller,
        ),
      ),
    );
  }
}
