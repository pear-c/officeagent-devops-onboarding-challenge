---
title: "데이터 주권 — 국내 보관·국외 이전 제한"
type: policy
tags: [데이터주권, 개인정보, 규제, llm-api]
status: active
confidence: high
created: 2026-05-21
updated: 2026-05-21
sources: [raw/2026-05-20_perplexity-csap-overview.md, raw/2026-05-21_perplexity-nhn-isms-detail.md]
---

# 데이터 주권 — 국내 보관·국외 이전 제한

공공기관 클라우드 도입에서 가장 민감한 이슈. OfficeAgent가 처리하는 데이터가 어디에 저장·처리되는지가 핵심이며, 특히 **LLM API 외부 호출**이 까다로운 지점이다.

## 법적 근거

- **클라우드컴퓨팅 발전법 제18조**: 근거지(데이터 처리 위치) 선택 원칙 — 공공기관 요청 시 국내 한정
- **개인정보보호법 제24조·제28조의2**: 개인정보 국외 이전 제한, 별도 동의·고지
- **정보통신망법 제25조**: 안전성 확보 조치 의무

## 실무 요건

- 데이터 저장·처리 위치: **국내 리전 의무** (특히 민감·중요 정보)
- 클라우드 시스템·백업·데이터의 물리적 위치 국내 한정 ([[csap]] 인증 요건과 직결)
- **암호화 키 관리(KMS) 독립 운영**: 데이터가 어디 있든 키는 공공기관(또는 국내 CSP)이 통제
- 데이터 처리 계약서에 데이터 주권 보장 명시 의무화 (2024+)

## ⚠ LLM API 외부 호출 — OfficeAgent의 핵심 난제

OfficeAgent는 Anthropic·OpenAI API를 호출한다. 이 호출이 개인정보·기밀을 국외 서버로 전송하면 데이터 주권 위반 소지가 있다.

설계 시 반드시 검토할 선택지:
- LLM API 호출 전 개인정보 마스킹·비식별화
- 국내 리전 LLM 또는 국산 모델(예: HyperCLOVA X) 대체 가능성
- 온프레미스 LLM(자체 호스팅 오픈 모델) — [[on-premise]] 참조
- 호출 데이터 범위 최소화 + 감사 로그

이 항목은 [[migration-checklist]]에서 별도 체크 대상이며, [[csap]] 상·중등급 설계에서 통과 난이도가 가장 높다.

## 기술 솔루션

- [[nhn-cloud|NHN Cloud]]는 KMS(키 관리 서비스) 별도 제공
- 전국 13개 국내 IDC로 데이터 국내 보관 요건 충족

## OfficeAgent 마이그레이션 설계 시사점

- AWS S3·RDS의 데이터를 NHN Object Storage·DB로 이전 시 국내 리전 확정
- AWS Secrets Manager → NHN 키 관리 서비스 대응, 키 소유·통제 주체 명시
- LLM API 데이터 흐름도를 그리고 국외 전송 지점을 식별 → 대안 설계

## 1차 자료

- law.go.kr — 클라우드컴퓨팅법 §18, 개인정보보호법 §24·§28의2, 정보통신망법 §25
- docs.nhncloud.com — NHN 키 관리 서비스
