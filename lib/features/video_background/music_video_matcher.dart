/// Metadatos de la pista local usados para buscar su video correspondiente.
class MusicVideoSongMetadata {
  const MusicVideoSongMetadata({
    required this.title,
    required this.artist,
    this.album,
    this.durationSeconds,
  });

  final String title;
  final String artist;
  final String? album;
  final int? durationSeconds;
}

/// Candidato obtenido de YouTube (directamente o por medio de Piped).
class YouTubeCandidate {
  const YouTubeCandidate({
    required this.videoId,
    required this.title,
    required this.uploaderName,
    required this.durationSeconds,
    this.description = '',
    this.uploaderVerified = false,
    this.isMusicCategory = false,
    this.views = 0,
    this.searchRank = 0,
  });

  final String videoId;
  final String title;
  final String uploaderName;
  final int durationSeconds;
  final String description;
  final bool uploaderVerified;
  final bool isMusicCategory;
  final int views;

  /// Posicion original en los resultados. Solo se usa como ultimo desempate.
  final int searchRank;
}

enum MusicVideoConfidence { high, medium, low }

enum MusicVideoSourceType {
  officialArtistChannel,
  artistTopic,
  artistVevo,
  officialLabel,
  otherMusicChannel,
  unknown,
}

/// Resultado explicable de la seleccion. `null` significa
/// `NoOfficialMatchFound`: ningun candidato supero el umbral minimo.
class MusicVideoMatch {
  const MusicVideoMatch({
    required this.videoId,
    required this.score,
    required this.confidence,
    required this.sourceType,
    required this.officialScore,
    required this.identityScore,
    required this.durationScore,
  });

  final String videoId;
  final int score;
  final MusicVideoConfidence confidence;
  final MusicVideoSourceType sourceType;
  final int officialScore;
  final int identityScore;
  final int durationScore;
}

/// Compara candidatos ya obtenidos. No conoce HTTP, Piped, Riverpod ni la
/// base de datos, por lo que su resultado es determinista y facil de probar.
class MusicVideoMatcher {
  const MusicVideoMatcher();

  MusicVideoMatch? selectBestMatch(
    MusicVideoSongMetadata song,
    Iterable<YouTubeCandidate> candidates,
  ) {
    final evaluations = candidates
        .map((candidate) => _evaluate(song, candidate))
        .where((evaluation) => evaluation.isEligible)
        .toList();
    if (evaluations.isEmpty) return null;

    evaluations.sort(_compareEvaluations);
    final best = evaluations.first;
    return MusicVideoMatch(
      videoId: best.candidate.videoId,
      score: best.totalScore,
      confidence: best.confidence!,
      sourceType: best.sourceType,
      officialScore: best.officialScore,
      identityScore: best.identityScore,
      durationScore: best.durationScore,
    );
  }

