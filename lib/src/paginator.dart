import 'dart:async' as a;

import 'shared.dart' as s;
import 'logger.dart' show l;
import 'response.dart' as res;
import 'request.dart' as req;
import 'client.dart' as c;

/// An abstract class representing an offset for pagination.
///
/// This class provides functionality for managing an offset value within a
/// specified range. It allows setting and getting the offset value, as well as
/// resetting it to a default value. The offset value must be of a type that
/// extends the [Comparable] class.
///
/// Subclasses of this class should implement the [offset] setter to enforce any
/// additional constraints or validations.
abstract class Offset<T extends Comparable> {
  final T min;
  final T max;
  final T defaultValue;

  T _offset;
  T get offset => _offset;
  set offset(T offset);

  /// Resets the offset value to the default value.
  void reset() => offset = defaultValue;

  /// Creates a new instance of the [Offset] class.
  ///
  /// [min] is the minimum allowed offset value. [max] is the maximum allowed
  /// offset value. [defaultValue] is the default offset value.
  Offset({
    required this.min,
    required this.max,
    required this.defaultValue,
  }) : _offset = defaultValue;
}

/// A class representing an offset that wraps around a minimum and maximum
/// value.
///
/// This class extends the [Offset] class and provides additional logic to
/// ensure that the offset value stays within the specified minimum and maximum
/// range. If an attempt is made to set the offset value outside of this range,
/// it will be automatically adjusted to the nearest boundary value.
class WrappingOffset<T extends Comparable> extends Offset<T> {
  @override
  set offset(T offset) {
    if (offset.compareTo(min) < 0) {
      l.w('Attempted to set Offset.offset to a value less than Offset.min: $offset, setting to Offset.min');
      offset = min;
    } else if (offset.compareTo(max) > 0) {
      l.w('Attempted to set Offset.offset to a value greater than Offset.max: $offset, setting to Offset.max');
      offset = max;
    }
    _offset = offset;
  }

  /// WrappingOffset class represents the offset values for a paginator.
  ///
  /// [min] is the minimum value of the offset. [max] is the maximum value of
  /// the offset. [defaultValue] is the default value of the offset.
  WrappingOffset({
    required super.min,
    required super.max,
    required super.defaultValue,
  });
}

/// A non-wrapping offset that extends the Offset class.
///
/// This class ensures that the offset value is within the specified range
/// defined by the minimum and maximum values. If an attempt is made to set
/// the offset value outside of this range, it will be automatically clamped
/// to the nearest valid value.
///
/// The generic type parameter `T` must be a subtype of `Comparable`.
class _NonWrappingOffset<T extends Comparable> extends Offset<T> {
  /// Sets the offset value.
  ///
  /// If the specified offset is less than the minimum value, it will be
  /// clamped to the minimum value. If the offset is greater than the maximum
  /// value, it will be clamped to the maximum value.
  ///
  /// If the offset is within the valid range, it will be set as the new offset
  /// value.
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

  /// Creates a non-wrapping offset.
  ///
  /// It represents an offset that does not wrap around when it reaches the
  /// [min] is the minimum value of the offset. [max] is the maximum value of
  /// the offset. [defaultValue] is the default value of the offset.
  _NonWrappingOffset({
    required super.min,
    required super.max,
    required super.defaultValue,
  });
}

/// A class representing an integer-based non-wrapping offset.
class IntBasedNonWrappingOffset extends _NonWrappingOffset<int> {
  /// Creates a new instance of [IntBasedNonWrappingOffset].
  ///
  /// [min] is the minimum value of the offset. [max] is the maximum value of
  /// the offset. [defaultValue] is the default value of the offset.
  IntBasedNonWrappingOffset({
    required super.min,
    required super.max,
    required super.defaultValue,
  });

  /// Creates a new instance of [IntBasedNonWrappingOffset] with standard values.
  IntBasedNonWrappingOffset.standard()
      : this(min: 0, max: 50000, defaultValue: 0);
}

