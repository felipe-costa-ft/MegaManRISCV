import sys
import os

try:
    from PIL import Image
except ImportError:
    print("A biblioteca Pillow não está instalada.")
    print("Por favor, instale usando o comando: pip install Pillow")
    sys.exit(1)

# ==============================================================================
# CONFIGURAÇÃO DOS RECORTES
# Formato: "nome_do_sprite": (posição_X, posição_Y, largura, altura)
# Você precisará olhar a imagem original e colocar as coordenadas de cada frame aqui!
# ==============================================================================
SPRITES = {
    "idle": (1, 21, 24, 24), # Substitua o 'x' e 'y' pelas coordenadas do topo esquerdo do Mega Man parado
    "run1": (87, 21, 24, 24),
    "run2": (120, 21, 24, 24),
    "run3": (145, 21, 24, 24),
    "jump": (174, 12, 24, 24)
}

# Como você moveu o script para dentro da pasta megaman, as rotas mudaram!
import os
DIRETORIO_ATUAL = os.path.dirname(os.path.abspath(__file__))
ARQUIVO_ORIGEM = os.path.join(DIRETORIO_ATUAL, "megaman", "spritemegaman.png")
PASTA_DESTINO = os.path.join(DIRETORIO_ATUAL, "megaman")

def rgba_para_hex(r, g, b, a=255):
    # Converte a cor para o formato de 32 bits (0x00RRGGBB) que o RISC-V usa.
    # Se o pixel for transparente (Alpha = 0), vamos pintar de Magenta (0x00FF00FF).
    # O Magenta servirá como nossa "cor transparente" no Assembly depois.
    if a < 128:
        return "0x00FF00FF"
    return f"0x00{r:02X}{g:02X}{b:02X}"

def main():
    print(f"Abrindo a imagem: {ARQUIVO_ORIGEM}")
    try:
        img = Image.open(ARQUIVO_ORIGEM).convert("RGBA")
    except Exception as e:
        print(f"Erro ao abrir a imagem: {e}")
        return

    # Cria a pasta de destino se não existir
    if not os.path.exists(PASTA_DESTINO):
        os.makedirs(PASTA_DESTINO)

    if not SPRITES:
        print("\n[!] Atenção: Você precisa editar este arquivo (recortar_sprites.py) e colocar as coordenadas X, Y, Largura e Altura no dicionário 'SPRITES'!")
        return

    for nome, (x, y, largura, altura) in SPRITES.items():
        print(f"Recortando '{nome}' ({largura}x{altura}) na posição ({x}, {y})...")
        
        # Faz o recorte: (esquerda, topo, direita, baixo)
        area_recorte = (x, y, x + largura, y + altura)
        img_recortada = img.crop(area_recorte)
        pixels = img_recortada.load()

        # Nome do arquivo final (ex: idle.data)
        arquivo_saida = os.path.join(PASTA_DESTINO, f"{nome}.data")
        
        with open(arquivo_saida, "w", encoding="utf-8") as f:
            f.write(f"# Sprite gerado automaticamente: {nome}\n")
            f.write(f".data\n")
            f.write(f".align 2\n")
            f.write(f"{nome}_sprite:\n")
            
            # A função PRINT no render.asm espera a largura em bytes (pixels * 4) e altura em linhas
            f.write(f"    .word {largura * 4}    # Largura em bytes\n")
            f.write(f"    .word {altura}       # Altura em pixels (linhas)\n")
            
            # Escreve os pixels linha por linha
            for py in range(altura):
                f.write("    .word ")
                linha_pixels = []
                for px in range(largura):
                    r, g, b, a = pixels[px, py]
                    linha_pixels.append(rgba_para_hex(r, g, b, a))
                
                # Junta os pixels com vírgula e escreve a linha
                f.write(", ".join(linha_pixels))
                f.write("\n")
                
        print(f" -> Salvo com sucesso: {arquivo_saida}")

if __name__ == "__main__":
    main()
