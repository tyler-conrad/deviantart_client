import 'dart:io' as io;
import 'dart:convert' as convert;

import 'package:http/http.dart' as http;

import 'shared.dart' as s;
import 'response.dart' as res;
import 'request.dart' as req;
import 'paginator.dart' as p;

final DateTime earliestDateSupportedByDailyPaginator = DateTime(2010, 1, 1);

class Client {
  String accessToken;

  Future<R> _next<R extends res.ResponseBase, O extends Comparable,
      L extends Comparable, P extends p.PaginatorBase<R, O, L>>(P paginator) {
    return paginator.next(client: this);
  }

  Future<R> _previous<R extends res.ResponseBase, O extends Comparable,
      L extends Comparable, P extends p.PaginatorBase<R, O, L>>(P paginator) {
    return paginator.prev(client: this);
  }

  Future<R> _send<R extends res.ResponseBase, T extends s.ResponseCallbackArgs,
      U extends req.RequestBase<R, T>>({required U request}) {
    return request.send(client: this);
  }

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

  static p.NewestPaginator newestPaginator(
      {p.IntBasedNonWrappingOffset? offset,
      p.IntBasedLimit? limit,
      String? search}) {
    return p.NewestPaginator(
        offset: offset ?? p.IntBasedNonWrappingOffset.standard(),
        limit: p.IntBasedLimit.standard(),
        search: search);
  }

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

  static p.ListTopicsPaginator topicsListPaginator({
    p.IntBasedNonWrappingOffset? offset,
    p.IntBasedLimit? limit,
  }) {
    return p.ListTopicsPaginator(
      offset: offset ?? p.IntBasedNonWrappingOffset.standard(),
      limit: limit ?? p.IntBasedLimit(min: 1, max: 10, defaultValue: 10),
    );
  }

  static p.BrowseTopicPaginator browseTopicPaginator(
      {p.IntBasedNonWrappingOffset? offset,
      p.IntBasedLimit? limit,
      required String topicName}) {
    return p.BrowseTopicPaginator(
        offset: offset ?? p.IntBasedNonWrappingOffset.standard(),
        limit: limit ?? p.IntBasedLimit(min: 1, max: 24, defaultValue: 10),
        name: topicName);
  }

  static req.MoreLikeThisRequest moreLikeThis({required String seed}) {
    return req.MoreLikeThisRequest(seed: seed, callback: (_) {});
  }

  static req.TagSearchRequest tagSearch({required String tag}) {
    return req.TagSearchRequest(tag: tag, callback: (_) {});
  }

  static req.TopTopicsRequest topTopics() {
    return req.TopTopicsRequest(callback: (_) {});
  }

  Client({required this.accessToken});
}

class _ClientCredentialError extends Error {
  final String message;

  _ClientCredentialError([this.message = '']);

  @override
  String toString() => 'ClientCredentialError: $message';
}

class ClientBuilder {
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

  static Future<Client> build() async {
    String accessToken = await _accessToken();
    return Client(accessToken: accessToken);
  }

  static Future<Client> resetAccessToken(Client client) async {
    String accessToken = await _accessToken();
    return client..accessToken = accessToken;
  }
}
