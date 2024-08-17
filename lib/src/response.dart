import 'package:equatable/equatable.dart' as eq;

import 'model.dart' as m;

/// Base class for all response objects.
abstract class ResponseBase {}

/// Represents a response for browsing.
///
/// Contains a list of [m.DeviationItem] objects.
///
/// The [BrowseResponse] constructor requires a non-null list of [items].
///
/// The [BrowseResponse.fromJSON] factory method creates a new instance of
/// [BrowseResponse] from a decoded list of dynamic objects. It maps each
/// decoded item to a [m.DeviationItem] using the [m.DeviationItem.fromJSON]
/// method and converts the result to a list.
class BrowseResponse extends ResponseBase with eq.EquatableMixin {
  final List<m.DeviationItem> items;

  @override
  List<Object> get props => items;

  @override
  bool get stringify => true;

  BrowseResponse({required this.items});

  /// Creates a [BrowseResponse] object from a JSON [decoded] list.
  factory BrowseResponse.fromJSON({required List<dynamic> decoded}) {
    return BrowseResponse(
      items: decoded
          .map((item) => m.DeviationItem.fromJSON(decoded: item))
          .toList(),
    );
  }
}

/// Represents a response object for the "More Like This" feature.
///
/// This class contains information about the seed, author, and various lists of
/// deviation items and suggested collections.
class MoreLikeThisResponse extends ResponseBase with eq.EquatableMixin {
  /// The seed used for generating similar content.
  final String seed;

  /// The author of the content.
  final m.User author;

  /// A list of deviation items from the same artist.
  final List<m.DeviationItem> moreFromArtist;

  /// A list of deviation items from DeviantArt.
  final List<m.DeviationItem> moreFromDA;

  /// A list of suggested collections related to the content.
  final List<m.SuggestedCollection> suggestedCollections;

  @override
  List<Object?> get props => [
        seed,
        author,
        moreFromArtist,
        moreFromDA,
        suggestedCollections,
      ];

  @override
  bool? get stringify => true;

  /// Creates a new instance of [MoreLikeThisResponse].
  MoreLikeThisResponse({
    required this.seed,
    required this.author,
    required this.moreFromArtist,
    required this.moreFromDA,
    required this.suggestedCollections,
  });

  /// Creates an instance of [MoreLikeThisResponse] from a decoded JSON map.
  ///
  /// The [decoded] parameter is a map containing the decoded JSON data.
  factory MoreLikeThisResponse.fromJSON(
      {required Map<String, dynamic> decoded}) {
    List<dynamic> suggestedCollections = decoded['suggested_collections'] ?? [];
    return MoreLikeThisResponse(
      seed: decoded['seed'],
      author: m.User.fromJSON(decoded: decoded['author']),
      moreFromArtist: decoded['more_from_artist']
          .map<m.DeviationItem>(
              (item) => m.DeviationItem.fromJSON(decoded: item))
          .toList(),
      moreFromDA: decoded['more_from_da']
          .map<m.DeviationItem>(
              (item) => m.DeviationItem.fromJSON(decoded: item))
          .toList(),
      suggestedCollections: suggestedCollections
          .map<m.SuggestedCollection>(
              (item) => m.SuggestedCollection.fromJSON(decoded: item))
          .toList(),
    );
  }
}

/// Response for a tag search.
///
/// The [tags] property represents the list of tags returned in the response.
///
/// The [TagSearchResponse] class has a constructor that takes a required
/// parameter [tags] which represents the list of tags.
///
/// The [TagSearchResponse.fromJSON] factory method is used to create an
/// instance of [TagSearchResponse] from a JSON object. It takes a required
/// parameter `decoded` which is a list of dynamic objects representing the
/// decoded JSON.
class TagSearchResponse extends ResponseBase with eq.EquatableMixin {
  final List<String> tags;

  @override
  List<Object> get props => tags;

  @override
  bool get stringify => true;

  TagSearchResponse({required this.tags});

  /// Creates a [TagSearchResponse] instance from the provided JSON data.
  ///
  /// The [decoded] parameter should be a list of dynamic objects representing
  /// the decoded JSON response.
  factory TagSearchResponse.fromJSON({required List<dynamic> decoded}) {
    return TagSearchResponse(
        tags: decoded.map<String>((tag) => tag['tag_name']).toList());
  }
}

/// Response for listing topics.
///
/// The [ListTopicsResponse] class has a constructor that takes a required
/// parameter [topics].
///
/// The [ListTopicsResponse.fromJSON] factory constructor creates an instance
/// of [ListTopicsResponse] from a JSON decoded list. It maps each decoded topic
/// to an instance of [m.Topic] using the [m.Topic.fromJSON] method, and then
/// converts the mapped topics to a list.
class ListTopicsResponse extends ResponseBase with eq.EquatableMixin {
  final List<m.Topic> topics;

  @override
  List<Object> get props => topics;

  @override
  bool get stringify => true;

  ListTopicsResponse({required this.topics});

  /// Creates a [ListTopicsResponse] object from a JSON [decoded] data.
  ///
  /// The [decoded] parameter is a required list of dynamic objects representing
  /// the decoded JSON data.
  factory ListTopicsResponse.fromJSON({required List<dynamic> decoded}) {
    return ListTopicsResponse(
      topics: decoded
          .map<m.Topic>((topic) => m.Topic.fromJSON(decoded: topic))
          .toList(),
    );
  }
}
