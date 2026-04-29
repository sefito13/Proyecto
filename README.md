# Setup PostgreSQL — Proyecto Análisis Redes Sociales

## Estructura de archivos

```
proyecto/
├── .env                      ← credenciales reales
├── .gitignore
├── docker-compose.yml        ← levanta PostgreSQL
├── requirements.txt          ← dependencias Python
├── ETL.py                    ← limpieza y carga del CSV
├── init/
│   └── 01_create_tables.sql  ← crea las 7 tablas automáticamente
└── instagram_users_lifestyle.csv  ← dataset
```

---

## Paso 1 — Configurar credenciales

Edita el `.env` y completa los valores:

```
POSTGRES_USER=admin
POSTGRES_PASSWORD=tu_contraseña_segura
POSTGRES_DB=proyectdb
POSTGRES_HOST=localhost
POSTGRES_PORT=5433
CSV_PATH=instagram_users_lifestyle.csv
```

---

## Paso 2 — Levantar el contenedor

```bash
docker-compose up -d
```

---

### 3. Crear entorno virtual e instalar dependencias

```bash
python -m venv venv

venv\Scripts\activate

pip install -r requirements.txt
```

### 4. Levantar PostgreSQL con Docker

```bash
docker-compose up -d
```

El script `init/01_create_tables.sql` crea las 7 tablas automáticamente al iniciar el contenedor.

Verifica que esté listo:

```bash
docker-compose ps

```
### 5. Cargar el dataset

Coloca el archivo `instagram_users_lifestyle.csv` en la raíz del proyecto y ejecuta:

```bash
python ETL.py
```

El script:
1. Lee las credenciales desde `.env`
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

# Detener contenedor (conserva los datos)
docker-compose down

# Detener y eliminar todos los datos
docker-compose down -v
```
