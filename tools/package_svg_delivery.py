"""Package the editable Godot project and approved SVG sources for delivery."""
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TARGET = ROOT / 'dist/Brisin_SVGs_e_Interacoes.zip'
REFERENCES = [
    'exec-d24d424c-04f7-41cb-9a46-cc76cb199712.png',
    'exec-d1fdcf1c-274d-4457-9a1a-2f8668f6d398.png',
    'exec-54a086db-33d8-4bf6-9fc3-26ebb47c10e4.png',
]
README = '''# Brisin — Conexão de Outro Mundo: SVGs e animações

Abra Brisin/godot/project.godot no Godot 4.5.1. O editor importa os recursos
automaticamente. O pacote inclui o projeto editável completo, SVGs, scripts,
manifests, testes e documentação.

Para gerar a versão web, entre em Brisin/ e use as instruções de README.md.
O carregador, manifesto WASM e verificadores estão incluídos; o helper baixa
o runtime compatível e reconstrói o PCK local. Os binários web gerados não
fazem parte deste ZIP editável.

A versão extraterrestre inclui nove Ruídozinhos coloridos com cinco estados,
menu sem frase de rodapé e todas as famílias de plataformas, objetos interativos e cenário/efeitos,
o panorama vetorial aprovado com atmosfera, menu e bandeiras animados,
dash/pulso opacos em SVG, chips SIM brancos (F / Y) com gesto de lançamento, dicas contextuais
e transição do portal de 1,8 s antes da conclusão.
Vento usa curvas e folhas; gemas laranja pulsam; coleta dispara anel, fragmentos
e faíscas. As animações de gameplay são controladas por GDScript.

Consulte Brisin/godot/docs/asset_integration.md para integração, validação e
limitações. Os documentos por família registram canvases, pivôs e tempos.
As variações disponíveis não são todas instanciadas na fase.

Os geradores em Brisin/tools exigem Python, Pillow e Inkscape para renderizar.
As referências mobile aprovadas ficam no repositório em tools/reference_art;
não são duplicadas neste ZIP para respeitar o limite de download.
As referências novas estão em Brisin/tools/reference_art/cosmic; a origem do novo fundo fica em
Brisin/tools/reference_art. Passe o caminho da prancha ao
gerador de plataformas/objetos, ou --source ao de cenário. Os PNGs de origem
servem para regeneração e não estão embutidos nos SVGs.
'''

def main():
    # Preserve references if repackaging the delivered archive in a new checkout.
    saved = {}
    if TARGET.exists() and zipfile.is_zipfile(TARGET):
        with zipfile.ZipFile(TARGET) as old:
            saved = {n: old.read(n) for n in old.namelist()
                     if n.startswith('Brisin/referencias/')}
    temporary = TARGET.with_suffix('.zip.tmp')
    with zipfile.ZipFile(temporary, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as out:
        out.writestr('LEIA-ME.md', README)
        out.write(ROOT / 'AGENTS.md', 'Brisin/AGENTS.md')
        out.write(ROOT / 'README.md', 'Brisin/README.md')
        out.write(ROOT / 'tools/requirements.txt', 'Brisin/tools/requirements.txt')
        for name in ['wasm-parts.json', 'verify-loader.cjs', '.gitignore']:
            out.write(ROOT / name, 'Brisin/' + name)
        for file in sorted((ROOT / 'dist').iterdir()):
            if file.is_file() and file.name != 'loading-bg.png' and file != temporary and file.suffix not in {'.zip', '.pck', '.wasm', '.part0', '.part1', '.part2'}:
                out.write(file, 'Brisin/dist/' + file.name)
        for file in sorted((ROOT / 'godot').rglob('*')):
            if not file.is_file():
                continue
            rel = file.relative_to(ROOT)
            if '.godot' in rel.parts or file.suffix == '.import' or ('qa' in rel.parts and file.suffix == '.png'):
                continue
            if 'cosmic_qa' in rel.parts:
                continue
            if file.name in {'background.png','background_mirror.png'} and rel.parts[:4] == ('godot','assets','world_01',file.name):
                continue
            if rel.parts[:4] == ('godot', 'assets', 'world_01', 'environment') and file.suffix == '.png':
                continue
            if rel.parts[:2] == ('godot', 'docs') and (file.suffix == '.png' or file.name == 'test_results.json'):
                continue
            out.write(file, 'Brisin/' + str(rel))
        for file in sorted((ROOT / 'tools').rglob('*')):
            if file.is_file() and file.suffix in {'.py', '.cjs', '.png', '.svg', '.gd'} and file.name not in {'approved-mobile-menu.png', 'approved-mobile-controls.png', 'approved-background.png', 'approved-checkpoint.png'}:
                out.write(file, 'Brisin/' + str(file.relative_to(ROOT)))
        for folder in ['docs', 'qa']:
            for file in sorted((ROOT / folder).rglob('*')):
                if file.is_file() and file.suffix in {'.md', '.svg', '.json'}:
                    out.write(file, 'Brisin/' + str(file.relative_to(ROOT)))
        for name in []: # The current cosmic references are included in tools/reference_art/cosmic.
            source = ROOT.parent / 'generated_images' / name
            if not source.exists():
                source = ROOT / 'referencias' / name
            key = 'Brisin/referencias/' + name
            if source.exists():
                out.write(source, key)
            elif key in saved:
                out.writestr(key, saved[key])
    with zipfile.ZipFile(temporary) as archive:
        assert archive.testzip() is None
        assert temporary.stat().st_size <= 26214400, 'Editable download exceeds hosting per-file limit'
        assert 'Brisin/godot/project.godot' in archive.namelist()
        for name in ['Brisin/wasm-parts.json', 'Brisin/verify-loader.cjs',
                     'Brisin/dist/index.html', 'Brisin/dist/index.js',
                     'Brisin/tools/bootstrap_web_runtime.py', 'Brisin/tools/export_web.py']:
            assert name in archive.namelist(), name
    temporary.replace(TARGET)
    print(f'Pacote íntegro: {TARGET.stat().st_size} bytes')

if __name__ == '__main__':
    main()
