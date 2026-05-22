---
title: "멀티 환경 배포 설계자 체크리스트"
type: decision
tags: [체크리스트, 설계, 마이그레이션]
status: active
confidence: high
created: 2026-05-21
updated: 2026-05-21
sources: [raw/2026-05-20_perplexity-csap-overview.md, raw/2026-05-21_perplexity-nhn-isms-detail.md]
---

# 멀티 환경 배포 설계자 체크리스트

OfficeAgent를 정부·공공기관 고객 규제에 맞춰 [[nhn-cloud|NHN]]·[[on-premise|오픈스택]] 등에 배포 가능하도록 설계할 때, `MIGRATION_PLAN.md` 작성 시 반드시 짚어야 할 항목. 각 항목은 본 위키의 상세 페이지로 연결된다.

## 규제 분류

- [ ] OfficeAgent가 처리할 정보 등급 분류 (개인정보 · 기밀 · 일반)
- [ ] 목표 [[csap|CSAP]] 등급 (하/중/상) 결정과 그 이유
- [ ] 목표 고객 유형 (일반 공공 / 국방·외교) — [[on-premise|오픈스택]] 필요 여부 판단

## 클라우드 환경

- [ ] [[nhn-cloud|NHN Cloud]]의 목표 등급 CSAP 인증 보유 여부 확인 (NHN docs 직접 인용)
- [ ] [[network-isolation|망분리]] 요건 (물리/논리) 확인 및 설계 반영
- [ ] [[data-sovereignty|데이터 국내 보관]] 보장 (서비스 리전 명시)
- [ ] AWS 컴포넌트 → NHN / 오픈스택 대응 서비스 매핑표

## 데이터 주권 (난이도 최상)

- [ ] 암호화 키 관리(KMS) 독립 운영 / 키 통제 주체 명시
- [ ] **LLM API 외부 호출(Anthropic·OpenAI)의 [[data-sovereignty|데이터 주권]] 영향** — 마스킹·국산 모델·온프레미스 LLM 등 대안 검토
- [ ] 데이터 처리 계약서 데이터 주권 명시 항목

## 추가 인증

- [ ] [[certifications|ISMS-P]] 등 추가 인증 필요 여부와 일정
- [ ] [[on-premise|오픈스택 자체 구축]] 시 보안적합성 검증·CC 인증 부담 평가

## 시간축

- [ ] [[policy-trends|2027년 검증 제도 통합]] 영향을 로드맵에 반영
- [ ] 단기(NHN) vs 장기(오픈스택) 로드맵 구분
- [ ] 마이그레이션 자체의 보안 감독 (전환 기간 데이터 보호)

## 멀티 환경 추상화

- [ ] AWS-only / 공통 / NHN-only / 오픈스택-only 영역 구분 (ARCHITECTURE.md)
- [ ] NHN-only 기능에 종속된 부분 식별 (오픈스택 단계 재작성 대상)
- [ ] [[on-premise|오픈스택]] Neutron·Cinder·Swift·Keystone ↔ AWS·NHN 서비스 매핑

## 검증 (VALIDATION.md)

- [ ] 깊이 다룬 도메인 2개 각각에 검증 시나리오 1개 이상
- [ ] 각 시나리오: 입력 · 명령 · 기대 출력 · 실패 시 판단 기준
- [ ] [[network-isolation|망분리]]·[[data-sovereignty|데이터 무결성]] 검증 항목

## 사용법

이 체크리스트는 **출발점**이다. 응시자는 각 항목을 본인 설계에 맞게 구체화하고, 위키에 없는 내용을 조사하면 `wiki/`를 확장(`llm-wiki ingest`)하는 것이 권장된다 (필수 아님, 하면 가산).
