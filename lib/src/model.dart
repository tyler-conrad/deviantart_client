import 'package:equatable/equatable.dart' as eq;

/// Represents a user in the application.
///
/// Each user has a unique [userID], a [userName], and a [userIcon]. The
/// [userID] is a string that uniquely identifies the user. The [userName] is
/// the name of the user. The [userIcon] is the icon associated with the user.
///
/// The [User.fromJSON] factory method creates a new [User] instance from a JSON
/// map. It requires a decoded map that contains the keys 'userid', 'username',
/// and 'usericon'.
class User extends eq.Equatable {
  final String userID;
  final String userName;
  final String userIcon;

  @override
  List<Object> get props => [userID, userName, userIcon];

  @override
  bool get stringify => true;

  /// Represents a user.
  ///
  /// Each user has a unique [userID] and is identified by their [userName].
  /// The [userIcon] represents the icon associated with the user.
  const User({
    required this.userID,
    required this.userName,
    required this.userIcon,
  });

  /// Creates a [User] object from a JSON [decoded] map.
  ///
  /// The [decoded] map should contain the following keys:
  /// - 'userid': The ID of the user.
  /// - 'username': The name of the user.
  /// - 'usericon': The icon of the user.
  factory User.fromJSON({required Map<String, dynamic> decoded}) {
    return User(
      userID: decoded['userid'],
      userName: decoded['username'],
      userIcon: decoded['usericon'],
    );
  }
}

/// Represents an image with its [src], [width], [height], and [transparency].
class Image extends eq.Equatable {
  final String src;
  final int width;
  final int height;
  final bool transparency;

  /// Creates a new instance of the [Image] class.
  ///
  /// The [src] parameter specifies the source of the image.
  /// The [width] parameter specifies the width of the image.
  /// The [height] parameter specifies the height of the image.
  /// The [transparency] parameter specifies whether the image has transparency.
  const Image({
    required this.src,
    required this.width,
    required this.height,
    required this.transparency,
  });

  /// Creates a new instance of the [Image] class from a JSON decoded map.
  ///
  /// The [decoded] parameter is a map containing the decoded JSON data.
  factory Image.fromJSON({required Map<String, dynamic> decoded}) {
    return Image(
      src: decoded['src'],
      width: decoded['width'],
      height: decoded['height'],
      transparency: decoded['transparency'],
    );
  }

  @override
  List<Object> get props => [src, width, height, transparency];

  @override
  bool get stringify => true;
}

/// Represents a full-size image with additional information about its file
/// size.
class FullSizeImage extends Image {
  /// The file size of the image.
  final int fileSize;

  @override
  List<Object> get props => [src, width, height, transparency, fileSize];

  @override
  bool get stringify => true;

  /// Creates a new instance of [FullSizeImage].
  const FullSizeImage({
    required super.src,
    required super.width,
    required super.height,
    required super.transparency,
    required this.fileSize,
  });

  /// Creates a new instance of [FullSizeImage] from a JSON map.
  ///
  /// The [decoded] parameter is a map containing the decoded JSON data.
  factory FullSizeImage.fromJSON({required Map<String, dynamic> decoded}) {
    return FullSizeImage(
        src: decoded['src'],
        width: decoded['width'],
        height: decoded['height'],
        transparency: decoded['transparency'],
        fileSize: decoded['filesize']);
  }
}

/// Represents a deviation item.
class DeviationItem extends eq.Equatable {
  /// The unique identifier of the deviation item.
  final String id;

  /// Indicates whether the deviation item is deleted or not.
  final bool isDeleted;

  /// Indicates whether the deviation item is published or not.
  final bool isPublished;

  /// The title of the deviation item.
  final String title;

  /// The category of the deviation item.
  final String category;

  /// The author of the deviation item.
  final User author;

  /// The preview image of the deviation item.
  final Image? preview;

  /// The full-size image content of the deviation item.
  final FullSizeImage? content;

  /// The list of thumbnail images associated with the deviation item.
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

  /// Creates a new instance of [DeviationItem].
  const DeviationItem({
    required this.id,
    required this.isDeleted,
    required this.isPublished,
    required this.title,
    required this.category,
    required this.author,
    required this.preview,
    required this.content,
    required this.thumbs,
  });

  /// Creates a new instance of [DeviationItem] from a JSON map.
  ///
  /// The [decoded] parameter represents the decoded JSON map.
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

/// Represents a topic.
class Topic {
  final String name;
  final String canonicalName;
  final List<DeviationItem> examples;

  /// Creates a new instance of [Topic].
  const Topic({
    required this.name,
    required this.canonicalName,
    required this.examples,
  });

  /// Creates a [Topic] instance from a JSON [decoded] map.
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

/// Represents a collection of items.
///
/// A collection is identified by its [folderID] and has a [name].
/// It is owned by a [User].
class Collection extends eq.Equatable {
  final int folderID;
  final String name;
  final User owner;

  @override
  List<Object> get props => [folderID, name, owner];

  @override
  bool get stringify => true;

  /// Represents a collection in the DeviantArt client.
  ///
  /// Each collection has a unique [folderID] that identifies it.
  /// [name] is the name of the collection.
  /// [owner] is the owner of the collection.
  const Collection({
    required this.folderID,
    required this.name,
    required this.owner,
  });

  /// Factory method to create a [Collection] object from a JSON [Map].
  ///
  /// The [decoded] parameter is a required [Map] containing the decoded JSON data.
  /// Returns a new instance of [Collection] with the properties set based on the decoded data.
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

/// Represents a suggested collection with a collection and a list of
/// deviations.
class SuggestedCollection extends eq.Equatable {
  final Collection collection;
  final List<DeviationItem> deviations;

  /// Creates a new instance of [SuggestedCollection].
  ///
  /// [collection] is the collection associated with the suggested collection.
  /// [deviations] is a list of deviations associated with the suggested
  /// collection.
  const SuggestedCollection({
    required this.collection,
    required this.deviations,
  });

  /// Creates a new instance of [SuggestedCollection] from a JSON [decoded] map.
  ///
  /// The [decoded] parameter represents the decoded JSON map.
  factory SuggestedCollection.fromJSON(
      {required Map<String, dynamic> decoded}) {
    return SuggestedCollection(
      collection: Collection.fromJSON(decoded: decoded['collection']),
      deviations: decoded['deviations']
          .map<DeviationItem>((item) => DeviationItem.fromJSON(decoded: item))
          .toList(),
    );
  }

  @override
  List<Object> get props => [collection, ...deviations];

  @override
  bool get stringify => true;
}
