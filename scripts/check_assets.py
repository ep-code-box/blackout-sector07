import os
import json
import re

# Lua 파일을 읽어서 테이블을 파이썬 딕셔너리로 대략적으로 파싱 (단순 문자열 매칭)
def check_files():
    images_dir = "client/assets/images/"
    mercs_file = "client/data/data_mercs.lua"
    enemy_file = "client/data/data_enemy.lua"
    
    missing_count = 0
    
    print("--- Mercenary Assets Check ---")
    with open(mercs_file, 'r', encoding='utf-8') as f:
        content = f.read()
        # sprite = "..." 패턴 추출
        sprites = re.findall(r'sprite\s*=\s*"([^"]+)"', content)
        names = re.findall(r'name\s*=\s*"([^"]+)"', content)
        
        for i, sprite in enumerate(sprites):
            name = names[i] if i < len(names) else "Unknown"
            # Full sprite check
            if not os.path.exists(os.path.join(images_dir, sprite)):
                print(f"❌ [MISSING] {name} SPRITE: {sprite}")
                missing_count += 1
            
            # Face sprite check
            face = sprite.replace(".png", "_face.png")
            if not os.path.exists(os.path.join(images_dir, face)):
                print(f"❌ [MISSING] {name} FACE: {face}")
                missing_count += 1

    print("\n--- Enemy Assets Check ---")
    with open(enemy_file, 'r', encoding='utf-8') as f:
        content = f.read()
        sprites = re.findall(r'sprite\s*=\s*"([^"]+)"', content)
        for sprite in sprites:
            if not os.path.exists(os.path.join(images_dir, sprite)):
                print(f"❌ [MISSING] ENEMY SPRITE: {sprite}")
                missing_count += 1

    if missing_count == 0:
        print("\n✨ All assets are correctly mapped and exist on disk!")
    else:
        print(f"\n⚠️ Found {missing_count} missing asset files.")

if __name__ == "__main__":
    check_files()
