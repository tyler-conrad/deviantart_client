import 'dart:async' as a;

import 'shared.dart' as s;
import 'logger.dart' show l;
import 'response.dart' as res;
import 'request.dart' as req;
import 'client.dart' as c;

abstract class Offset<T extends Comparable> {
  final T min;
  final T max;
  final T defaultValue;

  T _offset;
  T get offset => _offset;
  set offset(T offset);

  void reset() => offset = defaultValue;

  Offset({
    required this.min,
    required this.max,
    required this.defaultValue,
  }) : _offset = defaultValue;
}

class WrappingOffset<T extends Comparable> extends Offset<T> {
  @override
  set offset(T offset) {
    if (offset.compareTo(min) < 0) {
      l.w('Attempted to set Offset.offset to a value less than Offset.min: $offset, setting to Offset.max');
      offset = max;
    } else if (offset.compareTo(max) > 0) {
      l.w('Attempted to set Offset.offset to a value greater than Offset.max: $offset, setting to Offset.min');
      offset = min;
    }
    _offset = offset;
  }

  WrappingOffset({
    required super.min,
    required super.max,
    required super.defaultValue,
  });
}

class _NonWrappingOffset<T extends Comparable> extends Offset<T> {
  @override
  set offset(offset) {
    if (offset.compareTo(min) < 0) {
      l.w('Attempted to set Offset.offset to a value less than Offset.min: $offset, setting to Offset.min');
      offset = min;
    } else if (offset.compareTo(max) > 0) {
      l.w('Attempted to set Offset.offset to a value greater than Offset.max: $offset, setting to Offset.max');
      offset = max;
    }
    _offset = offset;
  }

  _NonWrappingOffset({
    required super.min,
    required super.max,
    required super.defaultValue,
  });
}

class IntBasedNonWrappingOffset extends _NonWrappingOffset<int> {
  IntBasedNonWrappingOffset({
    required super.min,
    required super.max,
    required super.defaultValue,
  });

  IntBasedNonWrappingOffset.standard()
      : this(min: 0, max: 50000, defaultValue: 0);
}

class Limit<T extends Comparable> {
  final T min;
  final T max;
  final T defaultValue;

  T _limit;
  T get limit => _limit;
  set limit(T limit) {
    if (limit.compareTo(min) < 0) {
      l.w('limit less than min: $limit, resetting to min');
      limit = min;
    } else if (limit.compareTo(max) > 0) {
      l.w('limit greater than max: $limit, resetting to max');
      limit = max;
    }
    _limit = limit;
  }

  Limit({
    required this.min,
    required this.max,
    required this.defaultValue,
  }) : _limit = defaultValue;
}

class IntBasedLimit extends Limit<int> {
  IntBasedLimit({
    required super.min,
    required super.max,
    required super.defaultValue,
  });
  IntBasedLimit.standard() : this(min: 1, max: 120, defaultValue: 10);
}

abstract class PaginatorBase<R extends res.ResponseBase, O extends Comparable,
    L extends Comparable> {
  final Offset<O> offset;
  final Limit<L> limit;

  bool wrappedBackward = false;
  bool wrappedForward = false;

  Future<R> _pageRequest({required c.Client client});
  Future<R> next({required c.Client client});
  Future<R> prev({required c.Client client});

  PaginatorBase({required this.offset, required this.limit});
}

abstract class SingleDirectionPaginatorBase<R extends res.ResponseBase>
    extends PaginatorBase<R, int, int> {
  abstract s.SingleDirectionPaginatorResponseMetadata metadata;

  @override
  Future<R> next({required c.Client client}) {
    if (!metadata.hasMore) {
      wrappedForward = true;
      offset.reset();
    } else {
      offset.offset = metadata.nextOffset!;
    }
    return _pageRequest(client: client);
  }

  @override
  Future<R> prev({required c.Client client}) {
    int newOffset = offset.offset - limit.limit;
    wrappedBackward = wrappedForward ? true : newOffset < offset.min;
    offset.offset = newOffset;
    return _pageRequest(client: client);
  }

  SingleDirectionPaginatorBase({
    required IntBasedNonWrappingOffset offset,
    required IntBasedLimit limit,
  }) : super(offset: offset, limit: limit);
}

