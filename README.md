# Mesa RPG

Mesa de RPG com **mapa quadriculado e tokens** feita para rodar num **iPad antigo com iOS 8** (testado num iPad 3, A5X, iOS 8.4.1). Pensada para Cyberpunk RED, mas serve para qualquer sistema com grid.

App nativo em Objective-C/UIKit, sem storyboard, compilado para **armv7** com o toolchain do Xcode 13.4.1 rodando no macOS atual.

## Funcionalidades

- Mapa importado das Fotos ou da pasta Documentos do app (compartilhamento de arquivos pelo Finder ou SSH); reduzido para no máx. 3072 px
- Zoom e arrasto com dois dedos; um dedo fica para tokens e régua
- Grid sobreposto (para mapas sem grid desenhado): tamanho, deslocamento, opacidade e metros por quadrado (padrão 2 m)
- Tokens com nome, rótulo, cor, tamanho 1×1 a 3×3, PV (amarelo abaixo da metade, vermelho em 0) e estado "caído"
- Arrastar um token mostra a distância percorrida; arrastar na área vazia vira régua (diagonal conta como 1 quadrado)
- Iniciativa: ordem arrastável, turno atual destacado, contador de rodadas, pula quem está caído
- Várias cenas, cada uma com seu mapa e tokens; tudo salvo automaticamente

## Requisitos

- iPad com iOS 8 e jailbreak, com **AppSync Unified** instalado (o app é assinado ad-hoc)
- Mac com o **Xcode 13.4.1** extraído (só o toolchain é usado; não precisa abrir o app). Versões mais novas do Xcode não geram armv7.
- `ldid` (`brew install ldid`) — opcional, mas recomendado
- `ideviceinstaller` para instalar pelo cabo (o da [Legacy iOS Kit](https://github.com/LukeZGD/Legacy-iOS-Kit) serve)

## Compilar e instalar

```bash
# Por padrão o script procura ../Xcode-13.4.1.app; ou aponte com X13:
export X13=/caminho/para/Xcode-13.4.1.app/Contents/Developer

./build.sh            # gera Tabletop.ipa
./build.sh install    # gera e instala no iPad conectado
```

## Mapas

O iOS 8 não abre WebP: converta os mapas para JPG ou PNG antes de copiar. Para levar ao iPad, use o Finder (iPad → aba Arquivos → arraste para "Mesa RPG") e depois **Mapa → Arquivos do app**.

### Grid automático pelo nome do arquivo

Se o nome do arquivo tiver `quadrado <N>px (<M> m)`, o app configura o grid sozinho ao carregar o mapa pela opção **Arquivos do app**:

```
Netrunner Cafe - quadrado 128px (2 m).jpg   → quadrado de 128 px, 2 m por quadrado
Mapa da loja - quadrado 70px.png            → quadrado de 70 px (metros não mudam)
```

O tamanho é em pixels da imagem original (se o app reduzir a imagem, o grid acompanha). Se a cena ainda tiver nome padrão ("Cena 1"…), ela ganha o nome do mapa.

## Estrutura

```
src/TTModel.*              tokens, cenas e persistência
src/TTBoardView.*          mapa, grid, tokens e régua
src/TTMainViewController.* barra, painel de grid, iniciativa, menus
src/main.m                 AppDelegate
```
