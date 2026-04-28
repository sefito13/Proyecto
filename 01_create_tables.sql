-- ============================================================
-- Proyecto: Análisis de usuarios en redes sociales
-- Dataset:  instagram_users_lifestyle.csv (1,547,896 registros)
-- Modelo:   Relacional - 7 tablas + restricciones
-- ============================================================
-- Corre dentro de una transacción: si algo falla no se crea
-- ninguna tabla (todo o nada).
-- ============================================================

BEGIN;

-- ============================================================
-- 1. TABLA PRINCIPAL: Users (datos demográficos)
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    user_id                 INTEGER         PRIMARY KEY,
    age                     INTEGER         NOT NULL CHECK (age BETWEEN 13 AND 65),
    gender                  VARCHAR(20)     NOT NULL,
    country                 VARCHAR(60)     NOT NULL,
    urban_rural             VARCHAR(10)     NOT NULL CHECK (urban_rural IN ('Urban', 'Rural', 'Suburban')),
    income_level            VARCHAR(15)     NOT NULL CHECK (income_level IN ('Low', 'Medium', 'High')),
    employment_status       VARCHAR(20)     NOT NULL,
    education_level         VARCHAR(30)     NOT NULL,
    relationship_status     VARCHAR(20)     NOT NULL,
    has_children            BOOLEAN         NOT NULL,
    account_creation_year   INTEGER         NOT NULL CHECK (account_creation_year BETWEEN 2000 AND 2026),
    last_login_date         DATE            NOT NULL,
    subscription_status     VARCHAR(15)     NOT NULL CHECK (subscription_status IN ('Free', 'Premium', 'Business'))
);

-- ============================================================
-- 2. AppUsage (uso de la aplicación)
--    NOTA: app_name excluido — valor constante "Instagram"
-- ============================================================
CREATE TABLE IF NOT EXISTS app_usage (
    id                              SERIAL          PRIMARY KEY,
    user_id                         INTEGER         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    daily_active_minutes_instagram  INTEGER         NOT NULL CHECK (daily_active_minutes_instagram >= 0),
    sessions_per_day                INTEGER         NOT NULL CHECK (sessions_per_day >= 0),
    posts_created_per_week          INTEGER         NOT NULL CHECK (posts_created_per_week >= 0),
    reels_watched_per_day           INTEGER         NOT NULL CHECK (reels_watched_per_day >= 0),
    stories_viewed_per_day          INTEGER         NOT NULL CHECK (stories_viewed_per_day >= 0),
    likes_given_per_day             INTEGER         NOT NULL CHECK (likes_given_per_day >= 0),
    comments_written_per_day        INTEGER         NOT NULL CHECK (comments_written_per_day >= 0),
    dms_sent_per_week               INTEGER         NOT NULL CHECK (dms_sent_per_week >= 0),
    dms_received_per_week           INTEGER         NOT NULL CHECK (dms_received_per_week >= 0)
);

-- ============================================================
-- 3. HealthLifestyle (salud y estilo de vida)
--    NOTA: weekly_work_hours agregada (columna extra del CSV)
-- ============================================================
CREATE TABLE IF NOT EXISTS health_lifestyle (
    id                          SERIAL          PRIMARY KEY,
    user_id                     INTEGER         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    exercise_hours_per_week     NUMERIC(4,1)    NOT NULL CHECK (exercise_hours_per_week >= 0),
    sleep_hours_per_night       NUMERIC(3,1)    NOT NULL CHECK (sleep_hours_per_night BETWEEN 0 AND 24),
    diet_quality                VARCHAR(10)     NOT NULL CHECK (diet_quality IN ('Poor', 'Fair', 'Good', 'Excellent')),
    smoking                     BOOLEAN         NOT NULL,
    alcohol_frequency           VARCHAR(20)     NOT NULL,
    perceived_stress_score      INTEGER         NOT NULL CHECK (perceived_stress_score BETWEEN 1 AND 10),
    self_reported_happiness     INTEGER         NOT NULL CHECK (self_reported_happiness BETWEEN 1 AND 10),
    body_mass_index             NUMERIC(4,1)    NOT NULL CHECK (body_mass_index BETWEEN 15 AND 45),
    blood_pressure_systolic     INTEGER         NOT NULL CHECK (blood_pressure_systolic > 0),
    blood_pressure_diastolic    INTEGER         NOT NULL CHECK (blood_pressure_diastolic > 0),
    daily_steps_count           INTEGER         NOT NULL CHECK (daily_steps_count >= 0),
    weekly_work_hours           NUMERIC(4,1)    NOT NULL CHECK (weekly_work_hours >= 0)
);

