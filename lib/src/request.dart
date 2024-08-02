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

Duration _pow2Duration(int index) {
  return Duration(seconds: math.pow(2, index).toInt());
}

const String baseAPIPath = 'https://www.deviantart.com/api/v1/oauth2';

String _buildPath({required List<String> parts}) {
  return '$baseAPIPath${parts.join()}';
}

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

class NullCallbackArgs extends s.ResponseCallbackArgs {}

class MaxAccessTokenResetRetriesExceededException implements Exception {
  final String message;

  const MaxAccessTokenResetRetriesExceededException([this.message = '']);

  @override
  String toString() => 'MaxAccessTokenResetRetriesExceededException: $message';
}

abstract class RequestBase<R extends res.ResponseBase,
    T extends s.ResponseCallbackArgs> {
  final void Function(T) callback;
  a.Future<R> send({required c.Client client});
  Map<String, String> get _params;

  RequestBase({required this.callback});
}

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

  @override
  Map<String, String> get _params => {'date': '$year-$month-$day'};

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

  DailyRequest({
    required this.date,
    required super.callback,
  });
}

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

  _OffsetLimitPaginatorRequest({
    required int offset,
    required int limit,
    required super.callback,
  })  : _offset = offset,
        _limit = limit;
}

class PopularRequest extends _OffsetLimitPaginatorRequest<res.BrowseResponse,
    s.SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  final String? _search;
  final s.TimeRange? _timeRange;

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

  PopularRequest(
      {required super.offset,
      required super.limit,
      String? search,
      s.TimeRange? timeRange,
      required super.callback})
      : _search = search,
        _timeRange = timeRange;
}

class NewestRequest extends _OffsetLimitPaginatorRequest<res.BrowseResponse,
    s.SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  final String? _search;

  @override
  List<Object?> get props => super.props..addAll([_search]);

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params {
    Map<String, String> offsetLimitParams = super._params;

    return _search == null ? offsetLimitParams : offsetLimitParams
      ..addAll({
        'q': _search!,
      });
  }

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

  NewestRequest(
      {required super.offset,
      required super.limit,
      String? search,
      required super.callback})
      : _search = search;
}

class TagsRequest extends _OffsetLimitPaginatorRequest<res.BrowseResponse,
    s.SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  final String _tag;

  @override
  List<Object?> get props => super.props..addAll([_tag]);

  @override
  Map<String, String> get _params => super._params
    ..addAll({
      'tag': _tag,
    });

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

  TagsRequest(
      {required super.offset,
      required super.limit,
      required String tag,
      required super.callback})
      : _tag = tag;
}

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

  MoreLikeThisRequest({required String seed, required super.callback})
      : _seed = seed;
}

class TagSearchRequest
    extends RequestBase<res.TagSearchResponse, NullCallbackArgs>
    with eq.EquatableMixin {
  final String _tag;

  @override
  List<Object> get props => [_tag];

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params => {
        'tag_name': _tag,
      };

  @override
  a.Future<res.TagSearchResponse> send({required c.Client client}) async {
    http.Response resp = await _get(
        path: _buildPath(parts: [browsePart, tagsPart, searchPart]),
        client: client,
        params: _params);
    callback(NullCallbackArgs());
    return res.TagSearchResponse.fromJSON(
        decoded: convert.json.decode(resp.body)['results']);
  }

  TagSearchRequest({
    required String tag,
    required super.callback,
  }) : _tag = tag;
}

class TopTopicsRequest
    extends RequestBase<res.ListTopicsResponse, NullCallbackArgs>
    with eq.EquatableMixin {
  @override
  List<Object> get props => [];

  @override
  bool get stringify => true;

  @override
  Map<String, String> get _params => {};

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

  TopTopicsRequest({required super.callback});
}

class ListTopicsRequest extends _OffsetLimitPaginatorRequest<
    res.ListTopicsResponse,
    s.SingleDirectionPaginatorResponseMetadata> with eq.EquatableMixin {
  @override
  bool get stringify => true;

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

  ListTopicsRequest({
    required super.offset,
    required super.limit,
    required super.callback,
  });
}

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

  BrowseTopicRequest({
    required super.offset,
    required super.limit,
    required super.callback,
    required String name,
  }) : _name = name;
}
