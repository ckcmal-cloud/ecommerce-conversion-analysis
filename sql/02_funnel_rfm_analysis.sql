-- 목적: 유저 식별자(user_id) 단위로 집계되는 1) 퍼널(Funnel) 지표, 2) 고객 행동 세분화를 위한 RFM 지표 동시 연산 테이블 구축
-- 참고: 02_ecommerce_behavior_analysis.ipynb의 "퍼널" 및 "RFM 세그멘테이션" 분석 로직


-- 01. 유저 및 세션 기준 퍼널(Funnel) 단계별 플래그 생성 : view -> cart -> purchase(구매) 흐름 분석
CREATE TABLE funnel_analysis_results AS
SELECT 
    user_id,
    user_session,
    
    -- 각 행동 유형별 고유 카운트 산출용 플래그
    MAX(CASE WHEN event_type = 'view' THEN 1 ELSE 0 END) AS has_view,
    MAX(CASE WHEN event_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
    MAX(CASE WHEN event_type = 'purchase' THEN 1 ELSE 0 END) AS has_purchase,
    
    -- 장바구니 이후 구매 전환 없이 이탈하거나 삭제한 흐름 추적 플래그
    MAX(CASE WHEN event_type = 'remove_from_cart' THEN 1 ELSE 0 END) AS has_remove
FROM user_event_table
GROUP BY user_id, user_session;


-- 02. 구매(purchase) 이력을 기반으로 한 유저별 RFM 지표 연산
CREATE TABLE rfm_analysis_results AS
WITH base_purchase AS (
    -- 정상적인 구매 건만 필터링하여 유저 단위로 집계
    SELECT 
        user_id,
        user_session,
        event_date,
        price
    FROM user_event_table
    WHERE event_type = 'purchase'
),
customer_rfm_raw AS (
    SELECT 
        user_id,
        
        -- Recency: 전체 관측 데이터의 마지막 구매일 + 1일 기준, 고객별 최근 구매일까지의 차이(일수)
        -- [설계 근거]
        --   Python 원본: current_date = df['event_time'].max() + pd.Timedelta(days=1)
        --                recency = (current_date - 고객별 max(event_time)).dt.days
        --   → 가장 최근 구매 유저의 Recency = 1 (0이 되지 않도록 +1일 보정)
    
        datediff(
            'day',
            MAX(event_date),
            (SELECT MAX(event_date) FROM user_event_table WHERE event_type = 'purchase')
                + INTERVAL '1 day'
        ) AS recency,  -- 타입: BIGINT (정수 일수, 최솟값 = 1)
        
        -- Frequency: 고객별 고유 구매 세션의 총 수 (구매 빈도)
        COUNT(DISTINCT user_session) AS frequency,
        
        -- Monetary: 고객별 총 매출 기여 금액
        SUM(price) AS monetary
    FROM base_purchase
    GROUP BY user_id
)
SELECT 
    user_id,
    recency,
    frequency,
    monetary,
    
    -- RFM 개별 스코어링 (NTILE 함수로 5분위수 점수 부여)
    -- 숫자가 클수록 우수고객 (Recency는 작을수록 최근 구매이므로 DESC, F/M은 클수록 우수이므로 ASC)
    NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
    NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
    NTILE(5) OVER (ORDER BY monetary ASC) AS m_score,
    
    -- 최종 세그먼트 스코어 계산 (R_Score + F_Score + M_Score)
    (
        NTILE(5) OVER (ORDER BY recency DESC) + 
        NTILE(5) OVER (ORDER BY frequency ASC) + 
        NTILE(5) OVER (ORDER BY monetary ASC)
    ) AS total_rfm_score

FROM customer_rfm_raw;
