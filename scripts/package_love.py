import os
import zipfile

def package_love():
    source_dir = 'client'
    output_file = 'make/build/sector07.love'

    if not os.path.exists('make/build'):
        os.makedirs('make/build')
        
    print(f"📦 Packaging {source_dir} into {output_file}...")
    
    with zipfile.ZipFile(output_file, 'w', zipfile.ZIP_DEFLATED) as love_zip:
        for root, dirs, files in os.walk(source_dir):
            for file in files:
                # .DS_Store나 불필요한 파일 제외
                if file == '.DS_Store' or file.endswith('.db-journal'):
                    continue
                
                file_path = os.path.join(root, file)
                arcname = os.path.relpath(file_path, source_dir)
                love_zip.write(file_path, arcname)
                
    print(f"✨ Successfully created {output_file}")

if __name__ == "__main__":
    package_love()
