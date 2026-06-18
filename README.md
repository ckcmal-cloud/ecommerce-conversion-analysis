# REES46 러시아 네일 이커머스 고객 행동 데이터 분석
> 네일 이커머스 로그 760만 건 분석: 가격 구조, 구매 행동, 재구매, 브랜드 전환 및 고객 세그먼트를 기반으로 Runail 고객 회수 전략 도출


## 프로젝트 목표:
> 네일 이커머스 고객의 탐색·장바구니·구매 행동을 분석하고, 브랜드 전환 및 고객 세그먼트 특성을 기반으로 고객 유지 및 회수 전략을 도출

## Dataset
- 원본 데이터: 20,692,840건
- 네일 시장 데이터: 7,600,542건
- 브랜드 수: 46개
- 상품 수: 18,077개
- 유저 수: 616,100명


## Analysis

### 1. 시장 구조 및 구매 행동 분석

- 브랜드 기반 네일 시장 데이터셋 구축
- 가격 구간별 시장 구조 분석
- 이벤트 비중 및 구매 퍼널 분석
- 장바구니 행동 패턴 분석

### 2. 고객 유지 및 재구매 분석

- 신규·기존 고객 매출 비중 분석
- 헤비유저 매출 기여도 분석
- 재구매 주기 분석
- 코호트 리텐션 분석

### 3. 고객 세그먼트 및 브랜드 전환 분석

- Runail·Grattol 브랜드 전환 분석
- RFM 기반 고객 세그먼트 분석
- 고객 회수 번들 전략 시나리오 도출


## 주요 결과

- 원본 2,069만 로그에서 네일 시장 760만 로그를 구축
- 장바구니 삭제율 73.12%로 장바구니가 비교·선별 공간으로 작동함을 확인
- 상위 25% 헤비유저가 전체 매출의 68.46%를 차지
- 헤비 고객의 1개월 리텐션은 20.4%로 일반 고객 4% 대비 높게 나타남
- Runail은 높은 유입 전환율에도 불구하고 Grattol 유출 규모가 더 커 순손실 54,664 달러 발생
- RFM 기반 고객 세그먼트를 활용한 번들 회수 전략 시나리오 도출


## 인사이트

- 네일 시장은 저가 SKU 중심 구조로 운영되고 있음
- 장바구니 고객은 구매 가능성과 이탈 위험이 동시에 높고, 평일에 활발히 구매하는 B2B 고객 패턴을 보임
- 매출과 리텐션 모두 헤비유저에 집중되어 있어 핵심 고객 관리가 중요
- 브랜드 전환 고객 분석을 통해 유출 방어 및 회수 전략 수립 가능
- 고객 세그먼트 기반 차별화 전략이 일괄 프로모션보다 효과적


## 분석 기법

- 데이터 전처리 및 결측치 제
- 브랜드 사전 구축 및 네일 시장 라벨링
- 퍼널 분석
- 장바구니 행동 분석
- 가격 구간 분석
- 코호트 리텐션 분석
- 재구매 주기 분석
- 브랜드 전환 분석
- RFM 분석
- K-Means 군집화
- 고객 세그먼트 분석


## 데이터 출처

- [eCommerce Events History in Cosmetics Shop](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-cosmetics-shop)

## Tableau Dashboard

- [전략 대시보드](https://public.tableau.com/app/profile/minjeong.choi/viz/nail_dashboard_master/Nail_overview)
- [월별 운영 대시보드](https://public.tableau.com/app/profile/minjeong.choi/viz/nail_dashboard_monthly/nail_dashboard_monthly)

## SQL 재설계 (보완 프로젝트)
- 기존 Python 기반 이커머스 EDA 분석 프로젝트를 마케팅 CRM 및 추천 시스템 입력 스키마 요건에 맞추어 실무형 SQL 데이터 마트 구조로 재구성하며 데이터 정합성을 고도화함

### 파이프라인 (Pipeline)
01_user_event_table.sql (타임존 로컬 변환 및 무효 로그 기초 정제)
→ 02_funnel_rfm_analysis.sql (세션 단위 퍼널 및 NTILE 기반 R·F·M 등급 연산)
→ 03_cohort_retention.sql (최초 방문월 정의 및 월별 코호트 잔존율 집계)
→ 04_crm_dashboard_mart.sql (시각화 대시보드 연동용 핵심 KPI 및 통합 CRM 마트 구축)

### 구현 내용
- 광고 참여 로그와 적립 로그 통합
- CTIT 및 IP 기반 어뷰징 탐지
- 도메인별 KPI 집계
- 추천용 데이터 마트 생성
- CTE 및 Window Function 활용
- JOIN Fan-out 방지를 위한 집계 구조 설계

### 학습 내용
- Python 기반 EDA 로직의 SQL 재구성
- Funnel · Cohort · RFM 분석 구조 구현
- CTE 및 Window Function 활용
- 데이터 Grain 관리 및 Fan-out 방지
- 데이터 정합성을 고려한 SQL 설계

