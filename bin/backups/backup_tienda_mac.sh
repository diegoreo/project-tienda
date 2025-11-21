#!/bin/bash

################################################################################
# Script de Backup Automático para PostgreSQL
# Sistema POS - Tienda
################################################################################

# Detectar ubicación del proyecto
PROJECT_DIR="$HOME/tienda"

# Cargar variables de entorno desde .env si existe
if [ -f "$PROJECT_DIR/.env" ]; then
    # Exportar solo variables de BACKUP_*
    while IFS='=' read -r key value; do
        # Ignorar comentarios y líneas vacías
        if [[ ! "$key" =~ ^#.*$ ]] && [[ -n "$key" ]] && [[ "$key" =~ ^BACKUP_ ]]; then
            # Remover comillas del valor si existen
            value=$(echo "$value" | sed 's/^["'\'']\|["'\'']$//g')
            export "$key=$value"
        fi
    done < "$PROJECT_DIR/.env"
fi

# Configuración con valores por defecto
DB_NAME="${BACKUP_DB_NAME:-tienda_development}"
DB_USER="${BACKUP_DB_USER:-diegoreyesolivares}"
DB_HOST="${BACKUP_DB_HOST:-localhost}"
DB_PORT="${BACKUP_DB_PORT:-5432}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups/postgres}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-30}"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Crear directorio de backups
mkdir -p "$BACKUP_DIR"

# Fecha actual
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_${DATE}.sql"
BACKUP_FILE_GZ="${BACKUP_FILE}.gz"

# Inicio
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}Iniciando backup de PostgreSQL${NC}"
echo -e "${BLUE}==========================================${NC}"
echo "Fecha: $(date)"
echo "Base de datos: $DB_NAME"
echo "Usuario: $DB_USER"
echo ""

# Verificar PostgreSQL
if ! pg_isready -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: PostgreSQL no está corriendo${NC}"
    echo "Inicia PostgreSQL con: brew services start postgresql@14"
    exit 1
fi

# Realizar backup
echo -e "${YELLOW}Exportando base de datos...${NC}"

pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" \
  --format=plain \
  --no-owner \
  --no-acl \
  --verbose \
  "$DB_NAME" > "$BACKUP_FILE" 2>&1

# Verificar éxito
if [ $? -eq 0 ]; then
    # Comprimir
    echo -e "${YELLOW}Comprimiendo backup...${NC}"
    gzip "$BACKUP_FILE"
    
    BACKUP_SIZE=$(du -h "$BACKUP_FILE_GZ" | cut -f1)
    echo ""
    echo -e "${GREEN}✅ Backup completado exitosamente${NC}"
    echo -e "${GREEN}📦 Archivo: $BACKUP_FILE_GZ${NC}"
    echo -e "${GREEN}📊 Tamaño: $BACKUP_SIZE${NC}"
    
    # Limpiar backups antiguos
    echo ""
    echo -e "${YELLOW}Limpiando backups antiguos (> $RETENTION_DAYS días)...${NC}"
    find "$BACKUP_DIR" -name "${DB_NAME}_backup_*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete
    echo -e "${GREEN}✅ Limpieza completada${NC}"
    
    # Mostrar backups existentes
    echo ""
    echo -e "${BLUE}Backups disponibles (últimos 5):${NC}"
    ls -lht "$BACKUP_DIR/${DB_NAME}_backup_"*.sql.gz 2>/dev/null | head -5 | awk '{print "  " $9 " - " $5}'
    
    # Estadísticas
    TOTAL_BACKUPS=$(ls -1 "$BACKUP_DIR/${DB_NAME}_backup_"*.sql.gz 2>/dev/null | wc -l | tr -d ' ')
    TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo ""
    echo -e "${BLUE}Total de backups: ${NC}$TOTAL_BACKUPS"
    echo -e "${BLUE}Espacio usado: ${NC}$TOTAL_SIZE"
    
    # Éxito
    echo ""
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${GREEN}✅ Proceso de backup completado${NC}"
    echo -e "${BLUE}==========================================${NC}"
    
    # Notificación Mac
    osascript -e 'display notification "Base de datos respaldada exitosamente" with title "Backup Completado" sound name "Glass"' 2>/dev/null
    
    exit 0
else
    echo ""
    echo -e "${RED}❌ Error al realizar el backup${NC}"
    echo "Verifica los logs arriba para más detalles"
    
    # Limpiar archivos parciales
    rm -f "$BACKUP_FILE" "$BACKUP_FILE_GZ" 2>/dev/null
    
    # Notificación de error
    osascript -e 'display notification "Error al respaldar base de datos" with title "Backup Fallido" sound name "Basso"' 2>/dev/null
    
    exit 1
fi