/// A class representing a limit for pagination.
///
/// The [Limit] class is used to define a limit for pagination. It ensures that
/// the limit value falls within the specified range of minimum and maximum
/// values. If the provided limit is less than the minimum value, it will be
/// automatically set to the minimum value. If the provided limit is greater
/// than the maximum value, it will be automatically set to the maximum value.
class Limit<T extends Comparable> {
  /// [min] value allowed for the limit.
  final T min;

  /// [max] value allowed for the limit.
  final T max;

  /// [defaultValue] for the limit.
  final T defaultValue;

  T _limit;

  /// The current value of the [limit].
  T get limit => _limit;

  /// Sets the value of the [limit].
  ///
  /// If the provided [limit] is less than the [min], it will be
  /// automatically set to [min]. If the provided [limit] is greater
  /// than [max], it will be automatically set to the [max] value.
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

  /// Creates a new instance of the [Limit] class.
  ///
  /// [min] is the minimum allowed limit value. [max] is the maximum allowed.
  /// [defaultValue] is the default limit value.
  Limit({
    required this.min,
    required this.max,
    required this.defaultValue,
  }) : _limit = defaultValue;
}

/// A class representing an integer-based limit.
///
/// This class extends the [Limit] class and provides a standard implementation
/// for integer-based limits.
class IntBasedLimit extends Limit<int> {
  /// Creates a new instance of [IntBasedLimit].
  IntBasedLimit({
    required super.min,
    required super.max,
    required super.defaultValue,
  });

  /// Creates a new instance of [IntBasedLimit] with standard values.
  IntBasedLimit.standard() : this(min: 1, max: 120, defaultValue: 10);
}

/// An abstract class representing a paginator.
///
/// A paginator is used to paginate through a collection of items. It provides
/// methods to move to the next or previous page of items. The paginator keeps
/// track of the current offset and limit values, as well as whether the
/// pagination has wrapped around the collection.
abstract class PaginatorBase<R extends res.ResponseBase, O extends Comparable,
    L extends Comparable> {
  final Offset<O> offset;
  final Limit<L> limit;

  bool wrappedBackward = false;
  bool wrappedForward = false;

  /// Makes a paginated request using the provided [client].
  Future<R> _pageRequest({required c.Client client});

  /// Fetches the next page of results.
  ///
  /// Used to retrieve the next page of results from the paginator.
  Future<R> next({required c.Client client});

  /// Fetches the previous page of results.
  ///
  /// Used to retrieve the previous page of results from the paginator.
  Future<R> prev({required c.Client client});

  /// Default constructor for the [PaginatorBase] class.
  PaginatorBase({required this.offset, required this.limit});
}

/// Base class for single direction paginators.
///
/// This class extends the [PaginatorBase] class and provides common functionality
/// for paginators that can only navigate in a single direction.
///
/// Subclasses of this class must implement the [metadata] field and override
/// the [next] and [prev] methods.
abstract class SingleDirectionPaginatorBase<R extends res.ResponseBase>
    extends PaginatorBase<R, int, int> {
  /// The metadata associated with the paginator response.
  ///
  /// Subclasses must provide an implementation for this field.
  abstract s.SingleDirectionPaginatorResponseMetadata metadata;

  /// Retrieves the next page of results.
  ///
  /// If there are no more pages to retrieve, the [wrappedForward] flag is set to true
  /// and the [offset] is reset. Otherwise, the [offset] is updated to the next offset
  /// specified in the [metadata].
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

  /// Retrieves the previous page of results.
  ///
  /// The [offset] is updated to the previous offset based on the current offset
  /// and the [limit]. The [wrappedBackward] flag is set to true if the [offset]
  /// is less than the minimum offset.
  @override
  Future<R> prev({required c.Client client}) {
    int newOffset = offset.offset - limit.limit;
    wrappedBackward = wrappedForward ? true : newOffset < offset.min;
    offset.offset = newOffset;
    return _pageRequest(client: client);
  }

  /// Creates a new instance of the [SingleDirectionPaginatorBase] class.
  ///
  /// The [offset] and [limit] parameters are required and specify the initial
  /// offset and limit for the paginator.
  SingleDirectionPaginatorBase({
    required IntBasedNonWrappingOffset offset,
    required IntBasedLimit limit,
  }) : super(offset: offset, limit: limit);
}

