---
title: "외산 CSP(AWS·Azure·GCP)의 공공 시장 제약"
type: comparison
tags: [aws, 외산csp, 규제, 비교]
status: active
confidence: medium
created: 2026-05-21
updated: 2026-05-21
sources: [raw/2026-05-20_perplexity-csap-overview.md, raw/2026-05-21_perplexity-nhn-isms-detail.md]
---

# 외산 CSP(AWS·Azure·GCP)의 공공 시장 제약

OfficeAgent는 현재 **AWS에서 운영 중**이다. 그러나 정부기관 납품에는 AWS만으로 충족 불가한 규제가 있어 [[nhn-cloud|NHN Cloud]]·[[on-premise|오픈스택]] 지원이 필요하다. 이 페이지는 "왜 AWS만으로는 안 되는가"를 정리한다.

## 핵심 제약

| 제약 | 내용 |
|------|------|
| [[data-sovereignty|데이터 주권]] | 데이터 국내 보관·키 통제 요건. AWS 서울 리전이 있어도 공공 고도 시스템엔 제약 |
| [[network-isolation|물리적 망분리]] | [[csap]] 상·중등급의 물리적 망분리·국내 운영 요건 충족 곤란 |
| 국내 운영 조직 | CSAP은 국내 운영 인력·조직 요건 포함 |
| 거버넌스 | 국정원 보안 감독·검증 체계가 외산 CSP에 불리 |

## 등급별 진입 가능성

- **상·중등급 CSAP**: 직접 취득 사실상 불가
- **하등급 CSAP**: [[network-isolation|논리적 망분리]]만 요구 → AWS 등이 서울 리전 기반으로 진입 시도 중
- **간접 진입**: 국내 파트너 CSP를 통한 리셀러·전용 영역 형태로 일부 도입

## 정책 동향

2024년 12월 이후 [[csap|CSAP]] 대개편 논의에서 **외산 CSP 진입 완화**가 쟁점. 다만 [[policy-trends|2027년 국정원 신규 검증 제도]] 통합 방향이 외산 CSP에 어떻게 작용할지는 미확정.

## OfficeAgent 마이그레이션 설계 시사점

- AWS를 버리는 것이 아니다 — 일반 상용 고객용으로 AWS는 유지
- 정부·공공 고객용으로 [[nhn-cloud|NHN]]·[[on-premise|오픈스택]] 배포 환경을 **추가**로 지원
- 따라서 설계의 핵심은 "AWS-only / 공통 / NHN-only / 오픈스택-only" 영역을 분리하는 추상화 (ARCHITECTURE.md)
- "AWS가 왜 공공에 안 되는가"를 설계서에 1차 자료로 근거 제시하면 [[csap]]·[[data-sovereignty]] 이해도를 보여줄 수 있음

## 1차 자료

- CSAP 고시 (과기정통부)
- digitalmarket.kr — CSAP ↔ FedRAMP 비교
- 외산 CSP 규제 완화 논의 관련 보도
