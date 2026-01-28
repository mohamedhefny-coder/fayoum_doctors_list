import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

class IntroVideoPlayerScreen extends StatefulWidget {
  final String url;
  final String title;

  const IntroVideoPlayerScreen({
    super.key,
    required this.url,
    this.title = 'فيديو تعريفي',
  });

  @override
  State<IntroVideoPlayerScreen> createState() => _IntroVideoPlayerScreenState();
}

class _IntroVideoPlayerScreenState extends State<IntroVideoPlayerScreen> {
  VideoPlayerController? _controller;
  Future<void>? _initFuture;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final uri = Uri.tryParse(widget.url);
      if (uri == null || !uri.hasScheme) {
        setState(() {
          _error = 'رابط غير صالح.';
        });
        return;
      }

      final controller = VideoPlayerController.networkUrl(uri);
      setState(() {
        _controller = controller;
        _initFuture = controller.initialize();
      });

      controller.addListener(() {
        if (!mounted) return;
        if (controller.value.hasError) {
          final desc = controller.value.errorDescription;
          setState(() {
            _error = desc == null || desc.trim().isEmpty
                ? 'تعذر تشغيل الفيديو.'
                : 'تعذر تشغيل الفيديو: $desc';
          });
        }
      });

      await _initFuture;
      if (!mounted) return;

      if (controller.value.hasError) {
        final desc = controller.value.errorDescription;
        setState(() {
          _error = desc == null || desc.trim().isEmpty
              ? 'تعذر تشغيل الفيديو.'
              : 'تعذر تشغيل الفيديو: $desc';
        });
        return;
      }

      await controller.setLooping(true);
      await controller.play();
      if (!mounted) return;

      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذر تشغيل الفيديو: $e';
      });
    }
  }

  Future<void> _openExternally() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'نصيحة: تأكد أن الرابط مباشر لملف فيديو (MP4) وأنه متاح بدون صلاحيات خاصة.\n'
                      'إذا كان الفيديو مرفوعاً على Supabase فتأكد أن الـ bucket مسموح بالقراءة أو الرابط عام.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _openExternally,
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('فتح خارجي'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('رجوع'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : (controller == null || _initFuture == null)
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<void>(
                  future: _initFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!controller.value.isInitialized) {
                      return const Center(child: Text('تعذر تهيئة الفيديو.'));
                    }

                    return Column(
                      children: [
                        AspectRatio(
                          aspectRatio: controller.value.aspectRatio == 0
                              ? (16 / 9)
                              : controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(
                                controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (controller.value.isPlaying) {
                                    controller.pause();
                                  } else {
                                    controller.play();
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.replay_10),
                              onPressed: () async {
                                final pos = controller.value.position;
                                final next = pos - const Duration(seconds: 10);
                                await controller.seekTo(
                                  next < Duration.zero ? Duration.zero : next,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10),
                              onPressed: () async {
                                final pos = controller.value.position;
                                final dur = controller.value.duration;
                                final next = pos + const Duration(seconds: 10);
                                await controller.seekTo(
                                  next > dur ? dur : next,
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            widget.url,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}
