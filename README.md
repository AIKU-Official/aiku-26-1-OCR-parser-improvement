# aiku-26-1-OCR-parser-function-improvement
> 📢 **2026년 1학기 AIKU 활동으로 진행한 프로젝트입니다**

# OCR 기반 문서 구조 분석 파이프라인

## 소개

스캔 문서를 구조 정보가 보존된 편집 가능한 문서로 변환하는 OCR 기반 문서 처리 파이프라인입니다.

도서·보고서·오피스 문서 등 다양한 형태의 스캔 문서를 입력받아, 문서 내 텍스트·표·이미지 영역을 자동으로 구분하고 구조화된 JSON으로 변환합니다. 단순 텍스트 추출에 그치는 기존 OCR과 달리, 표의 셀 구조와 이미지 영역까지 보존하여 원본 문서의 레이아웃을 최대한 유지하는 데 중점을 둡니다.

이후, PaddleOCR 기반의 PDF 문서 분석 GUI 배포 bat 및 zip 패키지까지 제작했습니다.

## 실험 방법론

### 1. 베이스 모델: PPStructureV3

초기에는 독자적인 커스텀 레이아웃 분류 모델 개발을 계획했으나, PaddleOCR 기반 PPStructureV3의 높은 정확도를 확인하고 PPStructureV3를 baseline으로 채택 + 보조 CNN으로 재교정하는 파이프라인으로 전략을 전환했습니다

### 2. 2-pass OCR (CER 개선)

OCR 인식을 두 단계로 나눠 수행하는 구조입니다.

- **1차 패스**: PaddleOCR (`korean_PP-OCRv5_mobile_rec`)로 텍스트 영역 검출 및 인식
- **2차 패스**: 1차에서 얻은 bbox를 상하좌우로 N px 확장(padding)한 뒤 재인식

bbox가 글자에 너무 타이트하면 획·받침·기호가 잘려 인식 오류가 발생합니다. crop을 약간 넓혀주면 잘림이 줄어 인식률이 향상되며, 최적 padding 값으로 **pad4**를 선정했습니다. 단, 일반 문서에 일괄 적용하면 인접 텍스트·선이 유입되어 역효과가 나므로 gated 방식을 병행했습니다.

### 3. 3-class CNN (레이아웃 분류 보정)

PPStructureV3의 영역 검출 결과를 보정하기 위해, crop 이미지를 **text / table / image**로 분류하는 경량 분류 모델을 사용합니다.

**전처리 파이프라인** — 표 격자 및 미디어 특징 강조를 위한 3채널 전처리:

- **Ch 1 — Adaptive Threshold**: 일반 텍스트 라인과 표의 경계선 추출
- **Ch 2 — HSV Saturation (HSV-S)**: 유채색 다이어그램·이미지 vs 무채색 텍스트 구분
- **Ch 3 — Hough Line Transform**: 표 격자선의 직교 구조적 특징 극대화

**백본 비교**:

- **Basic CNN**: Adam optimizer, Focal Loss(γ=2.0), 3채널 전처리 적용
- **MobileNetV3-small**: depthwise separable convolution + SE 모듈, cosine LR scheduler, from-scratch 학습

최종 채택 모델: **MobileNetV3-small**

### 4. GUI 프로그램 (`program_file/`)

PPStructureV3 기반 PDF 문서 분석 GUI 애플리케이션입니다.

- **Layout + OCR 모드**: 문서 구조(표·그림·텍스트 영역) 분석 + 텍스트 인식
- **OCR only 모드**: Recognition 모델만 사용, 빠른 텍스트 추출
- 출력 형식 선택: JSON / Markdown / HTML / Excel
- GPU 가속 지원 (NVIDIA CUDA)

## 데이터셋

| 데이터셋 | 설명 |
| --- | --- |
| AIHub 오피스 문서 생성 데이터 | 뉴스기사·보도자료·발표자료 위주, PDF + JSON 형태 정밀 레이블 탑재 |
| DocLayNet Benchmark | IBM 공개 문서 레이아웃 분석 벤치마크. 7개 도메인, text / table / image 3개 클래스 위주 추출 |
| 금융업 특화 문서 OCR 데이터 | 인쇄 글씨와 손글씨가 혼합된 비정형 양식·스캔 문서 |
| 한국어 교과서 스캔본 | 업체 제공 교과서 PDF |

## 환경 설정

### 모델 학습 환경

```
Python 3.10
PaddleOCR >= 3.3.0
PaddlePaddle 3.3.0
```

### GUI 프로그램 실행 환경

- [Miniconda](https://docs.conda.io/en/latest/miniconda.html) 설치 필요
- GPU 사용 시: NVIDIA 드라이버 CUDA 12.6 이상

```bash
# 최초 1회 설치
install.bat

# 이후 실행
run.bat
```

## 사용 방법

### GUI 프로그램

1. `program_file/` 폴더의 `main.py`, `install.bat`, `run.bat` 다운로드
2. 같은 폴더에 세 파일 배치
3. `install.bat` 실행 (최초 1회, 약 10~20분 소요)
4. `run.bat` 더블클릭으로 앱 실행
5. PDF 파일 선택 → OCR 모드 선택 → 분석 시작

### 출력 결과

```
PDFStructureResults/
└── 파일명_날짜/
    ├── pages/            # 페이지 렌더링 이미지 + 바운딩박스 시각화
    ├── tables/           # 표 HTML + Excel
    ├── crops/            # 그림 크롭 이미지
    ├── result.json       # 전체 구조화 JSON
    └── 파일명_result.md  # 마크다운 결과
```

## 예시 결과

### 2-pass OCR 성능 (금융업 특화 서식, 300 pages / 115,809 crops)

| 조건 | CER | Exact Match |
| --- | --- | --- |
| pad0 (baseline) | 2.71% | 92.25% |
| **pad4** | **2.36%** | **93.14%** |

### MobileNetV3-small 3-class 분류 성능 (AIHub News+Report)

| 지표 | 값 |
| --- | --- |
| Test Accuracy | **98.42%** |
| Text F1 | 0.9952 |
| Table F1 | 0.8593 |
| Image F1 | 0.9705 |

### PPStructureV3 보정 효과 (AIHub News, PPStructure 예측 crop 2,863개)

| 방식 | Accuracy | Table F1 |
| --- | --- | --- |
| PPStructureV3 원본 (baseline) | **99.55%** | **0.9759** |
| MobileNetV3-small 보정 적용 | 98.11% | 0.8864 |

→ PPStructureV3가 이미 충분히 정확하여 보정 모델의 추가 개선 효과는 제한적이었습니다.

### GUI 패키지 실행 결과
<img width="561" height="448" alt="image" src="https://github.com/user-attachments/assets/63c4a2ed-9874-4179-a31f-dcae922bb1c6" />


## 팀원

| 이름 | 역할 |
| --- | --- |
| 최우재 (팀장) | 전체 OCR Parser 모델 설계 |
| 송성준 | 전체 OCR Parser 개발 |
| 임시은 | Windows 타겟 패키징 |
| 조수빈 | Windows 타겟 패키징 |
| 손혜강 | 자문 |
