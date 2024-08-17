/// Time ranges for filtering data.
enum TimeRange {
  now,
  oneWeek,
  oneMonth,
  allTime,
}

/// An abstract class representing the arguments for a response callback.
abstract class ResponseCallbackArgs {}

/// Represents the metadata for a single direction paginator response.
///
/// This class extends [ResponseCallbackArgs] and provides information about
/// whether there is more data available, the offset for the next page, and any
/// error code associated with the response.
class SingleDirectionPaginatorResponseMetadata extends ResponseCallbackArgs {
  bool hasMore;
  int? nextOffset;
  int? errorCode;

  /// Creates a new instance of [SingleDirectionPaginatorResponseMetadata].
  ///
  /// [hasMore] indicates whether there is more data available.
  /// [nextOffset] specifies the offset for the next page.
  /// [errorCode] is any error code associated with the response.
  SingleDirectionPaginatorResponseMetadata({
    required this.hasMore,
    required this.nextOffset,
    required this.errorCode,
  });

  /// Creates a standard instance of [SingleDirectionPaginatorResponseMetadata].
  SingleDirectionPaginatorResponseMetadata.standard()
      : this(hasMore: true, nextOffset: 0, errorCode: null);

  /// Creates a new instance of [SingleDirectionPaginatorResponseMetadata] from
  /// a JSON object.
  ///
  /// The [decoded] parameter is a map containing the decoded JSON data.
  factory SingleDirectionPaginatorResponseMetadata.fromJSON(
      {required Map<String, dynamic> decoded}) {
    return SingleDirectionPaginatorResponseMetadata(
      hasMore: decoded['has_more'],
      nextOffset: decoded['next_offset'],
      errorCode: decoded['error_code'],
    );
  }
}
