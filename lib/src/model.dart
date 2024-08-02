import 'package:equatable/equatable.dart' as eq;

class User extends eq.Equatable {
  final String userID;
  final String userName;
  final String userIcon;

  @override
  List<Object> get props => [userID, userName, userIcon];

  @override
  bool get stringify => true;

  const User({
    required this.userID,
    required this.userName,
    required this.userIcon,
  });

  factory User.fromJSON({required Map<String, dynamic> decoded}) {
    return User(
        userID: decoded['userid'],
        userName: decoded['username'],
        userIcon: decoded['usericon']);
  }
}

class Image extends eq.Equatable {
  final String src;
  final int width;
  final int height;
  final bool transparency;

  @override
  List<Object> get props => [src, width, height, transparency];

  @override
  bool get stringify => true;

  const Image({
    required this.src,
    required this.width,
    required this.height,
    required this.transparency,
  });

  factory Image.fromJSON({required Map<String, dynamic> decoded}) {
    return Image(
      src: decoded['src'],
      width: decoded['width'],
      height: decoded['height'],
      transparency: decoded['transparency'],
    );
  }
}

class FullSizeImage extends Image {
  final int fileSize;

  @override
  List<Object> get props => [src, width, height, transparency, fileSize];

  @override
  bool get stringify => true;

  const FullSizeImage({
    required super.src,
    required super.width,
    required super.height,
    required super.transparency,
    required this.fileSize,
  });

  factory FullSizeImage.fromJSON({required Map<String, dynamic> decoded}) {
    return FullSizeImage(
        src: decoded['src'],
        width: decoded['width'],
        height: decoded['height'],
        transparency: decoded['transparency'],
        fileSize: decoded['filesize']);
  }
}

class DeviationItem extends eq.Equatable {
  final String id;
  final bool isDeleted;
  final bool isPublished;
  final String title;
  final String category;
  final User author;
  final Image? preview;
  final FullSizeImage? content;
  final List<Image> thumbs;

  @override
  List<Object?> get props => [
        id,
        isDeleted,
        isPublished,
        title,
        category,
        author,
        preview,
        content,
        ...thumbs
      ];

  @override
  bool get stringify => true;

  const DeviationItem(
      {required this.id,
      required this.isDeleted,
      required this.isPublished,
      required this.title,
      required this.category,
      required this.author,
      required this.preview,
      required this.content,
      required this.thumbs});

  factory DeviationItem.fromJSON({required Map<String, dynamic> decoded}) {
    Image? preview = decoded['preview'] == null
        ? null
        : Image.fromJSON(decoded: decoded['preview']);
    FullSizeImage? content = decoded['content'] == null
        ? null
        : FullSizeImage.fromJSON(decoded: decoded['content']);

    return DeviationItem(
      id: decoded['deviationid'],
      isDeleted: decoded['is_deleted'],
      isPublished: decoded['is_published'],
      title: decoded['title'],
      category: decoded['category'],
      author: User.fromJSON(decoded: decoded['author']),
      preview: preview,
      content: content,
      thumbs: decoded['thumbs']
          .map<Image>((thumb) => Image.fromJSON(decoded: thumb))
          .toList(),
    );
  }
}

class Topic extends eq.Equatable {
  final String name;
  final String canonicalName;
  final List<DeviationItem> examples;

  @override
  List<Object> get props => [name, canonicalName, ...examples];

  @override
  bool get stringify => true;

  const Topic(
      {required this.name,
      required this.canonicalName,
      required this.examples});

  factory Topic.fromJSON({required Map<String, dynamic> decoded}) {
    return Topic(
      name: decoded['name'],
      canonicalName: decoded['canonical_name'],
      examples: decoded['example_deviations']
          .map<DeviationItem>((item) => DeviationItem.fromJSON(decoded: item))
          .toList(),
    );
  }
}

class Collection extends eq.Equatable {
  final int folderID;
  final String name;
  final User owner;

  @override
  List<Object> get props => [folderID, name, owner];

  @override
  bool get stringify => true;

  const Collection({
    required this.folderID,
    required this.name,
    required this.owner,
  });

  factory Collection.fromJSON({required Map<String, dynamic> decoded}) {
    return Collection(
      folderID: decoded['folderid'],
      name: decoded['name'],
      owner: User.fromJSON(
        decoded: decoded['owner'],
      ),
    );
  }
}

class SuggestedCollection extends eq.Equatable {
  final Collection collection;
  final List<DeviationItem> deviations;

  @override
  List<Object> get props => [collection, ...deviations];

  @override
  bool get stringify => true;

  const SuggestedCollection({
    required this.collection,
    required this.deviations,
  });

  factory SuggestedCollection.fromJSON(
      {required Map<String, dynamic> decoded}) {
    return SuggestedCollection(
      collection: Collection.fromJSON(decoded: decoded['collection']),
      deviations: decoded['deviations']
          .map<DeviationItem>((item) => DeviationItem.fromJSON(decoded: item))
          .toList(),
    );
  }
}
