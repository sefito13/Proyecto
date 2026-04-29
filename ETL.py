import os
import logging
import polars as pl
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError
from dotenv import load_dotenv

#Logging 
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler("carga.log", encoding="utf-8"),
    ],
)
log = logging.getLogger(__name__)


#Configuración desde .env
load_dotenv()

DB_USER = os.getenv("POSTGRES_USER")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD")
DB_HOST = os.getenv("POSTGRES_HOST", "localhost")
DB_PORT = os.getenv("POSTGRES_PORT", "5432")
DB_NAME = os.getenv("POSTGRES_DB")
CSV_PATH = os.getenv("CSV_PATH", "instagram_users_lifestyle.csv")


def validar_config() -> None:
    """Verifica que todas las variables de entorno estén definidas."""
    faltantes = [
        v
        for v, val in {
            "POSTGRES_USER": DB_USER,
            "POSTGRES_PASSWORD": DB_PASSWORD,
            "POSTGRES_DB": DB_NAME,
        }.items()
        if not val
    ]
    if faltantes:
        raise EnvironmentError(
            f"Faltan variables de entorno: {', '.join(faltantes)}. "
            "Crea el archivo .env a partir de .env.example"
        )


#Limpieza y transformación con Polars
def limpiar(df: pl.DataFrame) -> pl.DataFrame:
    """Aplica limpieza y normalización al dataset crudo usando Polars."""
    log.info("Iniciando limpieza...")

    if "app_name" in df.columns:
        df = df.drop("app_name")

    df = df.with_columns(
        pl.col("education_level").replace(
            {
                "Bachelor's": "Bachelor",
                "High school": "High School",
            }
        )
    )

    bool_cols = [
        "has_children",
        "smoking",
        "uses_premium_features",
        "two_factor_auth_enabled",
        "biometric_login_used",
    ]
    for col in bool_cols:
        if df[col].dtype == pl.Utf8:
            df = df.with_columns(
                pl.col(col)
                .str.to_lowercase()
                .map_elements(lambda v: v in ("true", "yes"), return_dtype=pl.Boolean)
            )

    if df["last_login_date"].dtype == pl.Utf8:
        df = df.with_columns(
            pl.col("last_login_date").str.to_date("%Y-%m-%d", strict=False)
        )

    nulos = df.null_count().sum_horizontal().sum()
    if nulos > 0:
        log.warning(
            f"Se encontraron {nulos} valores nulos tras la limpieza. Revisar dataset."
        )

    log.info(f"Limpieza completada — filas: {len(df):,} | columnas: {df.width}")
    return df


#Separar en tablas
def separar_tablas(df: pl.DataFrame) -> dict[str, pl.DataFrame]:
    """Divide el DataFrame en las 7 tablas del modelo relacional."""
    return {
        "users": df.select(
            [
                "user_id",
                "age",
                "gender",
                "country",
                "urban_rural",
                "income_level",
                "employment_status",
                "education_level",
                "relationship_status",
                "has_children",
                "account_creation_year",
                "last_login_date",
                "subscription_status",
            ]
        ),
        "app_usage": df.select(
            [
                "user_id",
                "daily_active_minutes_instagram",
                "sessions_per_day",
                "posts_created_per_week",
                "reels_watched_per_day",
                "stories_viewed_per_day",
                "likes_given_per_day",
                "comments_written_per_day",
                "dms_sent_per_week",
                "dms_received_per_week",
            ]
        ),
        "health_lifestyle": df.select(
            [
                "user_id",
                "exercise_hours_per_week",
                "sleep_hours_per_night",
                "diet_quality",
                "smoking",
                "alcohol_frequency",
                "perceived_stress_score",
                "self_reported_happiness",
                "body_mass_index",
                "blood_pressure_systolic",
                "blood_pressure_diastolic",
                "daily_steps_count",
                "weekly_work_hours",
            ]
        ),
        "social_activity": df.select(
            [
                "user_id",
                "hobbies_count",
                "social_events_per_month",
                "books_read_per_year",
                "volunteer_hours_per_month",
                "travel_frequency_per_year",
            ]
        ),
        "time_spent": df.select(
            [
                "user_id",
                "time_on_feed_per_day",
                "time_on_explore_per_day",
                "time_on_messages_per_day",
                "time_on_reels_per_day",
                "average_session_length_minutes",
            ]
        ),
        "ads_interaction": df.select(
            ["user_id", "ads_viewed_per_day", "ads_clicked_per_day"]
        ),
        "account_settings": df.select(
            [
                "user_id",
                "followers_count",
                "following_count",
                "uses_premium_features",
                "notification_response_rate",
                "content_type_preference",
                "preferred_content_theme",
                "privacy_setting_level",
                "two_factor_auth_enabled",
                "biometric_login_used",
                "linked_accounts_count",
                "user_engagement_score",
            ]
        ),
    }


