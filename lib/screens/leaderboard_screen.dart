import 'package:flutter/material.dart';
import '../services/ranking_service.dart';

/// 리더보드 화면
class LeaderboardScreen extends StatefulWidget {
  final VoidCallback? onStartNewGame;
  final int? newScore;
  final int? newStage;
  final Duration? newElapsedTime;

  const LeaderboardScreen({
    super.key,
    this.onStartNewGame,
    this.newScore,
    this.newStage,
    this.newElapsedTime,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isSaving = false;
  int? _newEntryRank; // 새로운 점수가 몇 위인지
  bool _hasBeenSaved = false; // 저장 완료 여부

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 새 점수를 기존 순위 리스트에 삽입하여 순위 계산
  List<RankingEntry> _insertNewScore(List<RankingEntry> rankings) {
    if (widget.newScore == null || widget.newStage == null || widget.newElapsedTime == null) {
      return rankings;
    }

    // 임시 엔트리 생성 (아직 저장 안됨)
    final tempEntry = RankingEntry(
      id: 'temp',
      playerName: '', // 빈 이름
      stage: widget.newStage!,
      elapsedTime: widget.newElapsedTime!,
      score: widget.newScore!,
      timestamp: DateTime.now(),
    );

    // 기존 순위에 새 점수 삽입
    final newList = [...rankings, tempEntry];
    newList.sort((a, b) => b.score.compareTo(a.score)); // 점수 내림차순

    // 30개로 제한
    final limitedList = newList.take(30).toList();

    // 새 점수가 30위 안에 있는지 확인
    final newEntryIndex = limitedList.indexWhere((e) => e.id == 'temp');

    if (newEntryIndex != -1 && _newEntryRank == null) {
      // build 완료 후 setState 호출
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _newEntryRank = newEntryIndex + 1;
          });
          // 자동으로 포커스
          _nameFocusNode.requestFocus();
        }
      });
    }

    return limitedList;
  }

  Future<void> _saveRanking() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이름을 입력해주세요')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await RankingService.instance.saveRanking(
        playerName: name,
        stage: widget.newStage!,
        elapsedTime: widget.newElapsedTime!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('순위가 저장되었습니다!')),
        );
        // 저장 완료 플래그 설정 (일반 순위표로 전환)
        setState(() {
          _hasBeenSaved = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_pool.png'),
            fit: BoxFit.cover, // 해상도에 맞게 자동 크롭
          ),
        ),
        child: Container(
          // 반투명 검은색 오버레이
          color: Colors.black.withValues(alpha: 0.5),
          child: SafeArea(
            child: Column(
              children: [
                // 헤더
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        icon:
                      CircleAvatar(
                        backgroundColor: Colors.white.withValues(alpha:0.3),
                        child: Icon(
                          Icons.close,
                          color: Colors.white.withValues(alpha:0.7),
                          size: 32,
                          weight: 900,
                        ),
                      ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (widget.onStartNewGame != null) {
                            widget.onStartNewGame!();
                          }
                        },
                      ),
                      const Expanded(
                        child: Text(
                          '그리피의 기억 랭킹',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'TJJoyofsinging',
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // 균형을 위한 공간
                    ],
                  ),
                ),

                // 리더보드 리스트
                Expanded(
                  child: StreamBuilder<List<RankingEntry>>(
                    stream: RankingService.instance.watchTopRankings(limit: 30),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            '순위를 불러올 수 없습니다',
                            style: TextStyle(
                              fontFamily: 'TJJoyofsinging',
                              fontSize: 18,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        );
                      }

                      var rankings = snapshot.data ?? [];

                      // 새 점수가 있고 아직 저장되지 않았으면 삽입
                      if (widget.newScore != null && !_hasBeenSaved) {
                        rankings = _insertNewScore(rankings);
                      }

                      if (rankings.isEmpty) {
                        return Center(
                          child: Text(
                            '아직 기록이 없습니다',
                            style: TextStyle(
                              fontFamily: 'TJJoyofsinging',
                              fontSize: 20,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: rankings.length,
                        itemBuilder: (context, index) {
                          final entry = rankings[index];
                          final rank = index + 1;
                          final isNewEntry = entry.id == 'temp';

                          // 상위 3위는 특별한 스타일
                          Color rankColor;
                          Color bgColor;
                          if (rank == 1) {
                            rankColor = const Color(0xFFFFD700); // 금색
                            bgColor = Colors.white.withValues(alpha: 0.95);
                          } else if (rank == 2) {
                            rankColor = const Color(0xFFC0C0C0); // 은색
                            bgColor = Colors.white.withValues(alpha: 0.9);
                          } else if (rank == 3) {
                            rankColor = const Color(0xFFCD7F32); // 동색
                            bgColor = Colors.white.withValues(alpha: 0.85);
                          } else {
                            rankColor = const Color(0xFFFF4D8B);
                            bgColor = Colors.white.withValues(alpha: 0.8);
                          }

                          // 새 엔트리는 하이라이트
                          if (isNewEntry) {
                            bgColor = const Color(0xFFFFEB3B).withValues(alpha: 0.9);
                            rankColor = const Color(0xFFFF6F00);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: rankColor,
                                width: isNewEntry ? 4 : (rank <= 3 ? 3 : 2),
                              ),
                              boxShadow: [
                                if (rank <= 3 || isNewEntry)
                                  BoxShadow(
                                    color: rankColor.withValues(alpha: 0.3),
                                    blurRadius: isNewEntry ? 12 : 8,
                                    offset: const Offset(0, 4),
                                  ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              child: Row(
                                children: [
                                  // 순위
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: rankColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$rank',
                                        style: const TextStyle(
                                          fontFamily: 'TJJoyofsinging',
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // 플레이어 이름 또는 입력 필드
                                  Expanded(
                                    child: isNewEntry
                                        ? TextField(
                                            controller: _nameController,
                                            focusNode: _nameFocusNode,
                                            enabled: !_isSaving,
                                            textAlign: TextAlign.center,
                                            decoration: InputDecoration(
                                              hintText: '이름 입력',
                                              hintStyle: TextStyle(
                                                fontFamily: 'TJJoyofsinging',
                                                fontSize: 16,
                                                color: const Color(0xff300313).withValues(alpha: 0.5),
                                              ),
                                              filled: true,
                                              fillColor: Colors.white.withValues(alpha: 0.9),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFFF4D8B),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              suffixIcon: IconButton(
                                                icon: _isSaving
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      )
                                                    : const Icon(Icons.check, color: Color(0xFFFF4D8B)),
                                                onPressed: _isSaving ? null : _saveRanking,
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontFamily: 'TJJoyofsinging',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xff300313),
                                            ),
                                          )
                                        : Text(
                                            entry.playerName,
                                            style: const TextStyle(
                                              fontFamily: 'TJJoyofsinging',
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xff300313),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),

                                  const SizedBox(width: 12),

                                  // 스테이지
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF4D8B),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Stage ${entry.stage}',
                                      style: const TextStyle(
                                        fontFamily: 'TJJoyofsinging',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // 시간
                                  Text(
                                    _formatDuration(entry.elapsedTime),
                                    style: const TextStyle(
                                      fontFamily: 'TJJoyofsinging',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff300313),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // 하단 여백
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
