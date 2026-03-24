from transformers import AutoProcessor, MusicgenForConditionalGeneration
import torch

print("⏳ facebook/musicgen-small 모델 다운로드 및 로드 테스트 시작...")

try:
    # 프로세서 다운로드/로드
    processor = AutoProcessor.from_pretrained("facebook/musicgen-small")
    print("✅ 프로세서 로드 성공!")

    # 모델 다운로드/로드
    model = MusicgenForConditionalGeneration.from_pretrained("facebook/musicgen-small")
    print("✅ 모델 가중치(Weights) 다운로드 및 로드 성공!")
    
    # 더미 데이터로 테스트 생성
    inputs = processor(text=["test prompt"], padding=True, return_tensors="pt")
    with torch.no_grad():
        output = model.generate(**inputs, max_new_tokens=10)
    print("✅ 오디오 토큰 생성 테스트까지 완벽하게 성공했습니다!")

except Exception as e:
    print(f"❌ 다운로드 또는 로드 중 에러 발생:\n{e}")