#Carga a PostgreSQL
def cargar(tablas: dict[str, pl.DataFrame], engine) -> None:

    CHUNK_SIZE = 10_000

    orden = [
        "users",
        "app_usage",
        "health_lifestyle",
        "social_activity",
        "time_spent",
        "ads_interaction",
        "account_settings",
    ]

    for nombre in orden:
        df_tabla = tablas[nombre]
        total = len(df_tabla)
        log.info(
            f"Cargando '{nombre}' — {total:,} filas en chunks de {CHUNK_SIZE:,}..."
        )

        try:
            for inicio in range(0, total, CHUNK_SIZE):
                chunk = df_tabla.slice(inicio, CHUNK_SIZE)
                chunk.to_pandas().to_sql(
                    nombre, con=engine, if_exists="append", index=False, method="multi"
                )
            log.info(f"  ✓ '{nombre}' cargada correctamente.")

        except SQLAlchemyError as e:
            log.error(f"  ✗ Error al cargar '{nombre}': {e}")
            log.error("Proceso detenido. Verifica los datos y vuelve a intentarlo.")
            raise


#Verificación post-carga
def verificar(tablas: dict[str, pl.DataFrame], engine) -> None:
    """Confirma que el número de filas en BD coincide con el DataFrame."""
    log.info("Verificando conteos en la base de datos...")
    with engine.connect() as conn:
        for nombre, df_tabla in tablas.items():
            conteo_db = conn.execute(text(f"SELECT COUNT(*) FROM {nombre}")).scalar()
            conteo_df = len(df_tabla)
            estado = "✓" if conteo_db == conteo_df else "✗ DISCREPANCIA"
            log.info(
                f"  {estado} {nombre}: {conteo_db:,} en BD / {conteo_df:,} en DataFrame"
            )


#Main
if __name__ == "__main__":
    try:
        validar_config()

        log.info(f"Leyendo CSV con Polars: {CSV_PATH}")
        df_raw = pl.read_csv(CSV_PATH, infer_schema_length=10_000)
        log.info(f"Dataset cargado: {len(df_raw):,} filas x {df_raw.width} columnas")

        df_limpio = limpiar(df_raw)
        tablas = separar_tablas(df_limpio)

        engine_url = (
            f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}"
            f"@{DB_HOST}:{DB_PORT}/{DB_NAME}"
        )
        log.info(f"Conectando a PostgreSQL: {DB_HOST}:{DB_PORT}/{DB_NAME}")
        engine = create_engine(engine_url)

        cargar(tablas, engine)
        verificar(tablas, engine)

        log.info("✓ Proceso finalizado. Todas las tablas cargadas en PostgreSQL.")

    except EnvironmentError as e:
        log.error(f"Error de configuración: {e}")
    except FileNotFoundError:
        log.error(f"No se encontró el archivo CSV: {CSV_PATH}")
    except Exception as e:
        log.error(f"Error inesperado: {e}")
        raise