import 'dart:io' as io;
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

import 'shared.dart' as s;
import 'response.dart' as res;
import 'request.dart' as req;
import 'paginator.dart' as p;

/// The earliest date supported by the daily paginator.
///
/// This value is set to January 1, 2010.
final DateTime earliestDateSupportedByDailyPaginator = DateTime(2010, 1, 1);

/// Client for interacting with the DeviantArt API.
class Client {
  /// The access token used for authentication.
  String accessToken;

  /// Creates a new instance of the [Client] class.
  ///
  /// The [accessToken] parameter is required and represents the access token
  /// used for authentication.
  Client({required this.accessToken});

  /// Retrieves the next page of results using the provided [paginator].
  ///
  /// [R] is the response type. [O] is the offset used by the paginator. [L] is
  /// the limit used by the paginator. [P] is the paginator.
  Future<R> _next<R extends res.ResponseBase, O extends Comparable,
      L extends Comparable, P extends p.PaginatorBase<R, O, L>>(P paginator) {
    return paginator.next(client: this);
  }

  /// Retrieves the previous page of results using the provided [paginator].
  ///
  /// [R] is the response type. [O] is the offset used by the paginator. [L] is
  /// the limit used by the paginator. [P] is paginator.
  Future<R> _previous<R extends res.ResponseBase, O extends Comparable,
      L extends Comparable, P extends p.PaginatorBase<R, O, L>>(P paginator) {
    return paginator.prev(client: this);
  }

  /// Sends a request using the provided [request].
  ///
  /// [R] is the response type. [T] is the response callback arguments. [U] is
  /// the request.
  Future<R> _send<R extends res.ResponseBase, T extends s.ResponseCallbackArgs,
      U extends req.RequestBase<R, T>>({required U request}) {
    return request.send(client: this);
  }

  /// Creates a [p.DailyPaginator] with the specified [offset] and [limit].
  ///
  /// [offset] is the wrapping offset for the paginator. [limit] is the limit
  /// for the paginator.
  static p.DailyPaginator dailyPaginator(
      {p.WrappingOffset<DateTime>? offset, p.Limit<int>? limit}) {
    return p.DailyPaginator(
        offset: offset ??
            p.WrappingOffset<DateTime>(
                min: earliestDateSupportedByDailyPaginator,
                max: p.DailyPaginator.now,
                defaultValue: p.DailyPaginator.now),
        limit: limit ?? p.IntBasedLimit(min: 1, max: 365, defaultValue: 1));
  }

  /// Creates a [p.PopularPaginator].
  ///
  /// [offset] is the non-wrapping offset for the paginator. [limit] is the
  /// limit for the paginator. [search] is the search query for the paginator.
  /// [timeRange] is the time range for the paginator.
  static p.PopularPaginator popularPaginator(
      {p.IntBasedNonWrappingOffset? offset,
      p.IntBasedLimit? limit,
      String? search,
      s.TimeRange? timeRange}) {
    return p.PopularPaginator(
        offset: offset ?? p.IntBasedNonWrappingOffset.standard(),
        limit: limit ?? p.IntBasedLimit.standard(),
        search: search,
        timeRange: timeRange);
  }

  /// Creates a [p.NewestPaginator].
  ///
  /// [offset] is the non-wrapping offset for the paginator. [limit] is the
  /// limit for the paginator. [search] is the search query for the paginator.
  static p.NewestPaginator newestPaginator(
      {p.IntBasedNonWrappingOffset? offset,
      p.IntBasedLimit? limit,
      String? search}) {
    return p.NewestPaginator(
        offset: offset ?? p.IntBasedNonWrappingOffset.standard(),
        limit: p.IntBasedLimit.standard(),
        search: search);
  }

  /// Creates a [p.TagsPaginator].
  ///
  /// [offset] is the non-wrapping offset for the paginator. [limit] is the
  /// limit for the paginator. [tag] is the tag for the paginator.
  static p.TagsPaginator tagsPaginator({
    p.IntBasedNonWrappingOffset? offset,
    p.IntBasedLimit? limit,
    required String tag,
  }) {
    return p.TagsPaginator(
        offset: offset ?? p.IntBasedNonWrappingOffset.standard(),
        limit: limit ?? p.IntBasedLimit(min: 1, max: 50, defaultValue: 10),
        tag: tag);
  }

