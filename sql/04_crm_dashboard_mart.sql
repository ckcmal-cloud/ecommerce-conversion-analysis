-- 목적: 브랜드, RFM 세그먼트, 퍼널 성과 및 코호트 유입 데이터를 유저 중심 및 집계 레벨로 결합 대시보드 시각화용 최종 CRM 데이터 마트 구축
-- 참고: 이커머스 행동분석의 CRM 대시보드 요약 마트 생성 반영

-- 1. 유저별 선호 브랜드(가장 많이 조회/구매한 브랜드) 추출
CREATE TABLE user_preferred_brand AS
SELECT 
    user_id,
    brand AS preferred_brand
FROM (
    SELECT 
        user_id,
        brand,
        COUNT(1) AS action_count,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY COUNT(1) DESC) AS rn
    FROM user_event_table
    WHERE brand IS NOT NULL
    GROUP BY user_id, brand
) t
WHERE rn = 1; -- 가장 상호작용이 많았던 1순위 브랜드 매핑

-- 2. 유저별 코호트 최초 유입월 추출
CREATE TABLE user_cohort AS
SELECT 
    user_id,
    MIN(event_month) AS first_month
FROM user_event_table
GROUP BY user_id;

-- 3. 유저별 퍼널 완료 여부 집계
CREATE TABLE user_funnel_summary AS
SELECT 
    user_id,
    MAX(has_view) AS ever_viewed,
    MAX(has_cart) AS ever_carted,
    MAX(has_purchase) AS ever_purchased,
    MAX(has_remove) AS ever_removed
FROM funnel_analysis_results
GROUP BY user_id;

-- 4. 유저별 RFM 스코어 및 고객 등급 매핑
CREATE TABLE user_rfm_segment AS
SELECT 
    user_id,
    recency,
    frequency,
    monetary,
    total_rfm_score,
    CASE 
        WHEN total_rfm_score >= 12 THEN '1. VIP 고객 (Active)'
        WHEN total_rfm_score >= 8 AND total_rfm_score < 12 THEN '2. 우수 고객 (Loyal)'
        WHEN total_rfm_score >= 5 AND total_rfm_score < 8 THEN '3. 잠재 고객 (Potential)'
        ELSE '4. 이탈 우려/신규 고객 (Cold/New)'
    END AS crm_segment
FROM rfm_analysis_results;

-- 5. 개별 유저 프로필 마트 생성 (CRM User Profile Mart)
CREATE TABLE user_crm_profile AS
SELECT 
    c.user_id,
    c.first_month AS cohort_month,
    COALESCE(b.preferred_brand, 'None') AS preferred_brand,
    COALESCE(r.crm_segment, '4. 이탈 우려/신규 고객 (Cold/New)') AS crm_segment,
    COALESCE(r.monetary, 0.0) AS total_purchase_amount,
    COALESCE(r.frequency, 0) AS total_purchase_count,
    COALESCE(f.ever_viewed, 0) AS ever_viewed,
    COALESCE(f.ever_carted, 0) AS ever_carted,
    COALESCE(f.ever_purchased, 0) AS ever_purchased,
    COALESCE(f.ever_removed, 0) AS ever_removed
FROM user_cohort c
LEFT JOIN user_preferred_brand b ON c.user_id = b.user_id
LEFT JOIN user_rfm_segment r ON c.user_id = r.user_id
LEFT JOIN user_funnel_summary f ON c.user_id = f.user_id;

-- 6. 최종 CRM 분석 대시보드 마트 구축 (집계형 테이블 생성)
CREATE TABLE mart_crm_dashboard AS
SELECT 
    cohort_month,
    preferred_brand,
    crm_segment,
    
    -- 고객 볼륨 집계
    COUNT(DISTINCT user_id) AS total_customers,
    
    -- 매출 및 빈도 성과 집계
    SUM(total_purchase_amount) AS total_revenue,
    SUM(total_purchase_count) AS total_order_count,
    
    -- 유저 퍼널별 전수 집계 (view -> cart -> purchase 전환 모니터링용)
    SUM(ever_viewed) AS total_view_users,
    SUM(ever_carted) AS total_cart_users,
    SUM(ever_purchased) AS total_purchase_users,
    SUM(ever_removed) AS total_cart_removed_users,
    
    -- 구매 전환율(%)
    ROUND(SUM(ever_purchased) * 100.0 / NULLIF(COUNT(DISTINCT user_id), 0), 2) AS purchase_conversion_rate_pct,
    
    -- 인당 평균 구매 금액(ARPU)
    ROUND(SUM(total_purchase_amount) / NULLIF(COUNT(DISTINCT user_id), 0), 2) AS arpu

FROM user_crm_profile
GROUP BY 
    cohort_month,
    preferred_brand,
    crm_segment;
