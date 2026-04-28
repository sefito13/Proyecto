# Setup PostgreSQL — Proyecto Análisis Redes Sociales

## Estructura de archivos

```
proyecto/
├── .env                     ← credenciales reales (NO subir a Git)
├── .env.example             ← plantilla sin credenciales (sí subir a Git)
├── .gitignore               ← excluye .env y el CSV
├── docker-compose.yml       ← levanta PostgreSQL
├── cargar_datos.py          ← limpia y carga el CSV a PostgreSQL
├── init/
│   └── 01_create_tables.sql ← crea las 7 tablas automáticamente
└── instagram_users_lifestyle.csv
```

---

## Paso 1 — Configurar credenciales

```bash
cp .env.example .env
```

Edita el `.env` y completa los valores:

```
POSTGRES_USER=admin
POSTGRES_PASSWORD=tu_contraseña_segura
POSTGRES_DB=instagram_lifestyle
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
CSV_PATH=instagram_users_lifestyle.csv
```

---

## Paso 2 — Levantar el contenedor

```bash
docker-compose up -d
```

PostgreSQL arranca en `localhost:5432`.  
El script `init/01_create_tables.sql` crea las 7 tablas **automáticamente** dentro de una transacción.

---

## Paso 3 — Verificar que el contenedor está listo

```bash
docker-compose ps
```

Debe aparecer el estado `healthy` antes de continuar.

---

## Paso 4 — Instalar dependencias Python

```bash
pip install pandas sqlalchemy psycopg2-binary python-dotenv
```

---

## Paso 5 — Cargar el CSV

```bash
python cargar_datos.py
```

El script:
1. Lee las credenciales desde `.env` (nunca hardcodeadas)
2. Lee el CSV (1,547,896 filas)
3. Normaliza `education_level` y corrige columnas booleanas
4. Elimina `app_name` (valor constante)
5. Separa los datos en 7 tablas respetando el orden de FK
6. Carga en lotes de 10,000 filas con manejo de errores
7. Verifica que los conteos de filas coincidan
8. Genera un log en `carga.log`

---

## Comandos útiles

```bash
# Ver logs en tiempo real durante la carga
tail -f carga.log

# Conectarse a PostgreSQL dentro del contenedor
docker exec -it instagram_db psql -U admin -d instagram_lifestyle

# Verificar tablas creadas
\dt

# Detener contenedor (conserva los datos)
docker-compose down

# Detener y eliminar todos los datos
docker-compose down -v
```
