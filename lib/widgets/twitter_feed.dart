import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class TwitterFeed extends StatefulWidget {
  final String username;

  const TwitterFeed({super.key, required this.username});

  @override
  State<TwitterFeed> createState() => _TwitterFeedState();
}

class _TwitterFeedState extends State<TwitterFeed> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(
        Uri.parse(
          'https://platform.twitter.com/widgets/timeline/profile?screen_name=${widget.username}&theme=light&chrome=noheader%20nofooter%20noborders%20transparent',
        ),
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            launchUrl(Uri.parse(request.url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: 500,
          child: WebViewWidget(controller: _controller),
        ),
        if (_isLoading)
          Container(
            height: 500,
            color: Theme.of(context).scaffoldBackgroundColor,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
} 