  _CandidateEvaluation _evaluate(
    MusicVideoSongMetadata song,
    YouTubeCandidate candidate,
  ) {
    final songTitle = _normalize(song.title);
    final artist = _meaningfulArtist(song.artist);
    final album = _normalize(song.album ?? '');
    final title = _normalize(candidate.title);
    final uploader = _normalize(candidate.uploaderName);
    final description = _normalize(candidate.description);

    final exactSong = songTitle.isNotEmpty && _containsPhrase(title, songTitle);
    final artistInTitle = artist.isNotEmpty && _containsPhrase(title, artist);
    final artistInUploader =
        artist.isNotEmpty && _containsPhrase(uploader, artist);
    final artistInDescription =
        artist.isNotEmpty && _containsPhrase(description, artist);
    final artistMatched =
        artistInTitle || artistInUploader || artistInDescription;

    final sourceType = _sourceTypeOf(
      candidate,
      normalizedArtist: artist,
      normalizedTitle: title,
      normalizedUploader: uploader,
      normalizedDescription: description,
    );

    var officialScore = _sourceScore(sourceType);
    final officialMusicVideo = _containsPhrase(title, 'official music video');
    final officialVideo = _containsPhrase(title, 'official video');
    final officialAudio = _containsPhrase(title, 'official audio');
    if (officialMusicVideo) {
      officialScore += 25;
    } else if (officialVideo) {
      officialScore += 20;
    } else if (officialAudio) {
      officialScore += 15;
    }

    var disqualified = false;
    for (final rule in _negativeRules) {
      if (!_addsUnrequestedVariant(
        candidateTitle: title,
        requestedTitle: songTitle,
        requestedAlbum: album,
        term: rule.term,
      )) {
        continue;
      }
      officialScore += rule.penalty;
      disqualified = disqualified || rule.disqualifying;
    }

    var identityScore = 0;
    if (exactSong) identityScore += 50;
    if (artistInTitle) {
      identityScore += 40;
    } else if (artistInUploader) {
      identityScore += 35;
    } else if (artistInDescription) {
      identityScore += 20;
    }
    if (album.isNotEmpty &&
        (_containsPhrase(title, album) ||
            _containsPhrase(description, album))) {
      identityScore += 10;
    }
    if (candidate.isMusicCategory) identityScore += 20;

    final durationScore = _durationScore(
      expectedSeconds: song.durationSeconds,
      actualSeconds: candidate.durationSeconds,
      trustedOfficialVideo: officialMusicVideo && _isOfficialSource(sourceType),
    );
    final totalScore = officialScore + identityScore + durationScore;

    final hasSupportingIdentity = artist.isEmpty
        ? durationScore >= 15 || candidate.isMusicCategory
        : artistMatched || durationScore >= 15;
    final confidence = !disqualified && exactSong && hasSupportingIdentity
        ? _confidenceOf(
            totalScore: totalScore,
            exactSong: exactSong,
            artistMatched: artistMatched,
            sourceType: sourceType,
            durationScore: durationScore,
          )
        : null;

    return _CandidateEvaluation(
      candidate: candidate,
      sourceType: sourceType,
      officialScore: officialScore,
      identityScore: identityScore,
      durationScore: durationScore,
      totalScore: totalScore,
      confidence: confidence,
    );
  }

  static MusicVideoSourceType _sourceTypeOf(
    YouTubeCandidate candidate, {
    required String normalizedArtist,
    required String normalizedTitle,
    required String normalizedUploader,
    required String normalizedDescription,
  }) {
    if (normalizedArtist.isEmpty || normalizedUploader.isEmpty) {
      return candidate.isMusicCategory
          ? MusicVideoSourceType.otherMusicChannel
          : MusicVideoSourceType.unknown;
    }

    final channelMatchesArtist = _containsPhrase(
      normalizedUploader,
      normalizedArtist,
    );
    final corroboratedArtist =
        _containsPhrase(normalizedTitle, normalizedArtist) ||
        _containsPhrase(normalizedDescription, normalizedArtist);
    // El insignia de verificado no siempre llega: la busqueda movil de
    // YouTube (a la que redirige el user-agent de telefono) no la incluye en
    // absoluto para ningun resultado. Sin esta señal alternativa, un canal de
    // sello real como el de un video oficial con millones de vistas quedaria
    // permanentemente clasificado como `unknown`. El titulo declarando
    // explicitamente "official video" es una señal que el propio canal no
    // puede fingir sin que YouTube la retire, asi que sirve de sustituto
    // cuando el badge no esta disponible.
    final titleDeclaresOfficial = _containsPhrase(
          normalizedTitle,
          'official music video',
        ) ||
        _containsPhrase(normalizedTitle, 'official video') ||
        _containsPhrase(normalizedTitle, 'video oficial');
    final reliableChannelEvidence =
        candidate.uploaderVerified ||
        (candidate.isMusicCategory && corroboratedArtist) ||
        (titleDeclaresOfficial && corroboratedArtist);

    final isTopic =
        channelMatchesArtist &&
        normalizedUploader.endsWith(' topic') &&
        reliableChannelEvidence;
    if (isTopic) return MusicVideoSourceType.artistTopic;

    final compactArtist = normalizedArtist.replaceAll(' ', '');
    final compactUploader = normalizedUploader.replaceAll(' ', '');
    final isVevo =
        compactArtist.isNotEmpty &&
        compactUploader.contains('${compactArtist}vevo') &&
        reliableChannelEvidence;
    if (isVevo) return MusicVideoSourceType.artistVevo;

    final exactArtistChannel =
        normalizedUploader == normalizedArtist ||
        normalizedUploader == '$normalizedArtist official' ||
        normalizedUploader == 'official $normalizedArtist';
    if (exactArtistChannel && reliableChannelEvidence) {
      return MusicVideoSourceType.officialArtistChannel;
    }

    final looksLikeLabel = _labelTerms.any(
      (term) => _containsPhrase(normalizedUploader, term),
    );
    if (looksLikeLabel && reliableChannelEvidence) {
      return MusicVideoSourceType.officialLabel;
    }

    if (candidate.isMusicCategory ||
        candidate.uploaderVerified ||
        reliableChannelEvidence) {
      return MusicVideoSourceType.otherMusicChannel;
    }
    return MusicVideoSourceType.unknown;
  }

