import 'dart:convert';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tvmaze_discovery/core/load_status.dart';
import 'package:tvmaze_discovery/data/tvmaze_repository.dart';

void main() {
  test('slow requests produce a readable timeout failure', () async {
    final pending = Completer<http.Response>();
    final client = MockClient((_) => pending.future);
    addTearDown(client.close);
    await expectLater(
      TvMazeRepository(
        client,
        timeout: const Duration(milliseconds: 5),
      ).shows(0),
      throwsA(
        isA<AppFailure>().having(
          (error) => error.message,
          'message',
          contains('timed out'),
        ),
      ),
    );
  });
  test('page query is forwarded and missing metadata is safe', () async {
    final client = MockClient((request) async {
      expect(request.url.host, 'api.tvmaze.com');
      expect(request.url.path, '/shows');
      expect(request.url.queryParameters, {'page': '3'});
      return http.Response(
        jsonEncode([
          {'id': 1, 'name': 'A'},
        ]),
        200,
      );
    });
    addTearDown(client.close);
    final shows = await TvMazeRepository(client).shows(3);
    expect(shows.single.imageUrl, isNull);
    expect(shows.single.rating, isNull);
    expect(shows.single.genres, isEmpty);
  });
  test('index 404 is end of collection', () async {
    final client = MockClient((_) async => http.Response('', 404));
    addTearDown(client.close);
    expect(await TvMazeRepository(client).shows(99), isEmpty);
    await expectLater(
      TvMazeRepository(client).details(99),
      throwsA(isA<AppFailure>()),
    );
  });
  test('search is encoded and nested show payload is unwrapped', () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['q'], 'a & b');
      return http.Response(
        jsonEncode([
          {
            'score': 1,
            'show': {'id': 2, 'name': 'A & B'},
          },
        ]),
        200,
      );
    });
    addTearDown(client.close);
    expect((await TvMazeRepository(client).search(' a & b ')).single.id, 2);
  });
  for (final code in [429, 500]) {
    test('HTTP $code becomes a user-facing failure', () async {
      final client = MockClient((_) async => http.Response('', code));
      addTearDown(client.close);
      await expectLater(
        TvMazeRepository(client).shows(0),
        throwsA(isA<AppFailure>()),
      );
    });
  }
  test('malformed JSON and wrong schema become failures', () async {
    for (final body in [
      'not JSON',
      '{"unexpected":true}',
      '[{"name":"No id"}]',
    ]) {
      final client = MockClient((_) async => http.Response(body, 200));
      addTearDown(client.close);
      await expectLater(
        TvMazeRepository(client).shows(0),
        throwsA(isA<AppFailure>()),
      );
    }
  });
  test('transport failures are readable', () async {
    final client = MockClient(
      (_) async => throw http.ClientException('Offline'),
    );
    addTearDown(client.close);
    await expectLater(
      TvMazeRepository(client).shows(0),
      throwsA(
        isA<AppFailure>().having(
          (e) => e.message,
          'message',
          contains('internet'),
        ),
      ),
    );
  });
  test('details, cast and episodes use their separate endpoints', () async {
    final paths = <String>[];
    final client = MockClient((request) async {
      paths.add(request.url.path);
      if (request.url.path.endsWith('/cast')) {
        return http.Response(
          '[{"person":{"name":"Actor"},"character":{"name":"Role"}}]',
          200,
        );
      }
      if (request.url.path.endsWith('/episodes')) {
        return http.Response(
          '[{"id":10,"name":"Pilot","season":1,"number":1}]',
          200,
        );
      }
      return http.Response(
        '{"id":82,"name":"Show","summary":"<p>A &amp; B</p>"}',
        200,
      );
    });
    addTearDown(client.close);
    final repo = TvMazeRepository(client);
    expect((await repo.details(82)).summary, 'A & B');
    expect((await repo.cast(82)).single.character, 'Role');
    expect((await repo.episodes(82)).single.season, 1);
    expect(paths, ['/shows/82', '/shows/82/cast', '/shows/82/episodes']);
  });
}
