<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

BirdPress is a Markdown-based blogging platform that can be used as a standalone
Flutter app or embedded inside of another Flutter app.

## Example
![birdpress example blog](https://raw.githubusercontent.com/imichaelnorris/birdpress/master/Screen%20Shot%202022-06-03%20at%201.51.39%20PM.png)

## Features

* Write blog posts in Markdown.

## Getting started

BirdPress is currently under development, all APIs are subject to change before
the 1.0.0 release. The documentation will be kept up-to-date to my best-effort.

* install the birdpress plugin. 
* update assets/birdpress/index.md
* write blogposts in assets/birdpress/posts/
* follow birdpress/lib/main.dart to see how to use BirdPress in an existing flutter app


## Usage

BirdPress is a Flutter widget, run it as a standalone Flutter app like so:

```dart
main() {
  runApp(BirdPress());
}
```

## Additional information

I am currently investigating the following features:
[ ] Flutter-based templating for designing layouts

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