/// A paginator class for browsing popular items.
///
/// This class extends the [SingleDirectionPaginatorBase] class and provides
/// pagination functionality for browsing popular items. It handles making page
/// requests and updating the metadata accordingly.
class PopularPaginator
    extends SingleDirectionPaginatorBase<res.BrowseResponse> {
  final String? _search;
  final s.TimeRange? _timeRange;

  /// The metadata for the paginator response.
  @override
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  /// Makes a page request to retrieve the browse response.
  ///
  /// This method is called internally to make a page request and retrieve the
  /// browse response. It takes a required [client] parameter of type [c.Client]
  /// to send the request.
  /// [res.BrowseResponse].
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

  /// Creates a new instance of the [PopularPaginator] class.
  /// - [offset] of the paginator.
  /// - [limit] of items per page.
  /// - [search] query for filtering items (optional).
  /// - [timeRange] for filtering items (optional).
  PopularPaginator({
    required super.offset,
    required super.limit,
    String? search,
    s.TimeRange? timeRange,
  })  : _search = search,
        _timeRange = timeRange;
}

/// A paginator for browsing the newest items.
///
/// This paginator extends the [SingleDirectionPaginatorBase] class and provides
/// functionality for paginating through the newest items. It handles the
/// pagination logic and makes requests to retrieve the next page of items.
class NewestPaginator extends SingleDirectionPaginatorBase<res.BrowseResponse> {
  final String? _search;

  /// The metadata for the paginator response.
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  /// Makes a page request to retrieve the next page of items.
  ///
  /// This method is called internally to make a request to retrieve the next
  /// page of items. It takes a [client] parameter of type [c.Client] to make
  /// the HTTP request. It returns a [Future] that resolves to a
  /// [BrowseResponse] object representing the response of the request.
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

  /// Creates a new instance of the [NewestPaginator] class.
  ///
  /// This constructor initializes a new instance of the [NewestPaginator]
  /// class. It takes the [offset] and [limit] parameters, which are inherited
  /// from the [SingleDirectionPaginatorBase] class. It also takes an optional
  /// [search] parameter of type [String] to specify a search query.
  NewestPaginator({
    required super.offset,
    required super.limit,
    String? search,
  }) : _search = search;
}

/// A paginator for browsing tags in the DeviantArt client.
class TagsPaginator extends SingleDirectionPaginatorBase<res.BrowseResponse> {
  final String _tag;

  /// The metadata for the paginator response.
  ///
  /// This metadata contains information about the current state of the
  /// paginator, such as the number of items per page and the total number of
  /// items.
  @override
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  /// Sends a page request to retrieve the browse response.
  ///
  /// This method is called internally to send a request to the server and
  /// retrieve the browse response for the current page.
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

  /// Creates a new instance of the [TagsPaginator] class.
  ///
  /// [offset] is inherited from the [SingleDirectionPaginatorBase] and
  /// specifies the starting offset for the paginator. [limit] is inherited from
  /// the [SingleDirectionPaginatorBase] and specifies the maximum number of
  /// items per page. [tag] is a required and specifies the tag to browse.
  TagsPaginator({
    required super.offset,
    required super.limit,
    required String tag,
  }) : _tag = tag;
}

