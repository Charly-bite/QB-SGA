#!/bin/bash
# ============================================
# SGA Web Application - Linux/Mac Startup Script
# ============================================

echo ""
echo "======================================"
echo "  SGA Web Application"
echo "  Sistema Global Armonizado v1.0"
echo "======================================"
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python3 no encontrado. Por favor instale Python 3.10+"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d ".venv" ]; then
    echo "Creando entorno virtual..."
    python3 -m venv .venv
fi

# Activate virtual environment
source .venv/bin/activate

# Install/update dependencies
echo "Verificando dependencias..."
pip install -q -r requirements.txt

# Start the application
echo ""
echo "Iniciando servidor web..."
echo ""
echo "================================================"
echo "  Abra su navegador en: http://localhost:5000"
echo "  Credenciales: admin / admin123"
echo "================================================"
echo ""
echo "Presione Ctrl+C para detener el servidor"
echo ""

python app.py
