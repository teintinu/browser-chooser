#!/bin/bash

# Este script assume que você criou um projeto no Xcode chamado teintinu-browser-chooser
# e adicionou todos os arquivos .swift e o Info.plist a ele.

PROJECT_NAME="teintinu-browser-chooser"
SCHEME_NAME="teintinu-browser-chooser"

echo "🔨 Fechando $PROJECT_NAME..."
pkill teintinu-browser-chooser || true

echo "🔨 Iniciando build do $PROJECT_NAME..."

# Usa o Swift Package Manager para compilar
swift build -c release

if [ $? -eq 0 ]; then
    echo "✅ Build do binário concluído!"
    
    # Criar estrutura do .app
    APP_BUNDLE="teintinu-browser-chooser.app"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    
    # Copiar o binário para dentro do bundle
    cp ".build/release/teintinu-browser-chooser" "$APP_BUNDLE/Contents/MacOS/"
    chmod +x "$APP_BUNDLE/Contents/MacOS/teintinu-browser-chooser"
    
    # Copiar o Info.plist
    cp "Info.plist" "$APP_BUNDLE/Contents/"
    
    # Criar PkgInfo (necessário para alguns serviços do macOS)
    echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"
    
    # Instalar na pasta de aplicativos do usuário para garantir indexação do macOS
    USER_APPS="$HOME/Applications"
    mkdir -p "$USER_APPS"
    
    echo "🚚 Instalando em $USER_APPS..."
    rm -rf "$USER_APPS/$APP_BUNDLE"
    cp -R "$APP_BUNDLE" "$USER_APPS/"
    
    echo "🔄 Registrando aplicativo no sistema (Launch Services)..."
    LSR="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
    # -f força o registro, -u desregistra antes se necessário
    $LSR -f -u "$USER_APPS/$APP_BUNDLE"
    $LSR -v -f "$USER_APPS/$APP_BUNDLE"
    
    echo "🚀 Aplicativo instalado em: $USER_APPS/$APP_BUNDLE"
    echo "Você já pode abrir o app com: open \"$USER_APPS/$APP_BUNDLE\""
else
    echo "❌ Erro durante o build."
fi
