#!/bin/bash

# Tenta abrir o pacote .app instalado
APP_PATH="$HOME/Applications/teintinu-browser-chooser.app"

if [ -d "$APP_PATH" ]; then
    echo "🚀 Iniciando app..."
    open "$APP_PATH"
else
    echo "⚠️ Erro: $APP_PATH não encontrado. Execute ./build.sh primeiro."
fi
