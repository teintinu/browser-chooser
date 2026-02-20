#!/bin/bash

echo "🧹 Limpando arquivos gerados pelo build..."

# Remove o diretório de build do Swift Package Manager
if [ -d ".build" ]; then
    rm -rf .build
    echo "✓ Pasta .build removida"
fi

# Remove o bundle do app gerado
if [ -d "teintinu-browser-chooser.app" ]; then
    rm -rf teintinu-browser-chooser.app
    echo "✓ Aplicativo .app removido"
fi

echo "✨ Limpeza concluída!"
