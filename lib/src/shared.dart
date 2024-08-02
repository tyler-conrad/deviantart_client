enum TimeRange {
  now,
  oneWeek,
  oneMonth,
  allTime,
}

abstract class ResponseCallbackArgs {}

class SingleDirectionPaginatorResponseMetadata extends ResponseCallbackArgs {
  bool hasMore;
  int? nextOffset;
  int? errorCode;

  SingleDirectionPaginatorResponseMetadata({
    required this.hasMore,
    required this.nextOffset,
    required this.errorCode,
  });

  SingleDirectionPaginatorResponseMetadata.standard()
      : this(hasMore: true, nextOffset: 0, errorCode: null);

  factory SingleDirectionPaginatorResponseMetadata.fromJSON(
      {required Map<String, dynamic> decoded}) {
    return SingleDirectionPaginatorResponseMetadata(
      hasMore: decoded['has_more'],
      nextOffset: decoded['next_offset'],
      errorCode: decoded['error_code'],
    );
  }
}
