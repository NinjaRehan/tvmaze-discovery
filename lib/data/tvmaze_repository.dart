import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/load_status.dart';
import 'models.dart';

abstract class ShowRepository {
  Future<List<Show>> shows(int page);
  Future<List<Show>> search(String query);
  Future<Show> details(int id);
  Future<List<CastMember>> cast(int id);
  Future<List<Episode>> episodes(int id);
}

class TvMazeRepository implements ShowRepository {
  TvMazeRepository(this._client, {this.timeout = const Duration(seconds: 20)});
  final http.Client _client;
  final Duration timeout;

  Future<dynamic> _get(
    String path, {
    Map<String, String>? query,
    bool endOn404 = false,
  }) async {
    try {
      final response = await _client
          .get(Uri.https('api.tvmaze.com', path, query))
          .timeout(timeout);
      if (response.statusCode == 404 && endOn404) {
        return <dynamic>[];
      }
      if (response.statusCode == 429) {
        throw const AppFailure(
          'TVMaze is busy. Please wait a moment and retry.',
        );
      }
      if (response.statusCode == 404) {
        throw const AppFailure('This show is no longer available on TVMaze.');
      }
      if (response.statusCode != 200) {
        throw const AppFailure(
          'TVMaze is temporarily unavailable. Please retry.',
        );
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const AppFailure(
        'The request timed out. Check your connection and retry.',
      );
    } on http.ClientException {
      throw const AppFailure(
        'Unable to connect. Check your internet connection.',
      );
    } on FormatException {
      throw const AppFailure(
        'TVMaze returned an unreadable response. Please retry.',
      );
    }
  }

  Future<T> _decode<T>(
    Future<dynamic> request,
    T Function(dynamic) parse,
  ) async {
    final json = await request;
    try {
      return parse(json);
    } on TypeError {
      throw const AppFailure('TVMaze returned unexpected data. Please retry.');
    } on FormatException {
      throw const AppFailure('TVMaze returned unexpected data. Please retry.');
    }
  }

  @override
  Future<List<Show>> shows(int page) => _decode(
    _get('/shows', query: {'page': '$page'}, endOn404: true),
    (json) => (json as List)
        .map((item) => Show.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  @override
  Future<List<Show>> search(String query) => _decode(
    _get('/search/shows', query: {'q': query.trim()}),
    (json) => (json as List)
        .map(
          (item) => Show.fromJson(
            (item as Map<String, dynamic>)['show'] as Map<String, dynamic>,
          ),
        )
        .toList(),
  );

  @override
  Future<Show> details(int id) => _decode(
    _get('/shows/$id'),
    (json) => Show.fromJson(json as Map<String, dynamic>),
  );

  @override
  Future<List<CastMember>> cast(int id) => _decode(
    _get('/shows/$id/cast'),
    (json) => (json as List)
        .map((item) => CastMember.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  @override
  Future<List<Episode>> episodes(int id) => _decode(
    _get('/shows/$id/episodes'),
    (json) => (json as List)
        .map((item) => Episode.fromJson(item as Map<String, dynamic>))
        .toList(),
  );
}
