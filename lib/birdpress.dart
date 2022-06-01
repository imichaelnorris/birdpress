library birdpress;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// A Calculator.
class BirdPress extends StatelessWidget {
  final BirdPressSettings settings;

  const BirdPress({this.settings = const BirdPressSettings(), Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => settings),
        Provider(create: (_) => BirdFeeder()),
      ],
      child: MaterialApp(
        initialRoute: "/",
        routes: {
          "/": (context) =>
              BirdHouse(Provider.of<BirdPressSettings>(context).indexFile),
        },
      ),
    );
  }
}

class BirdPressSettings {
  final String postsDir;
  final String indexFile;
  final MarkdownSettings markdownSettings;

  const BirdPressSettings({
    this.postsDir = "_posts",
    this.indexFile = "assets/birdpress/index.md",
    this.markdownSettings = const MarkdownSettings(),
  });
}

typedef LinkCallback = void Function(String text, String? url, String title);

class MarkdownSettings {
  final LinkCallback onTapLink;

  const MarkdownSettings({this.onTapLink = MarkdownSettings._onTapLink});

  static void _onTapLink(String text, String? url, String title) {
    launchUrl(Uri(path: url!));
  }
}

// Home Page.
class BirdHouse extends MarkdownPage {
  const BirdHouse(super.asset, {Key? key}) : super(key: key);
}

class MarkdownPage extends StatelessWidget {
  final String asset;

  const MarkdownPage(this.asset, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future:
            Provider.of<BirdFeeder>(context).readOrLoadAsset(context, asset),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (!snapshot.hasData) {
            // TODO: add loading screen.
            return Container();
          } else if (snapshot.hasError) {
            // TODO: add error page.
            return Container();
          }
          return Markdown(
            data: snapshot.data!,
            onTapLink: Provider.of<BirdPressSettings>(context)
                .markdownSettings
                .onTapLink,
          );
        });
  }
}

// TODO: add some kind of check like it has to be in prefix "assets/birdpress"
// or be in a whitelist.
class BirdFeeder {
  Map<String, String> cachedAssets;

  BirdFeeder() : cachedAssets = <String, String>{};

  bool isCached(String asset) {
    return cachedAssets.containsKey(asset);
  }

  Future<String> readOrLoadAsset(BuildContext context, String asset) async {
    return isCached(asset)
        ? Future.value(cachedAssets[asset])
        : loadAsset(context, asset);
  }

  Future<String> loadAsset(BuildContext context, String asset) async {
    return await DefaultAssetBundle.of(context).loadString(asset);
  }
}
