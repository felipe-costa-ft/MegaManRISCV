# MegaManRISCV


[Sprites](https://www.spriters-resource.com/nes/mm2/) 

[Jogo](https://playclassic.games/games/platform-nes-games-online/mega-man-2/play/)

[Músicas](https://www.khinsider.com/midi/nes/mega-man-2)

[Repositório Lamar](https://github.com/victorlisboa/LAMAR)


**Requisitos:**
1) (0,5) Música e efeitos sonoros.
2) (0,5) Ataque base do jogador.
3) (1,0) Movimentação e animação do personagem jogável.
4) (1,5) Mínimo de 2 habilidades do Mega Man, permitindo que ele troque entre elas, impactando no
combate e/ou na movimentação.
5) (0,5) Informações sobre a vida e carga das habilidades do Mega Man.
6) (0,5) Itens coletáveis de cura e de recarga das habilidades.
7) (1,0) Pelo menos 2 áreas distintas, isto é, dois ambientes de estilos diferentes, separados por uma porta.
8) (1,5) Mínimo de 3 tipos de inimigos com IAs diferentes (número de inimigos em aberto), sendo um deles
um chefão.
9) (1,0) Background móvel que acompanhe o movimento do Mega Man (horizontal ou vertical)


[OAC_Projeto_2026_1.pdf](https://github.com/user-attachments/files/28319086/OAC_Projeto_2026_1.pdf)


# Organização do Projeto

O projeto está sendo organizado em uma arquitetura de três camadas:

- **Game**: fluxo principal do jogo.
- **Entidades**: objetos do jogo, como player, inimigos e coletáveis.
- **Engine**: sistemas reutilizáveis, como renderização, input, física, câmera e animação.

A ideia é manter `main.s` pequeno e legível. Ele coordena o frame do jogo, mas não deve concentrar regras específicas de movimento, colisão, renderização de entidade ou animação.

```
MegaManRISCV/
├── main.s               ← Entrada atual do jogo e loop principal
├── main.asm             ← Versão antiga usada como referência
├── consts.s             ← Constantes compartilhadas
├── utils.s              ← Rotinas utilitárias gerais
├── engine/              ← Sistemas reutilizáveis da engine
├── entities/            ← Código das entidades do jogo
├── assets/              ← Sprites, tilesets, mapas e outros dados
└── exemplos/            ← Exemplos isolados de assembly
```

## Camadas

### Game

Fica principalmente em `main.s`.

Responsabilidades:

- inicializar o jogo;
- executar o loop principal;
- ler input;
- atualizar entidades e sistemas;
- renderizar o frame;
- apresentar e alternar o framebuffer.

O fluxo geral é:

```asm
GAME_LOOP:
        call READ_INPUT
        call UPDATE_GAME
        call RENDER_FRAME
        call PRESENT_FRAME
        call SWAP_FRAMEBUFFER
        call WAIT_FRAME
        j GAME_LOOP
```

### Entidades

Ficam em `entities/`.

Atualmente, a entidade principal é:

- `entities/player.s`: estado, input, física aplicada, máquina de estados, animação e renderização do player.

Entidades devem expor rotinas de alto nível, como `PLAYER_SETUP`, `PLAYER_UPDATE` e `PLAYER_RENDER`. Quem usa a entidade não deve precisar conhecer os detalhes internos da física ou da animação dela.

### Engine

Fica em `engine/`.

Arquivos principais:

- `engine/render.s`: renderização de tiles, imagens e entidades;
- `engine/input.s`: leitura e estado dos botões;
- `engine/physics.s`: colisão e física baseada no mapa;
- `engine/camera.s`: posição da câmera e scroll;
- `engine/animation.s`: helpers genéricos de animação.

A engine deve conter rotinas reutilizáveis, evitando depender diretamente de uma entidade específica quando isso não for necessário.

## Organização de Assets

```
assets/
├── maps/                ← Mapas exportados pelo editor
├── sprites/             ← Sprites das entidades
└── tileset/             ← Tileset visual e dados convertidos
```

Os arquivos em `assets/maps/` são gerados pelo tilemap editor. Em geral, eles não devem ser editados manualmente.

O padrão atual de mapa separa:

- `*_defs.s`: dimensões e constantes do mapa;
- `*_visual.s`: camada visual;
- `*_colisao.s`: camada de colisão;
- `*_entidades.s`: entidades agrupadas por tipo;
- `*_tileset_offsets.s`: offsets do tileset usado pelo render.

## Convenções de Código

- Rotinas e variáveis relacionadas a uma entidade começam com o nome da entidade.
  Exemplo: `PLAYER_SETUP`, `PLAYER_UPDATE`, `PLAYER_POSITION`.
- Rotinas de engine usam o prefixo do sistema.
  Exemplo: `PHYSICS_`, `RENDER_`, `CAMERA_`, `ANIMATION_`, `INPUT_`.
- Labels internas de uma rotina usam `_` no começo e mantêm o prefixo do contexto.
  Exemplo: `_PLAYER_UPDATE_STATE_AIR`, `_PHYSICS_RESOLVE_VERTICAL_DONE`.
- Evitar `.globl` em arquivos incluídos com `.include`, a menos que seja realmente necessário.
- Cada rotina deve ter um comentário curto de contrato antes da label.
  O comentário deve dizer como usar a rotina: argumentos, retorno e estado global relevante quando importar.
- Constantes compartilhadas ficam em `consts.s`.
- Constantes muito específicas de uma entidade podem ficar junto da entidade quando fizer sentido.
- A posição das entidades no mapa deve respeitar os dados exportados pelo editor.
- Direção visual deve preferir flip horizontal no render em vez de duplicar sprites para esquerda e direita.

# Imagens / Sprites

Todos os arquivos `.data` convertidos de sprites ficam em `assets/`.

## Como converter sprites:

1. Recorte o sprite do sheet como PNG
2. **Largura DEVE ser múltiplo de 4** (ex: 16, 20, 24, 28, 32)
3. Use o conversor: https://github.com/ABMHub/png2oac
4. Coloque o `.data` na subpasta correta dentro de `assets/`

## Formato do .data gerado:

O conversor gera um arquivo com:
- Word 0: largura em pixels
- Word 1: altura em pixels  
- Restante: dados de cor, 1 word por pixel
