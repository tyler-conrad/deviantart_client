import 'dart:math' as math;
import 'dart:async' as a;
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart' as eq;

import 'shared.dart' as s;
import 'response.dart' as res;
import 'client.dart' as c;

const String apiVersion = '20210526';

const String browsePart = '/browse';
const String dailyPart = '/dailydeviations';
const String popularPart = '/popular';
const String moreLikeThisPart = '/morelikethis';
const String previewPart = '/preview';
const String newestPart = '/newest';
const String tagsPart = '/tags';
const String searchPart = '/search';
const String topicsPart = '/topics';
const String topicPart = '/topic';
const String topTopicsPart = '/toptopics';

/// Calculates the duration based on a power of 2.
///
/// Allows for exponential backoff.
Duration _pow2Duration(int index) {
  return Duration(seconds: math.pow(2, index).toInt());
}

const String baseAPIPath = 'https://www.deviantart.com/api/v1/oauth2';

/// Builds a path by joining the given list of [part]s with the base API path.
String _buildPath({required List<String> parts}) {
  return '$baseAPIPath${parts.join()}';
}

/// Sends a GET request to the specified [path] using the provided [client].
///
/// Optional [params] and [headers] can be provided to include additional query parameters and headers in the request.
/// The [accessTokenResetRetries] parameter specifies the number of times the access token can be reset before throwing a [MaxAccessTokenResetRetriesExceededException].
///
/// Returns a [Future] that resolves to an [http.Response] object.
/// If the response status code is 401 (Unauthorized), the request will be retried with a new access token.
/// The retry logic will be executed up to 3 times.
a.Future<http.Response> _get(
    {required String path,
    required c.Client client,
    Map<String, String>? params,
    Map<String, String>? headers,
    int accessTokenResetRetries = 0}) async {
  if (accessTokenResetRetries > 3) {
    throw MaxAccessTokenResetRetriesExceededException(
        'retries: $accessTokenResetRetries');
  }
  Map<String, String> paramsWithAccessToken = {
    'access_token': client.accessToken,
    'mature_content': 'false',
  };
  paramsWithAccessToken.addAll(params ?? {});

  Map<String, String> headersWithApiVersion = {
    'dA-minor-version': apiVersion,
  };
  headersWithApiVersion.addAll(headers ?? {});

  http.Response resp = await http.get(
      Uri.parse(path).replace(queryParameters: paramsWithAccessToken),
      headers: headersWithApiVersion);
  if (resp.statusCode == 401) {
    await Future.delayed(_pow2Duration(accessTokenResetRetries));
    c.Client apiWithNewAccessToken =
        await c.ClientBuilder.resetAccessToken(client);
    resp = await _get(
      path: path,
      client: apiWithNewAccessToken,
      params: params,
      headers: headers,
      accessTokenResetRetries: accessTokenResetRetries + 1,
    );
  }
  return resp;
}

/// Represents a noop callback that does not take any arguments.
class NullCallbackArgs extends s.ResponseCallbackArgs {}

/// Exception thrown when the maximum number of retries for resetting the access
/// token is exceeded.
///
/// This exception is thrown when the client has attempted to reset the access
/// token multiple times, but the maximum number of retries has been reached.
class MaxAccessTokenResetRetriesExceededException implements Exception {
  final String message;

  const MaxAccessTokenResetRetriesExceededException([this.message = '']);

  @override
  String toString() => 'MaxAccessTokenResetRetriesExceededException: $message';
}

/// An abstract base class for requests.
///
/// This class represents a base class for requests in the DeviantArt client
/// library. It provides common functionality and properties that are shared by
/// all requests. Subclasses of this class should implement the `send` method
/// and provide the necessary implementation details specific to each request.
///
/// The type parameters [R] and [T] represent the response type and callback
/// arguments type respectively. The [R] type must extend `ResponseBase` and the
/// [T] type must extend [s.ResponseCallbackArgs].
///
/// The [callback] parameter is a function that will be called when the request
/// is completed. It takes an argument of type [T], which represents the
/// callback arguments.
abstract class RequestBase<R extends res.ResponseBase,
    T extends s.ResponseCallbackArgs> {
  /// A callback function that takes a parameter of type [T] representing the
  /// callback arguments type.
  final void Function(T) callback;

  /// Base class for constructor for requests.
  ///
  /// This class is used as a blueprint for creating request objects. It
  /// contains a required [callback] parameter that represents the callback
  /// function to be executed when the request is completed.
  RequestBase({required this.callback});

  /// Sends a request using the specified [client].
  a.Future<R> send({required c.Client client});

  Map<String, String> get _params;
}

