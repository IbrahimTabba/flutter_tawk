import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'tawk_visitor.dart';

/// [Tawk] Widget.
class Tawk extends StatefulWidget {
  /// Tawk direct chat link.
  final String directChatLink;

  /// Object used to set the visitor name and email.
  final TawkVisitor visitor;

  /// Called right after the widget is rendered.
  final Function() onLoad;

  /// Called when a link pressed.
  final Function(String url) onLinkTap;

  /// Render your own loading widget.
  final Widget placeholder;

  Tawk({
    @required this.directChatLink,
    this.visitor,
    this.onLoad,
    this.onLinkTap,
    this.placeholder,
  });

  @override
  _TawkState createState() => _TawkState();
}

class _TawkState extends State<Tawk> {
  WebViewController _controller;
  bool _isLoading = true;

  void _setUser(TawkVisitor visitor) {
    final json = jsonEncode(visitor);
    String javascriptString;

    if (Platform.isIOS) {
      javascriptString = '''
        Tawk_API = Tawk_API || {};
        Tawk_API.onLoad = function() {
          Print.postMessage("Hello World being called from Javascript code");
          Tawk_API.setAttributes($json);
        };
        Tawk_API.onStatusChange = function(status){
          Print.postMessage(status);
        };
        Tawk_API.onChatEnded = function(){
          Print.postMessage("chat ended");
        };
      ''';
    } else {
      javascriptString = '''
        Tawk_API = Tawk_API || {};
        Tawk_API.onLoad = function() {
          Print.postMessage("Hello World being called from Javascript code");
          Tawk_API.setAttributes($json);
        };
        Tawk_API.onStatusChange = function(status){
          Print.postMessage(status);
        };
      ''';
    }

    _controller.evaluateJavascript(javascriptString);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebView(
          initialUrl: widget.directChatLink,
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            setState(() {
              _controller = webViewController;
            });
          },
          navigationDelegate: (NavigationRequest request) {
            if (request.url == 'about:blank' ||
                request.url.contains('tawk.to')) {
              return NavigationDecision.navigate;
            }

            if (widget.onLinkTap != null) {
              widget.onLinkTap(request.url);
            }

            return NavigationDecision.prevent;
          },
          onPageFinished: (_) {
            if (widget.visitor != null) {
              _setUser(widget.visitor);
            }

            if (widget.onLoad != null) {
              widget.onLoad();
            }

            setState(() {
              _isLoading = false;
            });
          },
        ),
        _isLoading
            ? widget.placeholder ??
                const Center(
                  child: CircularProgressIndicator(),
                )
            : Container(),
      ],
    );
  }
}
