import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Ranking data model
class RankingEntry {
  final String id;
  final String playerName;
  final int stage;
  final Duration elapsedTime;
  final int score;
  final DateTime timestamp;

  RankingEntry({
    required this.id,
    required this.playerName,
    required this.stage,
    required this.elapsedTime,
    required this.score,
    required this.timestamp,
  });

  factory RankingEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RankingEntry(
      id: doc.id,
      playerName: data['playerName'] ?? 'Unknown',
      stage: data['stage'] ?? 0,
      elapsedTime: Duration(seconds: data['elapsedSeconds'] ?? 0),
      score: data['score'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'playerName': playerName,
      'stage': stage,
      'elapsedSeconds': elapsedTime.inSeconds,
      'score': score,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Service for managing game rankings
class RankingService {
  static final RankingService instance = RankingService._();
  RankingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'rankings';

  /// Calculate score based on stage reached and elapsed time
  /// Higher stage = higher score, lower time = higher score
  /// Score = stage * 10000 - elapsedSeconds
  int calculateScore(int stage, Duration elapsedTime) {
    return (stage * 10000) - elapsedTime.inSeconds;
  }

  /// Save ranking to Firestore
  Future<void> saveRanking({
    required String playerName,
    required int stage,
    required Duration elapsedTime,
  }) async {
    try {
      final score = calculateScore(stage, elapsedTime);
      final entry = RankingEntry(
        id: '',
        playerName: playerName,
        stage: stage,
        elapsedTime: elapsedTime,
        score: score,
        timestamp: DateTime.now(),
      );

      await _firestore.collection(_collectionName).add(entry.toFirestore());
    } catch (e) {
      debugPrint('Error saving ranking: $e');
      rethrow;
    }
  }

  /// Get top rankings
  Future<List<RankingEntry>> getTopRankings({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('score', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => RankingEntry.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting rankings: $e');
      return [];
    }
  }

  /// Get player's rank
  Future<int?> getPlayerRank(String playerName) async {
    try {
      final allRankings = await _firestore
          .collection(_collectionName)
          .orderBy('score', descending: true)
          .get();

      final playerDocs = allRankings.docs
          .where((doc) => (doc.data())['playerName'] == playerName)
          .toList();

      if (playerDocs.isEmpty) return null;

      final playerBestDoc = playerDocs.first;
      final rank = allRankings.docs.indexWhere((doc) => doc.id == playerBestDoc.id);

      return rank + 1;
    } catch (e) {
      debugPrint('Error getting player rank: $e');
      return null;
    }
  }

  /// Stream top rankings for real-time updates
  Stream<List<RankingEntry>> watchTopRankings({int limit = 10}) {
    return _firestore
        .collection(_collectionName)
        .orderBy('score', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => RankingEntry.fromFirestore(doc)).toList());
  }
}