/// Represents a request to retrieve daily data from the server.
class DailyRequest extends RequestBase<res.BrowseResponse, NullCallbackArgs>
    with eq.EquatableMixin {
  final DateTime date;

  @override
  List<Object> get props => ['$date'];

  @override
  bool get stringify => true;

  String get year => '${date.year}'.padLeft(4, '0');
  String get month => '${date.month}'.padLeft(2, '0');
  String get day => '${date.day}'.padLeft(2, '0');

  /// Returns a map that contains a single entry with the key 'date' and the
  /// value formatted as '$year-$month-$day'.
  @override
  Map<String, String> get _params => {'date': '$year-$month-$day'};

  /// Sends a request to browse and retrieve the response.
  ///
  /// It requires a [client] parameter to make the HTTP request.
  @override
  a.Future<res.BrowseResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
      path: _buildPath(parts: [browsePart, dailyPart]),
      client: client,
      params: _params,
    );
    callback(NullCallbackArgs());
    return res.BrowseResponse.fromJSON(
      decoded: convert.json.decode(resp.body)['results'],
    );
  }

  /// Creates a daily request.
  ///
  /// This class is used to make a request for a specific date. [date] specifies
  /// the date for which the request is made. [callback] is the callback
  /// function to be executed when the request is completed.
  DailyRequest({
    required this.date,
    required super.callback,
  });
}

/// An abstract class representing a request for offset and limit pagination.
///
/// This class is used as a base class for requests that require pagination
/// using offset and limit parameters.
abstract class _OffsetLimitPaginatorRequest<R extends res.ResponseBase,
        T extends s.ResponseCallbackArgs> extends RequestBase<R, T>
    with eq.EquatableMixin {
  final int _offset;
  final int _limit;

  @override
  List<Object?> get props => [_offset, _limit];

  @override
  Map<String, String> get _params => {
        'offset': '$_offset',
        'limit': '$_limit',
      };

  /// Represents a request for an offset-limit paginator.
  ///
  /// This request is used to specify the offset and limit for paginated data
  /// retrieval. [offset] represents the starting index of the data to retrieve,
  /// while the [limit] represents the maximum number of items to retrieve. The
  /// [callback] parameter is a required callback function that will be called
  /// when the request is executed.
  _OffsetLimitPaginatorRequest({
    required int offset,
    required int limit,
    required super.callback,
  })  : _offset = offset,
        _limit = limit;
}

/// A class representing a popular request for browsing deviantart items.
///
/// This class extends the [_OffsetLimitPaginatorRequest] class.
class PopularRequest extends _OffsetLimitPaginatorRequest<res.BrowseResponse,
    s.SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  /// The search query for the request.
  final String? _search;

  /// The time range for the request.
  final s.TimeRange? _timeRange;

  /// Converts a [s.TimeRange] enum value to its corresponding string
  /// representation.
  static String _stringFromTimeRange(s.TimeRange timeRange) {
    switch (timeRange) {
      case s.TimeRange.now:
        return 'now';
      case s.TimeRange.oneWeek:
        return '1week';
      case s.TimeRange.oneMonth:
        return '1month';
      case s.TimeRange.allTime:
        return 'alltime';
    }
  }

  @override
  List<Object?> get props => super.props..addAll([_search, _timeRange]);

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params {
    Map<String, String> params = {
      'offset': '$_offset',
      'limit': '$_limit',
    };
    if (_search != null) {
      params['q'] = _search;
    }
    if (_timeRange != null) {
      params['timerange'] = _stringFromTimeRange(_timeRange);
    }
    return params;
  }

  /// Sends a browse request using the provided [client].
  ///
  /// This method sends a browse request to the server and returns a [Future]
  /// that resolves to a [res.BrowseResponse] object. The [client] parameter is
  /// required and should be an instance of [c.Client] from the [http] package.
  @override
  a.Future<res.BrowseResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
      path: _buildPath(parts: [browsePart, popularPart]),
      client: client,
      params: _params,
    );
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
      s.SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded),
    );
    return res.BrowseResponse.fromJSON(decoded: decoded['results']);
  }

  /// Creates a new instance of [PopularRequest].
  ///
  /// [offset] and [limit] are required and specify the pagination offset and
  /// limit for the request. [search] is optional and represents the search
  /// query for the request. [timeRange] is optional and specifies the time
  /// range for the request. [callback] is required and represents the callback
  /// function to be called after the request is sent.
  PopularRequest(
      {required super.offset,
      required super.limit,
      String? search,
      s.TimeRange? timeRange,
      required super.callback})
      : _search = search,
        _timeRange = timeRange;
}

