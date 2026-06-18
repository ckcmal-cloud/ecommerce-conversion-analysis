-- 목적: 원본(nail_market)의 시간 데이터를 정제하고 타임존을 변환 유저 이벤트 기준 테이블 구축
-- 참고: 02_ecommerce_behavior_analysis.ipynb의 "데이터 로드" 전처리 파트

-- 1. 유저 이벤트 로그 정제 및 시간 변수 포맷팅
-- 파이썬 로직: Etc/GMT-3 타임존 변환 (UTC +3시간 오프셋 적용) 및 일자/월 변수 추출
CREATE TABLE user_event_table AS
SELECT 
    COALESCE(user_id, 'Unknown') AS user_id,
    COALESCE(user_session, 'Unknown') AS user_session,
    product_id,
    brand,
    COALESCE(event_type, 'view') AS event_type,
    CAST(COALESCE(price, 0.0) AS DECIMAL(18,2)) AS price,
    
    -- 타임존 변환: UTC 기준 시간을 현지 시간(Etc/GMT-3 = UTC+3)으로 보정
    -- PostgreSQL / DuckDB 표준 문법: AT TIME ZONE 사용
    CAST(event_time AT TIME ZONE 'UTC' AT TIME ZONE 'Etc/GMT-3' AS TIMESTAMP) AS event_time,
    
    -- event_date 생성 (DATE 형식)
    CAST(event_time AT TIME ZONE 'UTC' AT TIME ZONE 'Etc/GMT-3' AS DATE) AS event_date,
    
    -- event_month 생성 (월 단위 DATE_TRUNC)
    DATE_TRUNC('month', CAST(event_time AT TIME ZONE 'UTC' AT TIME ZONE 'Etc/GMT-3' AS TIMESTAMP)) AS event_month

FROM nail_market; -- 원천 이커머스 로그 테이블
