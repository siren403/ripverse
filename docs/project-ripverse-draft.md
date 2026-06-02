# Project Ripverse

> 카드를 사용하는 게임이 아니라,
> 카드를 뜯는 경험을 중심으로 성장하는 게임.

---

# Core Vision

Ripverse의 핵심은 TCG 배틀도, 경제 시뮬레이션도 아니다.

플레이어가 반복하게 되는 가장 작은 행동은:

```text
박스 획득
→ 개봉
→ 카드 공개
→ 다음 개봉
```

이다.

모든 시스템은 이 루프를 강화하기 위해 존재한다.

---

# Core Design Principle

새로운 기능을 추가할 때마다 다음 질문을 한다.

> "이 기능이 다음 팩을 더 열고 싶게 만드는가?"

YES라면 고려한다.

NO라면 후순위로 미룬다.

---

# MVP Goal

검증할 가설:

> 카드 개봉 자체가 수 시간 동안 반복 가능한 재미를 제공하는가?

아직 검증하지 않는 것:

- PvP
- 거래소
- 복잡한 경제
- 길드
- 메타 경쟁

---

# Initial Gameplay Loop

```text
자원 획득
↓
박스 구매
↓
팩 개봉
↓
카드 획득
↓
판매 또는 보관
↓
다음 박스
```

---

# Layer Structure

## Layer 0 - Core

### Rip Loop

```text
박스 획득
↓
박스 개봉
↓
팩 선택
↓
카드 공개
↓
결과 확인
```

가장 중요한 레이어.

여기가 재미없으면 나머지는 의미 없음.

---

## Layer 1 - Collection

### Collector Play

```text
도감
세트 수집
희귀 카드 수집
```

개봉에 장기 목표를 제공.

---

## Layer 2 - Grading

### Grader Play

```text
카드 획득
↓
그레이딩 의뢰
↓
등급 판정
↓
가치 상승
```

카드 획득 이후의 기대감을 제공.

---

## Layer 3 - Roguelike

### High Risk / High Return

개봉한 카드를 활용하는 컨텐츠.

```text
런 진입
↓
카드 활용
↓
스코어 획득
↓
보상 획득
```

목적:

- 카드에 사용처 제공
- 자산 소모처 제공
- 고위험 고보상 제공

---

## Layer 4 - Trading

### Trader Play

```text
시세 확인
↓
매수
↓
보유
↓
매도
```

후반 컨텐츠.

초기 MVP 범위 제외.

---

# Dual Structure

## Safe Content

### Idle / Collection

```text
카드 수집
개봉
도감
그레이딩
```

특징:

- 안정적 성장
- 낮은 리스크
- 꾸준한 진척

---

## Risk Content

### Roguelike

```text
자산 투자
카드 활용
고위험 고보상
```

특징:

- 실패 가능
- 큰 보상
- 높은 감정 곡선

---

# Player Archetypes

직업 시스템 없음.

모든 플레이 스타일은 항상 열려있다.

---

## Breaker

```text
더 많은 박스
더 많은 개봉
```

---

## Collector

```text
도감 완성
세트 수집
```

---

## Grader

```text
고등급 카드 확보
```

---

## Trader

```text
매매 차익
```

---

## Investor

```text
장기 보유
```

---

# Affinity System

플레이어가 선택하는 것이 아니라

플레이어의 행동으로 형성된다.

예시:

```text
Breaker 85
Collector 42
Grader 18
Trader 7
Investor 31
```

---

# Endgame Philosophy

단일 엔딩 없음.

각 플레이 스타일마다 다른 목표가 존재.

예시:

### Breaker

```text
100만 팩 개봉
```

### Collector

```text
도감 100%
```

### Grader

```text
PSA10급 카드 1000장
```

### Investor

```text
순자산 1B
```

---

# What Ripverse Is

- 카드 개봉 게임
- 수집 게임
- 로그라이크
- 성향 기반 샌드박스

---

# What Ripverse Is Not

- TCG 배틀 게임
- 현실 카드샵 시뮬레이터
- 경제 시뮬레이션
- 경쟁 PvP 중심 게임

---

# Development Roadmap

## Phase 1

Core Rip Loop

```text
박스
팩
개봉
판매
```

검증:

"계속 뜯고 싶은가?"

---

## Phase 2

Collection

```text
도감
세트
수집 목표
```

검증:

"보관하고 싶은가?"

---

## Phase 3

Grading

```text
등급
희귀도 상승
```

검증:

"카드의 미래 가치에 기대를 갖는가?"

---

## Phase 4

Roguelike

```text
카드 활용
고위험 고보상
```

검증:

"카드를 사용하고 싶은가?"

---

## Phase 5

Trading

```text
시장
투자
매매
```

검증:

"카드를 자산처럼 다루고 싶은가?"

---

# North Star

Ripverse의 모든 시스템은 하나의 목표를 가진다.

> "플레이어가 다음 팩을 열고 싶게 만든다."