  /// Creates a [p.ListTopicsPaginator] with the specified [offset] and [limit].
  ///
  /// [offset] is the non-wrapping offset for the paginator. [limit] is the
  /// limit for the paginator.
  static p.ListTopicsPaginator topicsListPaginator({
    p.IntBasedNonWrappingOffset? offset,
    p.IntBasedLimit? limit,
  }) {
    return p.ListTopicsPaginator(
      offset: offset ?? p.IntBasedNonWrappingOffset.standard(),
      limit: limit ?? p.IntBasedLimit(min: 1, max: 10, defaultValue: 10),
    );
  }

  /// Creates a [p.BrowseTopicPaginator].
  ///
  /// [offset] is the non-wrapping offset for the paginator. [limit] is the
  /// limit for the paginator. [topicName] is the name of the topic for the
  /// paginator.
  static p.BrowseTopicPaginator browseTopicPaginator(
      {p.IntBasedNonWrappingOffset? offset,
      p.IntBasedLimit? limit,
      required String topicName}) {
    return p.BrowseTopicPaginator(
        offset: offset ?? p.IntBasedNonWrappingOffset.standard(),
        limit: limit ?? p.IntBasedLimit(min: 1, max: 24, defaultValue: 10),
        name: topicName);
  }

  /// Creates a [req.MoreLikeThisRequest] with the specified [seed].
  static req.MoreLikeThisRequest moreLikeThis({required String seed}) {
    return req.MoreLikeThisRequest(seed: seed, callback: (_) {});
  }

  /// Creates a [req.TagSearchRequest] with the specified [tag].
  static req.TagSearchRequest tagSearch({required String tag}) {
    return req.TagSearchRequest(tag: tag, callback: (_) {});
  }

  /// Creates a [req.TopTopicsRequest].
  static req.TopTopicsRequest topTopics() {
    return req.TopTopicsRequest(callback: (_) {});
  }
}

/// Represents an error that occurs when there is an issue with the client
/// credentials.
class _ClientCredentialError extends Error {
  final String message;

  _ClientCredentialError([this.message = '']);

  @override
  String toString() => 'ClientCredentialError: $message';
}

/// A builder class for creating instances of the [Client] class.
class ClientBuilder {
  /// Retrieves the access token for making authenticated requests to the
  /// DeviantArt API.
  ///
  /// Throws [_ClientCredentialError] if the 'DA_CLIENT_ID' or
  /// 'DA_CLIENT_SECRET' environment variables are not set.
  static Future<String> _accessToken() async {
    http.Response resp = await http.post(
      Uri.parse('https://www.deviantart.com/oauth2/token'),
      body: {
        'client_id': io.Platform.environment['DA_CLIENT_ID'] ??
            (throw _ClientCredentialError(
              'DA_CLIENT_ID environment variable not set',
            )),
        'client_secret': io.Platform.environment['DA_CLIENT_SECRET'] ??
            (throw _ClientCredentialError(
              'DA_CLIENT_SECRET environment variable not set',
            )),
        'grant_type': 'client_credentials',
      },
    );
    return convert.json.decode(resp.body)['access_token'];
  }

  /// Builds a new instance of the [Client] class.
  ///
  /// This method retrieves the access token and uses it to create a new
  /// instance of the [Client] class. The access token is obtained
  /// asynchronously using the [_accessToken] method.
  static Future<Client> build() async {
    String accessToken = await _accessToken();
    return Client(accessToken: accessToken);
  }

  /// Resets the access token for the given [client].
  ///
  /// This method retrieves the access token using the [_accessToken] method and
  /// assigns it to the [client].
  static Future<Client> resetAccessToken(Client client) async {
    String accessToken = await _accessToken();
    return client..accessToken = accessToken;
  }
}