  static int _sourceScore(MusicVideoSourceType sourceType) =>
      switch (sourceType) {
        MusicVideoSourceType.officialArtistChannel => 100,
        MusicVideoSourceType.artistTopic => 90,
        MusicVideoSourceType.artistVevo => 90,
        MusicVideoSourceType.officialLabel => 70,
        MusicVideoSourceType.otherMusicChannel => 10,
        MusicVideoSourceType.unknown => 0,
      };

  static int _durationScore({
    required int? expectedSeconds,
    required int actualSeconds,
    required bool trustedOfficialVideo,
  }) {
    if (expectedSeconds == null || expectedSeconds <= 0 || actualSeconds <= 0) {
      return 0;
    }
    final difference = (expectedSeconds - actualSeconds).abs();
    if (difference <= 5) return 25;
    if (difference <= 15) return 15;
    if (difference <= 30) return 8;
    if (trustedOfficialVideo) {
      // Un videoclip oficial puede incluir dialogo, creditos o introduccion.
      return difference <= 90 ? 0 : -20;
    }
    return difference <= 90 ? -25 : -45;
  }

  static MusicVideoConfidence? _confidenceOf({
    required int totalScore,
    required bool exactSong,
    required bool artistMatched,
    required MusicVideoSourceType sourceType,
    required int durationScore,
  }) {
    if (!exactSong || totalScore < _minimumScore) return null;
    if (totalScore >= 180 && artistMatched && _isOfficialSource(sourceType)) {
      return MusicVideoConfidence.high;
    }
    if (totalScore >= 125 && (artistMatched || durationScore >= 15)) {
      return MusicVideoConfidence.medium;
    }
    return MusicVideoConfidence.low;
  }

  static bool _isOfficialSource(MusicVideoSourceType sourceType) =>
      switch (sourceType) {
        MusicVideoSourceType.officialArtistChannel ||
        MusicVideoSourceType.artistTopic ||
        MusicVideoSourceType.artistVevo ||
        MusicVideoSourceType.officialLabel => true,
        MusicVideoSourceType.otherMusicChannel ||
        MusicVideoSourceType.unknown => false,
      };

  /// Los terminos que forman parte del titulo/album solicitado no describen
  /// una variante indeseada. Esto evita falsos positivos como "Piano Man" o
  /// "Live Forever", pero sigue penalizando "Piano Man - cover" porque el
  /// candidato agrega una segunda aparicion de `cover`.
  static bool _addsUnrequestedVariant({
    required String candidateTitle,
    required String requestedTitle,
    required String requestedAlbum,
    required String term,
  }) {
    final candidateCount = _phraseCount(candidateTitle, term);
    if (candidateCount == 0) return false;
    final requestedCount =
        _phraseCount(requestedTitle, term) + _phraseCount(requestedAlbum, term);
    return candidateCount > requestedCount;
  }

