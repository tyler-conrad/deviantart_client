import 'package:equatable/equatable.dart' as eq;

import 'model.dart' as m;

abstract class ResponseBase {}

class BrowseResponse extends ResponseBase with eq.EquatableMixin {
  final List<m.DeviationItem> items;

  @override
  List<Object> get props => items;

  @override
  bool get stringify => true;

  BrowseResponse({required this.items});

  factory BrowseResponse.fromJSON({required List<dynamic> decoded}) {
    return BrowseResponse(
      items: decoded
          .map((item) => m.DeviationItem.fromJSON(decoded: item))
          .toList(),
    );
  }
}

class MoreLikeThisResponse extends ResponseBase with eq.EquatableMixin {
  final String seed;
  final m.User author;
  final List<m.DeviationItem> moreFromArtist;
  final List<m.DeviationItem> moreFromDA;
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

  MoreLikeThisResponse({
    required this.seed,
    required this.author,
    required this.moreFromArtist,
    required this.moreFromDA,
    required this.suggestedCollections,
  });

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

class TagSearchResponse extends ResponseBase with eq.EquatableMixin {
  final List<String> tags;

  @override
  List<Object> get props => tags;

  @override
  bool get stringify => true;

  TagSearchResponse({required this.tags});

  factory TagSearchResponse.fromJSON({required List<dynamic> decoded}) {
    return TagSearchResponse(
        tags: decoded.map<String>((tag) => tag['tag_name']).toList());
  }
}

class ListTopicsResponse extends ResponseBase with eq.EquatableMixin {
  final List<m.Topic> topics;

  @override
  List<Object> get props => topics;

  @override
  bool get stringify => true;

  ListTopicsResponse({required this.topics});

  factory ListTopicsResponse.fromJSON({required List<dynamic> decoded}) {
    return ListTopicsResponse(
      topics: decoded
          .map<m.Topic>((topic) => m.Topic.fromJSON(decoded: topic))
          .toList(),
    );
  }
}
