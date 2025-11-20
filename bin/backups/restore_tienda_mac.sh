#!/bin/bash

# Script de Restauración
DB_NAME="tienda_development"
DB_USER="diegoreyesolivares"
DB_HOST="localhost"
DB_PORT="5432"
BACKUP_DIR="$HOME/backups/postgres"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar que se proporcionó archivo
if [ -z "$1" ]; then
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}Script de Restauración${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "Uso: $0 <archivo_backup>"
    echo ""
    echo "Ejemplo:"
    echo "  $0 $BACKUP_DIR/tienda_development_backup_2025-11-14_18-49-12.sql.gz"
    echo ""
    echo -e "${YELLOW}Backups disponibles:${NC}"
    ls -lht "$BACKUP_DIR"/*.sql.gz 2>/dev/null | awk '{print "  " $9 " - " $5}'
    exit 1
fi

BACKUP_FILE="$1"

# Verificar que existe
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Error: El archivo no existe${NC}"
    exit 1
fi

echo -e "${BLUE}==========================================${NC}"
echo -e "${YELLOW}RESTAURACIÓN DE BASE DE DATOS${NC}"
echo -e "${BLUE}==========================================${NC}"
echo -e "${RED}⚠️  ADVERTENCIA:${NC}"
echo "   - Se eliminará la base de datos actual"
echo "   - Se restaurará desde: $(basename $BACKUP_FILE)"
echo ""
read -p "¿Continuar? (escribe 'SI'): " confirmacion

if [ "$confirmacion" != "SI" ]; then
    echo -e "${RED}❌ Cancelado${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}Restaurando...${NC}"

# Cerrar conexiones
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -c \
  "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$DB_NAME' AND pid <> pg_backend_pid();" > /dev/null 2>&1

# Eliminar BD
dropdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" 2>/dev/null

# Crear BD nueva
createdb -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME"

# Restaurar
gunzip -c "$BACKUP_FILE" | psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Restauración exitosa${NC}"
    echo ""
    osascript -e 'display notification "Base de datos restaurada" with title "Restore Completado"' 2>/dev/null
    exit 0
else
    echo -e "${RED}❌ Error en restauración${NC}"
    exit 1
fi