class DailyPaginator extends PaginatorBase<res.BrowseResponse, DateTime, int> {
  static DateTime get now {
    DateTime current = DateTime.now();
    return DateTime(current.year, current.month, current.day);
  }

  @override
  a.Future<res.BrowseResponse> _pageRequest({required c.Client client}) {
    return req.DailyRequest(date: offset.offset, callback: (_) {})
        .send(client: client);
  }

  @override
  a.Future<res.BrowseResponse> next({required c.Client client}) {
    DateTime newOffset = offset.offset.add(Duration(days: limit.limit));
    wrappedForward = wrappedForward ? true : newOffset.isAfter(offset.max);
    offset.offset = newOffset;
    return _pageRequest(client: client);
  }

  @override
  a.Future<res.BrowseResponse> prev({required c.Client client}) {
    DateTime newOffset = offset.offset.subtract(Duration(days: limit.limit));
    wrappedBackward = wrappedBackward ? true : newOffset.isBefore(newOffset);
    offset.offset = newOffset;
    return _pageRequest(client: client);
  }

  DailyPaginator({
    required WrappingOffset<DateTime> super.offset,
    required super.limit,
  });
}

class PopularPaginator
    extends SingleDirectionPaginatorBase<res.BrowseResponse> {
  final String? _search;
  final s.TimeRange? _timeRange;

  @override
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  @override
  Future<res.BrowseResponse> _pageRequest({required c.Client client}) {
    return req.PopularRequest(
        offset: offset.offset,
        limit: limit.limit,
        search: _search,
        timeRange: _timeRange,
        callback: (s.SingleDirectionPaginatorResponseMetadata newMetadata) {
          metadata = newMetadata;
        }).send(client: client);
  }

  PopularPaginator({
    required super.offset,
    required super.limit,
    String? search,
    s.TimeRange? timeRange,
  })  : _search = search,
        _timeRange = timeRange;
}

class NewestPaginator extends SingleDirectionPaginatorBase<res.BrowseResponse> {
  final String? _search;

  @override
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  @override
  a.Future<res.BrowseResponse> _pageRequest({required c.Client client}) {
    return req.NewestRequest(
        offset: offset.offset,
        limit: limit.limit,
        search: _search,
        callback: (s.SingleDirectionPaginatorResponseMetadata newMetadata) {
          metadata = newMetadata;
        }).send(client: client);
  }

  NewestPaginator({
    required super.offset,
    required super.limit,
    String? search,
  }) : _search = search;
}

class TagsPaginator extends SingleDirectionPaginatorBase<res.BrowseResponse> {
  final String _tag;

  @override
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  @override
  a.Future<res.BrowseResponse> _pageRequest({required c.Client client}) {
    return req.TagsRequest(
        offset: offset.offset,
        limit: limit.limit,
        tag: _tag,
        callback: (s.SingleDirectionPaginatorResponseMetadata newMetadata) {
          metadata = newMetadata;
        }).send(client: client);
  }

  TagsPaginator({
    required super.offset,
    required super.limit,
    required String tag,
  }) : _tag = tag;
}

class ListTopicsPaginator
    extends SingleDirectionPaginatorBase<res.ListTopicsResponse> {
  @override
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  @override
  a.Future<res.ListTopicsResponse> _pageRequest({required c.Client client}) {
    return req.ListTopicsRequest(
      offset: offset.offset,
      limit: limit.limit,
      callback: (s.SingleDirectionPaginatorResponseMetadata newMetadata) {
        metadata = newMetadata;
      },
    ).send(client: client);
  }

  ListTopicsPaginator({
    required super.offset,
    required super.limit,
  });
}

class BrowseTopicPaginator
    extends SingleDirectionPaginatorBase<res.BrowseResponse> {
  final String _name;

  @override
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  @override
  a.Future<res.BrowseResponse> _pageRequest({required c.Client client}) {
    return req.BrowseTopicRequest(
      offset: offset.offset,
      limit: limit.limit,
      callback: (s.SingleDirectionPaginatorResponseMetadata newMetadata) {
        metadata = newMetadata;
      },
      name: _name,
    ).send(client: client);
  }

  BrowseTopicPaginator(
      {required super.offset, required super.limit, required String name})
      : _name = name;
}