-- ============================================================
-- 4. SocialActivity (actividad social fuera de la app)
-- ============================================================
CREATE TABLE IF NOT EXISTS social_activity (
    id                          SERIAL      PRIMARY KEY,
    user_id                     INTEGER     NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    hobbies_count               INTEGER     NOT NULL CHECK (hobbies_count >= 0),
    social_events_per_month     INTEGER     NOT NULL CHECK (social_events_per_month >= 0),
    books_read_per_year         INTEGER     NOT NULL CHECK (books_read_per_year >= 0),
    volunteer_hours_per_month   INTEGER     NOT NULL CHECK (volunteer_hours_per_month >= 0),
    travel_frequency_per_year   INTEGER     NOT NULL CHECK (travel_frequency_per_year >= 0)
);

-- ============================================================
-- 5. TimeSpent (tiempo por sección de la app)
-- ============================================================
CREATE TABLE IF NOT EXISTS time_spent (
    id                              SERIAL          PRIMARY KEY,
    user_id                         INTEGER         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    time_on_feed_per_day            INTEGER         NOT NULL CHECK (time_on_feed_per_day >= 0),
    time_on_explore_per_day         INTEGER         NOT NULL CHECK (time_on_explore_per_day >= 0),
    time_on_messages_per_day        INTEGER         NOT NULL CHECK (time_on_messages_per_day >= 0),
    time_on_reels_per_day           INTEGER         NOT NULL CHECK (time_on_reels_per_day >= 0),
    average_session_length_minutes  NUMERIC(5,2)    NOT NULL CHECK (average_session_length_minutes >= 0)
);

-- ============================================================
-- 6. AdsInteraction (interacción con anuncios)
-- ============================================================
CREATE TABLE IF NOT EXISTS ads_interaction (
    id                  SERIAL      PRIMARY KEY,
    user_id             INTEGER     NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    ads_viewed_per_day  INTEGER     NOT NULL CHECK (ads_viewed_per_day >= 0),
    ads_clicked_per_day INTEGER     NOT NULL CHECK (ads_clicked_per_day >= 0)
);

-- ============================================================
-- 7. AccountSettings (configuración y métricas de la cuenta)
-- ============================================================
CREATE TABLE IF NOT EXISTS account_settings (
    id                          SERIAL          PRIMARY KEY,
    user_id                     INTEGER         NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    followers_count             INTEGER         NOT NULL CHECK (followers_count >= 0),
    following_count             INTEGER         NOT NULL CHECK (following_count >= 0),
    uses_premium_features       BOOLEAN         NOT NULL,
    notification_response_rate  NUMERIC(4,3)    NOT NULL CHECK (notification_response_rate BETWEEN 0 AND 1),
    content_type_preference     VARCHAR(20)     NOT NULL,
    preferred_content_theme     VARCHAR(30)     NOT NULL,
    privacy_setting_level       VARCHAR(10)     NOT NULL CHECK (privacy_setting_level IN ('Low', 'Medium', 'High')),
    two_factor_auth_enabled     BOOLEAN         NOT NULL,
    biometric_login_used        BOOLEAN         NOT NULL,
    linked_accounts_count       INTEGER         NOT NULL CHECK (linked_accounts_count >= 0),
    user_engagement_score       NUMERIC(5,2)    NOT NULL CHECK (user_engagement_score BETWEEN 0 AND 100)
);

-- ============================================================
-- ÍNDICES simples — filtros frecuentes en users
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_users_country       ON users(country);
CREATE INDEX IF NOT EXISTS idx_users_gender        ON users(gender);
CREATE INDEX IF NOT EXISTS idx_users_subscription  ON users(subscription_status);
CREATE INDEX IF NOT EXISTS idx_users_urban_rural   ON users(urban_rural);
CREATE INDEX IF NOT EXISTS idx_users_age           ON users(age);
CREATE INDEX IF NOT EXISTS idx_users_income        ON users(income_level);

-- ============================================================
-- ÍNDICES compuestos — cruces analíticos frecuentes
-- (más útiles que índices simples sobre FK en relaciones 1:1)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_health_stress_sleep
    ON health_lifestyle(user_id, perceived_stress_score, sleep_hours_per_night);

CREATE INDEX IF NOT EXISTS idx_health_happiness_bmi
    ON health_lifestyle(user_id, self_reported_happiness, body_mass_index);

CREATE INDEX IF NOT EXISTS idx_appusage_minutes_sessions
    ON app_usage(user_id, daily_active_minutes_instagram, sessions_per_day);

CREATE INDEX IF NOT EXISTS idx_account_engagement
    ON account_settings(user_id, user_engagement_score);

CREATE INDEX IF NOT EXISTS idx_ads_clicked
    ON ads_interaction(user_id, ads_clicked_per_day, ads_viewed_per_day);

COMMIT;
