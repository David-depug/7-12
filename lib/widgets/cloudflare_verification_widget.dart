import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import '../services/cloudflare_service.dart';

class CloudflareVerificationWidget extends StatefulWidget {
  final Function(bool verified, String? token) onVerificationComplete;

  const CloudflareVerificationWidget({
    super.key,
    required this.onVerificationComplete,
  });

  @override
  State<CloudflareVerificationWidget> createState() =>
      _CloudflareVerificationWidgetState();
}

class _CloudflareVerificationWidgetState
    extends State<CloudflareVerificationWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      )
      ..addJavaScriptChannel(
        'ToDart',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message);
            if (data['type'] == 'turnstile_response') {
              widget.onVerificationComplete(true, data['token']);
            } else if (data['type'] == 'turnstile_error') {
              widget.onVerificationComplete(false, null);
            }
          } catch (e) {
            widget.onVerificationComplete(false, null);
          }
        },
      );

    _loadTurnstileWidget();
  }

  void _loadTurnstileWidget() {
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Security Check</title>
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
    <style>
        body {
            margin: 0;
            padding: 20px;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 200px;
            font-family: Arial, sans-serif;
            background-color: transparent;
        }
        .turnstile-container {
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .cf-turnstile {
            width: 300px;
            height: 65px;
        }
    </style>
</head>
<body>
    <div class="turnstile-container">
        <div class="cf-turnstile" data-sitekey="${CloudflareService.getSiteKey()}" data-callback="onSuccess" data-error-callback="onError"></div>
    </div>

    <script>
        // Ensure turnstile is properly loaded
        function initTurnstile() {
            if (typeof turnstile !== 'undefined') {
                // Turnstile is loaded, render the widget
                turnstile.render('.cf-turnstile', {
                    sitekey: '${CloudflareService.getSiteKey()}',
                    callback: onSuccess,
                    'error-callback': onError,
                });
            } else {
                // Retry after a delay
                setTimeout(initTurnstile, 500);
            }
        }
        
        // Initialize when page loads
        window.onload = function() {
            // Give some time for the script to load
            setTimeout(initTurnstile, 1000);
        };

        function onSuccess(token) {
            // Send token to Flutter
            ToDart.postMessage(JSON.stringify({
                'type': 'turnstile_response',
                'token': token
            }));
        }

        function onError() {
            // Send error to Flutter
            ToDart.postMessage(JSON.stringify({
                'type': 'turnstile_error',
                'token': null
            }));
        }
    </script>
</body>
</html>
    ''';

    _controller.loadHtmlString(htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: _hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 40,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Failed to load security verification',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadTurnstileWidget,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : WebViewWidget(controller: _controller),
    );
  }
}
