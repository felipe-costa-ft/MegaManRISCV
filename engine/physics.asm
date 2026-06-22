# ===========================================================================
# engine/physics.asm - Sistema de Física do Mega Man
# ===========================================================================
# Constantes e funções de física (gravidade, pulo, movimento)
# Será implementado na etapa 2 do projeto
# ===========================================================================

# ---------------------------------------------------------------------------
# Constantes de física
# ---------------------------------------------------------------------------
.eqv GRAVITY        1      # Aceleração gravitacional por frame
.eqv MAX_FALL_SPEED 8      # Velocidade máxima de queda (pixels/frame)
.eqv JUMP_FORCE     -10    # Força inicial do pulo (negativa = para cima)
.eqv WALK_SPEED     2      # Velocidade de caminhada (pixels/frame)
.eqv SCREEN_WIDTH   320    # Largura da tela em pixels
.eqv SCREEN_HEIGHT  240    # Altura da tela em pixels

.text

# ===========================================================================
# UPDATE_PLAYER_PHYSICS - Atualiza a física do jogador
# ===========================================================================
# Argumentos: (a serem definidos na etapa 2)
# Retorno: (a ser definido na etapa 2)
#
# TODO (Etapa 2): Implementar:
#   - Aplicar gravidade à velocidade vertical
#   - Limitar velocidade de queda a MAX_FALL_SPEED
#   - Aplicar força de pulo quando INPUT_JUMP estiver ativo
#   - Mover jogador horizontalmente com WALK_SPEED
#   - Verificar limites da tela (SCREEN_WIDTH, SCREEN_HEIGHT)
#   - Detecção de colisão com o chão e plataformas
# ===========================================================================
UPDATE_PLAYER_PHYSICS:
        ret                 # Stub - será implementado na etapa 2