/// Request to retrieve the newest items.
class NewestRequest extends _OffsetLimitPaginatorRequest<res.BrowseResponse,
    s.SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  final String? _search;

  @override
  List<Object?> get props => super.props..addAll([_search]);

  @override
  bool get stringify => true;

  /// Returns the parameters for the request.
  @override
  Map<String, String> get _params {
    Map<String, String> offsetLimitParams = super._params;

    return _search == null ? offsetLimitParams : offsetLimitParams
      ..addAll({
        'q': _search!,
      });
  }

  /// Sends a request to browse the newest items.
  ///
  /// This method sends a request to browse the newest items using the provided
  /// [client].
  @override
  a.Future<res.BrowseResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, newestPart]),
        client: client,
        params: _params);
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
      s.SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded),
    );
    return res.BrowseResponse.fromJSON(decoded: decoded['results']);
  }

  /// Creates a request for retrieving the newest items.
  ///
  /// [offset] and [limit] are required and specify the starting offset and the
  /// maximum number of items to retrieve. [search] is optional and allows
  /// filtering the items based on a search query. [callback] is required and
  /// specifies the callback function to be called when the request is
  /// completed.
  NewestRequest(
      {required super.offset,
      required super.limit,
      String? search,
      required super.callback})
      : _search = search;
}

/// Request to browse tags.
///
/// This request is used to retrieve browse response for a specific tag.
class TagsRequest extends _OffsetLimitPaginatorRequest<res.BrowseResponse,
    s.SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  /// The tag to browse.
  final String _tag;

  /// Returns a list of objects that are used to determine equality of this
  /// request.
  @override
  List<Object?> get props => super.props..addAll([_tag]);

  /// Returns a map of query parameters for the request.
  @override
  Map<String, String> get _params => super._params
    ..addAll({
      'tag': _tag,
    });

  /// Sends the request and returns a [res.BrowseResponse].
  ///
  /// The [client] parameter is required to send the request.
  @override
  a.Future<res.BrowseResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, tagsPart]),
        client: client,
        params: _params);
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
      s.SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded),
    );
    return res.BrowseResponse.fromJSON(decoded: decoded['results']);
  }

  /// Creates a new instance of [TagsRequest].
  ///
  /// [offset] is the starting index of the browse request. [limit] is the
  /// maximum number of results to retrieve. The [tag] is the tag to browse. The
  /// [callback] is a function that will be called with the response metadata.
  TagsRequest(
      {required super.offset,
      required super.limit,
      required String tag,
      required super.callback})
      : _tag = tag;
}

/// Request to list topics.
class ListTopicsRequest extends _OffsetLimitPaginatorRequest<
    res.ListTopicsResponse,
    s.SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  @override
  bool get stringify => true;

  /// Sends a request to list topics.
  ///
  /// This method sends a request to list topics using the provided [client]. It
  /// returns a future that completes with a [res.ListTopicsResponse] object.
  ///
  /// The [client] parameter is required and represents the HTTP client to use
  /// for the request.
  @override
  a.Future<res.ListTopicsResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, topicsPart]),
        client: client,
        params: _params);
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
        s.SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded));
    return res.ListTopicsResponse.fromJSON(decoded: decoded['results']);
  }

  /// Create a request to list topics.
  ListTopicsRequest({
    required super.offset,
    required super.limit,
    required super.callback,
  });
}

/// Request to browse a specific topic.
class BrowseTopicRequest extends _OffsetLimitPaginatorRequest<
    res.BrowseResponse,
    s.SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  final String _name;

  @override
  List<Object?> get props => super.props..addAll([_name]);

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params => super._params..addAll({'topic': _name});

  /// Sends a request to browse and returns a future that resolves to a
  /// [res.BrowseResponse].
  ///
  /// The [client] parameter is required and represents the HTTP client used to
  /// send the request. This method performs an HTTP GET request to the
  /// specified path, with the necessary parameters. The response is then
  /// decoded from JSON and used to create a [res.BrowseResponse] object.
  /// Additionally, the [callback] function is called with the response
  /// metadata.
  @override
  a.Future<res.BrowseResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
      path: _buildPath(parts: [browsePart, topicPart]),
      client: client,
      params: _params,
    );
    Map<String, dynamic> decoded = convert.json.decode(resp.body);
    callback(
        s.SingleDirectionPaginatorResponseMetadata.fromJSON(decoded: decoded));
    return res.BrowseResponse.fromJSON(decoded: decoded['results']);
  }

  /// Request to browse a specific topic.
  ///
  /// The [offset] and [limit] parameters determine the range of items to be
  /// retrieved. The [callback] parameter is a function that will be called when
  /// the request is completed. The [name] parameter specifies the name of the
  /// topic to browse.
  BrowseTopicRequest({
    required super.offset,
    required super.limit,
    required super.callback,
    required String name,
  }) : _name = name;
}

