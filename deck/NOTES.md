# Deck NOTES — 발표자 노트 + 빌드 가이드

> [`slides.md`](./slides.md)는 Marp 호환 Markdown deck. GitHub에서 그대로 렌더링되고, Marp/Slidev로 PDF·HTML export 가능.

---

## 빌드 (사용자 환경)

### Marp CLI 방식 (가장 단순)

```bash
# 사전 설치 (Node.js 18+)
npm install -g @marp-team/marp-cli

# PDF 빌드
marp deck/slides.md --pdf --output deck/slides.pdf

# HTML (스피커 노트 포함)
marp deck/slides.md --html --output deck/slides.html

# 라이브 프리뷰
marp deck/slides.md --preview
```

### VS Code Marp 확장 (개발 중)

`marp-team.marp-vscode` 설치 → `slides.md` 열고 ctrl+shift+v 미리보기

### Slidev (선택)

```bash
npm i -g @slidev/cli
slidev deck/slides.md --port 3030
slidev export deck/slides.md --output deck/slides.pdf
```

---

## 슬라이드 구성 (총 약 24장)

| # | 슬라이드 | 분 (목표) |
|---|---------|---------:|
| 1 | 표지 | 0.5 |
| 2 | **표준 시작 질문 답 — 가장 큰 미해결 위험** | 2 |
| 3 | 과제 본질 + 평가 비중 | 1 |
| 4 | 시스템 컨텍스트 + 핵심 제약 | 1.5 |
| 5 | 깊이 도메인 선정 이유 | 1 |
| 6 | A-1 VPC↔NHN VPC | 2.5 |
| 7 | A-2 CSAP 5 zone 망분리 | 3 |
| 8 | A-3 IAM ★ 핵심 발견 | 3 |
| 9-10 | B-1 4h 무중단 이전 (sim 결과 포함) | 4 |
| 11 | B-2 S3→OBS sync | 2 |
| 12-13 | B-3 LLM 데이터 주권 ★ | 5 |
| 14 | 검증 산출물 시나리오 7개 | 2 |
| 15 | 추상화 4영역 + NHN-only 종속 | 2 |
| 16-20 | Q&A 5축 부록 (자료 참조용) | (Q&A 동안 펴서 봄) |
| 21 | 후속 과제 | 1 |
| 22 | Thank you | 0.5 |

**총 발표 시간**: 약 30분 (1~15 + 21~22). Q&A 30분은 부록(16~20) 참조.

---

## 발표 흐름 핵심

### 시작 5분 (가장 중요)
평가자 공통 질문: *"본인이 깊이 다룬 2개 도메인 중, 가장 큰 미해결 위험 1개와 근거를 먼저 말씀해 주세요"*
→ **슬라이드 2에서 즉시 답할 수 있도록 설계됨** (B-3 LLM 데이터 주권, 미국 §28의8 ④ 미확인)

### 본론 흐름
A-1 (가벼움) → A-2 (CSAP) → A-3 (★ 핵심 발견) → B-1 (4h) → B-2 (가벼움) → B-3 (★ 가장 무거움)

**무게 분배**: A-3 + B-1 + B-3 = 12분 (전체 발표의 40%). 나머지 18분에 다른 5개 박스 + 컨텍스트.

### 마무리 흐름
검증 7개 → 추상화 → 후속 → Thank you. 1차 자료 인용·NHN-only 종속을 마지막 한 번 더 환기.

---

## Q&A 30분 운영 가이드

| 시간 | 평가자 질문 축 | 답할 부록 슬라이드 |
|-----|--------------|-----------------|
| 0~6분 | 1축 의사결정 근거 | 16 |
| 6~12분 | 2축 대안 단점 + 설계 깨질 시나리오 | 17 |
| 12~18분 | 3축 1차 자료 출처 | 18 |
| 18~24분 | 4축 NHN-only 종속 | 19 |
| 24~30분 | 5축 학습 궤적 | 20 |

각 축에서 *"모르는 부분은 솔직히 인정"* + *"후속 검증 계획"* 즉답 — 본 deck 어디나 명시되어 있음.

---

## 발표 전 셀프 체크 (Day 5.5 시뮬레이션)

- [ ] 시작 2분 안에 B-3 LLM 데이터 주권 위험 명시 가능?
- [ ] A-3 IAM 핵심 발견 (Trust Policy 등가 없음 + Secret manifest)을 30초 이내로 설명 가능?
- [ ] B-1 4h 시뮬레이션 결과 표를 외워서 말할 수 있나? (50GB 172분 / 100GB 319분 / 100GB+200MBps 187분)
- [ ] 1차 자료 12건 중 5건 이상 즉답 가능? (RDS Backup and Restore / VPC console-guide / OBS S3 API guide / IAM QuickStart / 개보법 §28의8)
- [ ] *"설계가 깨질 시나리오 1개"* 즉답 — 미국 §28의8 ④ 미포함 + 100GB + NKS 미적용 3중

---

## 본 deck의 한계 (솔직히 명시)

- 다이어그램은 mermaid 텍스트 위주 — 발표 시 화이트보드 또는 별도 PNG export 필요
- 발표 스피커 노트 (`<!-- _class -->` 등 Marp 디렉티브 활용 가능) 미박제 — 시간 부족
- 실 발표 영상 리허설 미실시 (Day 5.5 권장)
