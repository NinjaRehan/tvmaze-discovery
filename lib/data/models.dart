import 'package:html/parser.dart' as html;

String plainText(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }
  // Keep paragraph boundaries while decoding entities and removing markup.
  final document = html.parse(
    value.replaceAll(RegExp(r'</p>|<br\s*/?>', caseSensitive: false), '\n'),
  );
  return (document.body?.text ?? '').trim();
}

String? _image(dynamic value) {
  if (value is! Map) {
    return null;
  }
  return (value['medium'] ?? value['original']) as String?;
}

class Show {
  const Show({
    required this.id,
    required this.name,
    this.imageUrl,
    this.originalImageUrl,
    this.genres = const [],
    this.rating,
    this.summary = '',
    this.status = 'Unknown',
    this.language = 'Unknown',
    this.network = 'Unknown',
    this.premiered,
    this.ended,
    this.runtime,
    this.url,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final String? originalImageUrl;
  final List<String> genres;
  final double? rating;
  final String summary;
  final String status;
  final String language;
  final String network;
  final String? premiered;
  final String? ended;
  final int? runtime;
  final String? url;

  String get years {
    final start = premiered?.split('-').first;
    if (start == null || start.isEmpty) {
      return 'Release date unknown';
    }
    final end = ended?.split('-').first;
    return end != null
        ? (start == end ? start : '$start – $end')
        : status == 'Running'
        ? '$start – Present'
        : start;
  }

  factory Show.fromJson(Map<String, dynamic> json) {
    final image = json['image'];
    final rating = json['rating'];
    final network = json['network'] ?? json['webChannel'];
    return Show(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? 'Untitled show',
      imageUrl: _image(image),
      originalImageUrl: image is Map ? image['original'] as String? : null,
      genres: List<String>.unmodifiable(
        (json['genres'] as List? ?? []).whereType<String>(),
      ),
      rating: rating is Map ? (rating['average'] as num?)?.toDouble() : null,
      summary: plainText(json['summary'] as String?),
      status: json['status'] as String? ?? 'Unknown',
      language: json['language'] as String? ?? 'Unknown',
      network: network is Map
          ? network['name'] as String? ?? 'Unknown'
          : 'Unknown',
      premiered: json['premiered'] as String?,
      ended: json['ended'] as String?,
      runtime: ((json['averageRuntime'] ?? json['runtime']) as num?)?.toInt(),
      url: json['url'] as String?,
    );
  }

  // Store API-shaped metadata, so saved shows remain readable offline.
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name,
    'image': {'medium': imageUrl, 'original': originalImageUrl},
    'genres': genres, 'rating': {'average': rating},
    // Escape text before it is decoded by fromJson on the next launch.
    'summary': summary
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;'),
    'status': status, 'language': language, 'network': {'name': network},
    'premiered': premiered, 'ended': ended, 'averageRuntime': runtime,
    'url': url,
  };
}

class CastMember {
  const CastMember({
    required this.name,
    required this.character,
    this.imageUrl,
  });
  final String name;
  final String character;
  final String? imageUrl;
  factory CastMember.fromJson(Map<String, dynamic> json) {
    final person = json['person'] as Map<String, dynamic>? ?? {};
    final character = json['character'] as Map<String, dynamic>? ?? {};
    return CastMember(
      name: person['name'] as String? ?? 'Unknown actor',
      character: character['name'] as String? ?? 'Unknown character',
      imageUrl: _image(person['image']),
    );
  }
}

class Episode {
  const Episode({
    required this.id,
    required this.name,
    required this.season,
    this.number,
    this.airdate,
    this.runtime,
    this.imageUrl,
    this.summary = '',
  });
  final int id;
  final String name;
  final int season;
  final int? number;
  final String? airdate;
  final int? runtime;
  final String? imageUrl;
  final String summary;
  factory Episode.fromJson(Map<String, dynamic> json) => Episode(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String? ?? 'Untitled episode',
    season: (json['season'] as num?)?.toInt() ?? 0,
    number: (json['number'] as num?)?.toInt(),
    airdate: json['airdate'] as String?,
    runtime: (json['runtime'] as num?)?.toInt(),
    imageUrl: _image(json['image']),
    summary: plainText(json['summary'] as String?),
  );
}
