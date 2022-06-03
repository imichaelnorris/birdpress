library birdpress;

import 'dart:convert';

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
    String postsPath = "/${settings.postsPath}";
    if (settings.blogPrefix.isNotEmpty) {
      postsPath = "/${settings.blogPrefix}$postsPath";
    }
    return MultiProvider(
      providers: [
        Provider(create: (_) => settings),
        Provider(create: (_) => BirdFeeder()),
        Provider(create: (_) => PageParams()),
      ],
      child: MaterialApp(
        initialRoute: "/",
        routes: {
          "/${settings.blogPrefix}": (context) => const BirdHouse(),
          postsPath: (context) => const PostPreviews(),
        },
      ),
    );
  }
}

typedef WidgetClosure = void Function();

class BirdPressSettings {
  // Directory that posts are in.
  final String postsDir;

  // file that the index markdown is in.
  final String indexFile;

  // Settings for rendering Markdown.
  final MarkdownSettings markdownSettings;

  // Show preview of new blog posts on the main page.
  final bool showPreview;

  // Title for the BirdPress site.
  final String title;

  // Path for posts. blog.com/$postsPath
  final String postsPath;

  // Path for index. defaults to "", which is blog.com
  final String blogPrefix;

  const BirdPressSettings({
    this.postsDir = "assets/birdpress/posts",
    this.indexFile = "assets/birdpress/index.md",
    this.markdownSettings = const MarkdownSettings(),
    this.showPreview = true,
    this.title = "BirdPress",
    this.postsPath = "posts",
    this.blogPrefix = "",
  });

  static BirdPressSettings of(BuildContext context) {
    return Provider.of<BirdPressSettings>(context);
  }
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
// TODO: make it so if someone doesn't like the layout they can subclass this.
//       I am making it so the components of the page are in member functions
//       so it's easy to re-compose or restyle it in a subclass.
class BirdHouse extends StatelessWidget {
  const BirdHouse({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    BirdPressSettings settings = BirdPressSettings.of(context);
    // BirdFeeder feeder = BirdFeeder.of(context);
    // Pseudocode of what this should look like. If asset is not null and
    // index.md exists, then render index page. If settings.show_preview exists
    // then show a preview containing the first 10 posts. Figure out pagination
    // later. Previews should be defined by settings as well, show this many
    // lines / characters and a read more link or something like that.
    List<Widget> widgets = [];
    if (settings.indexFile.isNotEmpty) {
      widgets.add(index(context));
    }
    if (settings.showPreview) {
      widgets.add(previews(context));
    }
    return SizedBox(
      height: 400,
      child: ListView.separated(
        itemCount: widgets.length,
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        separatorBuilder: (_, index) => const Divider(thickness: 5),
        itemBuilder: (_, index) => widgets[index],
      ),
    );
  }

  Widget index(BuildContext context) {
    return SizedBox(
        height: 250,
        child: MarkdownPage(BirdPressSettings.of(context).indexFile));
  }

  Widget previews(BuildContext context) {
    return const PostPreviews();
  }
}

class PostPreviews extends StatelessWidget {
  const PostPreviews({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: BirdFeeder.of(context).listPostNames(context),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (!snapshot.hasData) {
          print("PostPreview loading...");
          // TODO: add loading screen.
          return SizedBox(width: 10, height: 10, child: Container());
        } else if (snapshot.hasError) {
          print("PostPreview error");
          // TODO: add error page.
          return SizedBox(width: 10, height: 10, child: Container());
        }

        List<Widget> previews = snapshot.data!
            .map((asset) => SizedBox(height: 200, child: MarkdownPage(asset)))
            .toList();

        return ListView.separated(
            shrinkWrap: true,
            itemCount: previews.length,
            separatorBuilder: (_, index) => const Divider(),
            itemBuilder: (_, index) => previews[index]);
      },
    );
  }
}

// Params for which page is being viewed and any other information that would
// affect the order of pages being shown.
class PageParams extends ChangeNotifier {
  final int page;

  PageParams({this.page = 0});
}

class MarkdownPage extends StatelessWidget {
  final String asset;

  const MarkdownPage(this.asset, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: BirdFeeder.of(context).readOrLoadAsset(context, asset),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (!snapshot.hasData) {
            // TODO: add loading screen.
            return const SizedBox(
                width: 10, height: 10, child: Text("loading..."));
          } else if (snapshot.hasError) {
            // TODO: add error page.
            return const SizedBox(width: 10, height: 10, child: Text("404"));
          }
          return Markdown(
            data: snapshot.data!,
            onTapLink: BirdPressSettings.of(context).markdownSettings.onTapLink,
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

  Future<List<String>> listPostNames(BuildContext context) async {
    BirdPressSettings settings = Provider.of<BirdPressSettings>(context);
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    // TODO: match from key[0:len(settings.postsDir)] to enforce a prefix match.
    return manifestMap.keys
        .where((String key) => key.contains(settings.postsDir))
        .toList();
  }

  static BirdFeeder of(BuildContext context) {
    return Provider.of<BirdFeeder>(context);
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