/// Represents a request to retrieve more items similar to a given seed.
///
/// The [MoreLikeThisRequest] requires a seed, which is a string used to
/// identify the item for which similar items are requested. The [_params]
/// getter returns a map of query parameters that will be included in the
/// request URL. In this case, it includes the 'seed' parameter with the value
/// of [_seed].
class MoreLikeThisRequest
    extends RequestBase<res.MoreLikeThisResponse, NullCallbackArgs>
    with eq.EquatableMixin {
  final String _seed;

  @override
  List<Object> get props => [_seed];

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params => {'seed': _seed};

  /// Sends a equest to retrieve more like this response.
  ///
  /// The [client] parameter is required and represents the HTTP client to use
  /// for the request.
  @override
  a.Future<res.MoreLikeThisResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(
          parts: [
            browsePart,
            moreLikeThisPart,
            previewPart,
          ],
        ),
        client: client,
        params: _params);
    callback(NullCallbackArgs());
    return res.MoreLikeThisResponse.fromJSON(
      decoded: convert.json.decode(resp.body),
    );
  }

  /// Represents a request for retrieving similar items based on a seed.
  ///
  /// The [MoreLikeThisRequest] class is used to construct a request for
  /// retrieving items that are similar to a given seed. The seed is a string
  /// that serves as the basis for finding similar items.
  ///
  /// The [callback] parameter is a required callback function that will be
  /// invoked when the request is completed. It should accept the response data
  /// as a parameter.
  MoreLikeThisRequest({required String seed, required super.callback})
      : _seed = seed;
}

/// Represents a request to search for tags.
///
/// It is used to perform a tag search request and retrieve the corresponding
/// response.
class TagSearchRequest
    extends RequestBase<res.TagSearchResponse, NullCallbackArgs>
    with eq.EquatableMixin {
  final String _tag;

  @override
  List<Object> get props => [_tag];

  @override
  bool get stringify => true;

  /// Returns the parameters for the request.
  @override
  Map<String, String> get _params => {
        'tag_name': _tag,
      };

  /// Sends the request and returns the corresponding response.
  ///
  /// The [client] parameter is required and represents the HTTP client to use
  /// for the request.
  @override
  Future<res.TagSearchResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, tagsPart, searchPart]),
        client: client,
        params: _params);
    callback(NullCallbackArgs());
    return res.TagSearchResponse.fromJSON(
        decoded: convert.json.decode(resp.body)['results']);
  }

  /// Creates a new instance of [TagSearchRequest].
  ///
  /// [tag] is required and represents the tag to search for. [callback] is
  /// required and represents the callback function to be called after the
  /// request is sent.
  TagSearchRequest({
    required String tag,
    required super.callback,
  }) : _tag = tag;
}

/// Represents a request to retrieve the top topics.
///
/// This request is used to fetch the top topics from the server.
class TopTopicsRequest
    extends RequestBase<res.ListTopicsResponse, NullCallbackArgs>
    with eq.EquatableMixin {
  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;

  /// Returns the parameters for the request.
  @override
  Map<String, String> get _params => {};

  /// Sends the request to the server and returns the response.
  ///
  /// This method sends the request to the server using the provided [client] and
  /// returns the response as a [res.ListTopicsResponse] object.
  @override
  a.Future<res.ListTopicsResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, topTopicsPart]),
        client: client,
        params: _params);
    callback(NullCallbackArgs());
    return res.ListTopicsResponse.fromJSON(
      decoded: convert.json.decode(resp.body)['results'],
    );
  }

  /// Create a new instance of the [TopTopicsRequest] class.
  ///
  /// [callback] is the function to be called after the request is sent.
  TopTopicsRequest({required super.callback});
}
