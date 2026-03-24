import os

def check_files():
    images_dir = "client/assets/images/"
    
    # 8명의 용병 전용 에셋 리스트 (데이터와 대조)
    mercs = [
        "merc_01_luna.png",
        "merc_02_helena.png",
        "merc_03_mio.png",
        "merc_04_yui.png",
        "merc_05_nova.png",
        "merc_06_stella.png",
        "merc_07_kira.png",
        "merc_08_chloe.png"
    ]
    
    missing = []
    
    print("--- Detailed File Existence Check ---")
    for m in mercs:
        # 전신 스프라이트 확인
        full_path = os.path.join(images_dir, m)
        if not os.path.exists(full_path):
            missing.append(f"Full Sprite: {m}")
        
        # 얼굴 크롭 확인
        face_name = m.replace(".png", "_face.png")
        face_path = os.path.join(images_dir, face_name)
        if not os.path.exists(face_path):
            missing.append(f"Face Crop: {face_name}")
            
    if not missing:
        print("✨ All 8 mercenary full sprites and face crops EXIST!")
    else:
        print(f"⚠️ Found {len(missing)} missing files:")
        for miss in missing:
            print(f"  - {miss}")

if __name__ == "__main__":
    check_files()
