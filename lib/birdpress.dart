library birdpress;

import 'dart:convert';
import 'dart:math';

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

  // How many lines to render for a preview post. Includes whitespace.
  final int previewLines;

  // How many pixels high the preview widgets will be.
  final double previewHeight;

  // What order the posts are in the posts directory. Posts should have
  // ordered titles to ensure they're posted in order.
  final PostOrder postOrder;

  const BirdPressSettings({
    this.postsDir = "assets/birdpress/posts",
    this.indexFile = "assets/birdpress/index.md",
    this.markdownSettings = const MarkdownSettings(),
    this.showPreview = true,
    this.title = "BirdPress",
    this.postsPath = "posts",
    this.blogPrefix = "",
    this.previewLines = 10,
    this.previewHeight = 100,
    this.postOrder = PostOrder.ascending,
  });

  static BirdPressSettings of(BuildContext context) {
    return Provider.of<BirdPressSettings>(context);
  }
}

enum PostOrder { ascending, descending }

typedef LinkCallback = void Function(String text, String? url, String title);

class MarkdownSettings {
  final LinkCallback onTapLink;

  const MarkdownSettings({this.onTapLink = MarkdownSettings._onTapLink});

  static void _onTapLink(String text, String? url, String title) {
    launchUrl(Uri.parse(url!));
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
    return Column(
      children: [
        settings.title.isNotEmpty ? Text(settings.title) : Container(),
        Expanded(
          child: ListView.separated(
            itemCount: widgets.length,
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            separatorBuilder: (_, index) => const Divider(thickness: 5),
            itemBuilder: (_, index) => widgets[index],
          ),
        ),
      ],
    );
  }

  Widget index(BuildContext context) {
    return MarkdownPage(BirdPressSettings.of(context).indexFile);
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
        BirdPressSettings settings = BirdPressSettings.of(context);
        if (!snapshot.hasData) {
          // TODO: add loading screen.
          return SizedBox(
              height: settings.previewHeight,
              child: const Text("loading previews..."));
        } else if (snapshot.hasError) {
          // TODO: add error page.
          return SizedBox(
              height: settings.previewHeight,
              child: const Text("error loading previews"));
        }

        List<Widget> previews = snapshot.data!
            .map((asset) => MarkdownPage(asset, preview: true))
            .toList();
        if (settings.postOrder == PostOrder.descending) {
          previews = previews.reversed.toList();
        }

        // TODO: add pagination.
        // PageParams args =
        //     ModalRoute.of(context)!.settings.arguments as PageParams;

        return ListView.separated(
            shrinkWrap: true,
            itemCount: previews.length,
            separatorBuilder: (_, index) => const Divider(),
            itemBuilder: (_, index) => previews[index]);
      },
    );
  }

// Widget navigationBar(BuildContext context) {
//
// }
}

// Params for which page is being viewed and any other information that would
// affect the order of pages being shown.
class PageParams extends ChangeNotifier {
  final int page;

  PageParams({this.page = 0});
}

class MarkdownPage extends StatelessWidget {
  final String asset;
  final bool preview;

  const MarkdownPage(this.asset, {this.preview = false, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: BirdFeeder.of(context).readOrLoadAsset(context, asset),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          BirdPressSettings settings = BirdPressSettings.of(context);
          if (!snapshot.hasData) {
            // TODO: add loading screen.
            return SizedBox(
                width: 10,
                height: settings.previewHeight,
                child: const Text("loading..."));
          } else if (snapshot.hasError) {
            // TODO: add error page.
            return SizedBox(
                width: 10,
                height: settings.previewHeight,
                child: const Text("404"));
          }
          String data = snapshot.data!;

          if (preview) {
            data = data
                .split("\n")
                .sublist(
                    0,
                    min(
                      data.split("\n").length,
                      BirdPressSettings.of(context).previewLines,
                    ))
                .join("\n");
          }
          return Markdown(
            data: data,
            // TODO: possibly make this !preview.
            shrinkWrap: true,
            onTapLink: settings.markdownSettings.onTapLink,
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