/// A paginator for listing topics.
///
/// This paginator extends the [SingleDirectionPaginatorBase] class and provides
/// the ability to paginate through a list of topics.
class ListTopicsPaginator
    extends SingleDirectionPaginatorBase<res.ListTopicsResponse> {
  /// The metadata for the paginator response.
  ///
  /// This metadata contains information about the response, such as the total
  /// number of topics and the current page.
  @override
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  /// Sends a request to retrieve the next page of topics.
  ///
  /// This method is called internally by the paginator to fetch the next page
  /// of topics.
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

  /// Creates a new instance of the [ListTopicsPaginator] class.
  ///
  /// [offset] is the starting offset for pagination. [limit] is the maximum
  /// number of topics to retrieve per page.
  ListTopicsPaginator({
    required super.offset,
    required super.limit,
  });
}

/// A paginator for browsing daily items.
///
/// This paginator provides methods for navigating to the next and previous
/// pages.
class DailyPaginator extends PaginatorBase<res.BrowseResponse, DateTime, int> {
  /// Returns the current date and time.
  static DateTime get now {
    DateTime current = DateTime.now();
    return DateTime(current.year, current.month, current.day);
  }

  /// Sends a page request to retrieve the browse response.
  ///
  /// This method is called internally to send a page request to the server and
  /// retrieve the browse response. It takes a [client] parameter which is an
  /// instance of the HTTP client used to send the request.
  @override
  a.Future<res.BrowseResponse> _pageRequest({required c.Client client}) {
    return req.DailyRequest(date: offset.offset, callback: (_) {})
        .send(client: client);
  }

  /// Retrieves the next page of items.
  ///
  /// This method is used to navigate to the next page of items. It takes a
  /// [client] parameter which is an instance of the HTTP client used to send
  /// the request.
  @override
  a.Future<res.BrowseResponse> next({required c.Client client}) {
    DateTime newOffset = offset.offset.add(Duration(days: limit.limit));
    wrappedForward = wrappedForward ? true : newOffset.isAfter(offset.max);
    offset.offset = newOffset;
    return _pageRequest(client: client);
  }

  /// Retrieves the previous page of items.
  ///
  /// This method is used to navigate to the previous page of items. It takes a
  /// [client] parameter which is an instance of the HTTP client used to send
  /// the request.
  @override
  a.Future<res.BrowseResponse> prev({required c.Client client}) {
    DateTime newOffset = offset.offset.subtract(Duration(days: limit.limit));
    wrappedBackward = wrappedBackward ? true : newOffset.isBefore(newOffset);
    offset.offset = newOffset;
    return _pageRequest(client: client);
  }

  /// Creates a new instance of [DailyPaginator].
  ///
  /// [offset] is an instance of [WrappingOffset] representing the current
  /// offset. [limit] is an instance of [int] representing the limit of items
  /// per page.
  DailyPaginator({
    required WrappingOffset<DateTime> super.offset,
    required super.limit,
  });
}

/// A paginator for browsing topics.
///
/// This paginator extends the [SingleDirectionPaginatorBase] class and provides
/// functionality for browsing topics. It paginates through [res.BrowseResponse]
/// objects.
class BrowseTopicPaginator
    extends SingleDirectionPaginatorBase<res.BrowseResponse> {
  final String _name;

  /// The metadata for the paginator response.
  ///
  /// This metadata is used to store information about the response, such as the
  /// total number of items and the current page.
  @override
  s.SingleDirectionPaginatorResponseMetadata metadata =
      s.SingleDirectionPaginatorResponseMetadata.standard();

  /// Sends a page request to retrieve the next page of results.
  ///
  /// This method is called internally by the paginator to retrieve the next
  /// page of results. It returns a [Future] that resolves to a
  /// [res.BrowseResponse] object. The [client] parameter is the HTTP client
  /// used to send the request.
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

  /// Creates a new instance of the [BrowseTopicPaginator] class.
  ///
  /// [offset] is the starting offset for pagination. [limit] is the maximum
  /// number of items per page. [name] is the name of the topic to browse.
  BrowseTopicPaginator(
      {required super.offset, required super.limit, required String name})
      : _name = name;
}
