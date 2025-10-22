import 'package:flutter/material.dart';

/// 게임 설정 상수
class GameConfig {
  // 인스턴스화 방지
  GameConfig._();

  // ==================== 카드 물리 설정 ====================

  /// 카드가 떠다니는 속도 (픽셀/초)
  static const double cardFloatSpeed = 30.0;

  /// 카드 부유 주파수 범위 (최소~최대)
  static const double cardFloatFrequencyMin = 0.5;
  static const double cardFloatFrequencyMax = 1.0;

  /// 카드 뒤집기 애니메이션 시간 (초)
  static const double cardFlipDuration = 0.3;

  /// 카드 충돌 반발 계수 (0.0 = 반발 없음, 1.0 = 완전 반발)
  static const double cardBounceFactor = 0.8;


  // ==================== 카드 그림자 설정 ====================

  /// 그림자 표시 여부
  static const bool shadowEnabled = true;

  /// 그림자 Y 오프셋 (카드 아래 거리, 픽셀)
  static const double shadowOffsetY = 40.0;

  /// 그림자 X 오프셋 (카드 아래 거리, 픽셀)
  static const double shadowOffsetX = 40.0;

  /// 그림자 너비 배수 (카드 너비 기준)
  static const double shadowWidthMultiplier = 1;

  /// 그림자 높이 배수 (카드 높이 기준)
  static const double shadowHeightMultiplier = 1;

  /// 그림자 투명도 (0.0~1.0)
  static const double shadowOpacity = 0.15;

  /// 그림자 색상
  static const Color shadowColor = Color.fromARGB(255, 30, 28, 28); // 검은색


  // ==================== 물결 애니메이션 설정 ====================

  /// 물결 생성 간격 (초)
  static const double rippleInterval = 1.0;

  /// 물결 최대 반지름 (카드 크기 배수)
  static const double rippleMaxRadiusMultiplier = 0.5;

  /// 물결 애니메이션 지속 시간 (초)
  static const double rippleDuration = 1.0;

  /// 물결 색상
  static const Color rippleColor = Color(0xFFFFFFFF); // 흰색

  /// 물결 선 두께
  static const double rippleStrokeWidth = 5.0;
  static const double rippleStrokeWidthSecondary = 4.0;

  /// 물결 투명도 (0.0~1.0)
  static const double rippleOpacityMain = 0.75;
  static const double rippleOpacitySecondary = 0.55;

  /// 물결 렌더링 우선순위 (음수 = 카드 뒤에 그리기)
  static const int ripplePriority = -1;


  // ==================== 카드 매칭 애니메이션 설정 ====================

  /// 매칭 성공 애니메이션 시간 (초)
  static const double matchSuccessAnimationDuration = 1.0;

  /// 매칭 실패 애니메이션 시간 (초)
  static const double matchFailAnimationDuration = 0.5;

  /// 매칭 성공시 펄스 크기 배수
  static const double matchSuccessPulseScale = 1.2;

  /// 가라앉기 애니메이션 거리 (픽셀)
  static const double sinkAnimationDistance = 200.0;

  /// 튀어오르기 애니메이션 높이 (픽셀)
  static const double jumpAnimationHeight = 150.0;

  /// 흔들림 애니메이션 강도 (픽셀)
  static const double shakeAnimationIntensity = 10.0;

  /// 매칭 성공시 물결 크기 배수
  static const double matchSuccessRippleMultiplier = 1.5;


  // ==================== 게임 타이밍 설정 ====================

  /// 셔플 애니메이션 시간 (초)
  static const double shufflingDuration = 1.0;

  /// 매칭 확인 딜레이 (초)
  static const double matchCheckDelay = 1.0;


  // ==================== 파워업 설정 ====================

  /// 매칭 실패 후 힌트 아이콘 출현 확률 (0.0~1.0)
  static const double hintPowerupChance = 0.20; // 5%

  /// 매칭 실패 후 하트 아이콘 출현 확률 (0.0~1.0)
  static const double heartPowerupChance = 0.30; // 10%

  /// 힌트 사용시 카드 공개 시간 (초)
  static const double hintRevealDuration = 3.0;

  /// 파워업 카드 매칭 실패시 패널티 셔플 시간 (초)
  static const double penaltyShuffleDuration = 1.5;


  // ==================== UI 설정 ====================

  /// 매칭 성공시 획득 점수
  static const int scorePerMatch = 100;


  // ==================== 레이아웃 설정 ====================

  /// 카드 배치 열 개수
  static const int cardLayoutColumns = 4;

  /// 카드 크기 (화면 너비 비율)
  static const double cardSizeFraction = 1 / 4.5;

  /// 카드 간격 (화면 너비 비율)
  static const double cardSpacingFraction = 1 / 5;

  /// 카드 행 간격 배수 (카드 크기 기준)
  static const double cardRowSpacingMultiplier = 1.5;

  /// 카드 배치 시작 위치 (화면 높이 비율, 위에서부터)
  static const double cardLayoutStartY = 0.25;
}