  static int _compareEvaluations(
    _CandidateEvaluation left,
    _CandidateEvaluation right,
  ) {
    var comparison = right.officialScore.compareTo(left.officialScore);
    if (comparison != 0) return comparison;
    comparison = right.identityScore.compareTo(left.identityScore);
    if (comparison != 0) return comparison;
    comparison = right.durationScore.compareTo(left.durationScore);
    if (comparison != 0) return comparison;
    comparison = right.candidate.views.compareTo(left.candidate.views);
    if (comparison != 0) return comparison;
    comparison = left.candidate.searchRank.compareTo(
      right.candidate.searchRank,
    );
    if (comparison != 0) return comparison;
    return left.candidate.videoId.compareTo(right.candidate.videoId);
  }

  static String _meaningfulArtist(String value) {
    final normalized = _normalize(value);
    return _unknownArtists.contains(normalized) ? '' : normalized;
  }

  static String _normalize(String value) {
    var normalized = value.toLowerCase();
    const replacements = <String, String>{
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });
    normalized = normalized
        .replaceAll(RegExp(r"[’']"), '')
        .replaceAll(RegExp(r'[\[\](){}.,!?;:"/\\|_+=~`@#\$%^&*<>\-–—]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return normalized;
  }

  static bool _containsPhrase(String text, String phrase) {
    if (text.isEmpty || phrase.isEmpty) return false;
    return text == phrase || ' $text '.contains(' $phrase ');
  }

  static int _phraseCount(String text, String phrase) {
    if (text.isEmpty || phrase.isEmpty) return 0;
    final textParts = text.split(' ');
    final phraseParts = phrase.split(' ');
    if (phraseParts.length > textParts.length) return 0;
    var count = 0;
    for (
      var index = 0;
      index <= textParts.length - phraseParts.length;
      index++
    ) {
      var matches = true;
      for (var offset = 0; offset < phraseParts.length; offset++) {
        if (textParts[index + offset] != phraseParts[offset]) {
          matches = false;
          break;
        }
      }
      if (matches) count++;
    }
    return count;
  }

  static const _minimumScore = 90;

  static const _unknownArtists = {
    '',
    'unknown',
    'unknown artist',
    'artista desconocido',
  };

  static const _labelTerms = {
    'records',
    'recordings',
    'music group',
    'music entertainment',
    'distribution',
    'distributor',
    'label',
  };

  static const _negativeRules = <_NegativeRule>[
    _NegativeRule('cover', -100, disqualifying: true),
    _NegativeRule('reaction', -100, disqualifying: true),
    _NegativeRule('karaoke', -100, disqualifying: true),
    _NegativeRule('tutorial', -90, disqualifying: true),
    _NegativeRule('nightcore', -80, disqualifying: true),
    _NegativeRule('slowed', -80, disqualifying: true),
    _NegativeRule('sped up', -80, disqualifying: true),
    _NegativeRule('8d', -75, disqualifying: true),
    _NegativeRule('instrumental', -70, disqualifying: true),
    _NegativeRule('piano', -70, disqualifying: true),
    _NegativeRule('guitar', -70, disqualifying: true),
    _NegativeRule('fan made', -60, disqualifying: true),
    _NegativeRule('fanmade', -60, disqualifying: true),
    _NegativeRule('tribute', -60, disqualifying: true),
    _NegativeRule('amv', -60, disqualifying: true),
    _NegativeRule('remake', -60, disqualifying: true),
    _NegativeRule('remix', -50),
    _NegativeRule('live', -30),
    _NegativeRule('concert', -30),
    _NegativeRule('lyric video', -20),
    _NegativeRule('lyrics', -20),
  ];
}

class _NegativeRule {
  const _NegativeRule(this.term, this.penalty, {this.disqualifying = false});

  final String term;
  final int penalty;
  final bool disqualifying;
}

class _CandidateEvaluation {
  const _CandidateEvaluation({
    required this.candidate,
    required this.sourceType,
    required this.officialScore,
    required this.identityScore,
    required this.durationScore,
    required this.totalScore,
    required this.confidence,
  });

  final YouTubeCandidate candidate;
  final MusicVideoSourceType sourceType;
  final int officialScore;
  final int identityScore;
  final int durationScore;
  final int totalScore;
  final MusicVideoConfidence? confidence;

  bool get isEligible => confidence != null;
}
