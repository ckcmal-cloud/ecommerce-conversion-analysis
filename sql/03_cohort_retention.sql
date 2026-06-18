-- 목적: 유저별 최초 유입월(Cohort)을 정의하고, 이를 기준으로 월별 재방문율(Retention)을 다차원 연산, 리텐션 매트릭스 테이블 생성
-- 참고: 02_ecommerce_behavior_analysis.ipynb의 "코호트 및 리텐션 분석" 로직

-- 1. 유저별 최초 방문월(유입 Cohort 기준월) 산출
CREATE TABLE user_first_month AS
SELECT 
    user_id,
    MIN(event_month) AS first_month
FROM user_event_table
GROUP BY user_id;

-- 2. 유저별 월단위 고유 방문 기록 생성
CREATE TABLE user_monthly_activity AS
SELECT DISTINCT
    user_id,
    event_month AS active_month
FROM user_event_table;

-- 3. 최초 유입월과 활동월 매칭 및 경과 월수(Cohort Index) 계산
CREATE TABLE cohort_index_calc AS
SELECT 
    act.user_id,
    first.first_month,
    act.active_month,
    
    -- 경과 월수 연산
    -- (현재활동년도 - 최초유입년도) * 12 + (현재활동월 - 최초유입월)
    (EXTRACT(YEAR FROM act.active_month) - EXTRACT(YEAR FROM first.first_month)) * 12 
    + (EXTRACT(MONTH FROM act.active_month) - EXTRACT(MONTH FROM first.first_month)) AS period_diff
FROM user_monthly_activity act
INNER JOIN user_first_month first 
    ON act.user_id = first.user_id;

-- 4. 코호트 그룹 및 인덱스 단위 고유 활성 사용자 수 선집계
-- (GROUP BY 집계와 Window Function 분리를 위해 별도 중간 테이블로 생성)
CREATE TABLE cohort_aggregated AS
SELECT 
    first_month,
    period_diff AS cohort_index,
    COUNT(DISTINCT user_id) AS active_users
FROM cohort_index_calc
GROUP BY 
    first_month,
    period_diff;

-- 5. 최종 코호트 잔존율 요약 테이블 생성 (Window Function 활용)
-- 집계 완료된 cohort_aggregated에 FIRST_VALUE 윈도우 함수 적용 (문법 안전 보장)
CREATE TABLE cohort_retention_results AS
SELECT 
    first_month,
    cohort_index,
    active_users,
    
    -- 유입 당월(cohort_index = 0) 기준의 유지 비율 연산용 기준 고객 수
    FIRST_VALUE(active_users) OVER (PARTITION BY first_month ORDER BY cohort_index) AS cohort_size,
    
    -- 코호트 리텐션 비율(%)
    ROUND(
        active_users * 100.0 / 
        FIRST_VALUE(active_users) OVER (PARTITION BY first_month ORDER BY cohort_index), 
        2
    ) AS retention_rate_pct
FROM cohort_aggregated;
