---
title: "NHN Cloud — 공공 클라우드 포지션"
type: entity
tags: [nhn, csp, 공공, 배포환경]
status: active
confidence: high
created: 2026-05-21
updated: 2026-05-21
sources: [raw/2026-05-21_perplexity-nhn-isms-detail.md, raw/2026-05-20_perplexity-csap-overview.md]
---

# NHN Cloud — 공공 클라우드 포지션

OfficeAgent가 정부기관 납품을 위해 지원해야 할 주요 배포 환경. AWS([[foreign-csp]])로는 충족 불가한 [[csap|CSAP]]·[[data-sovereignty|데이터 주권]] 요건을 NHN Cloud는 만족시킬 수 있다.

## 공공 시장 포지션

- 국내 공공 클라우드 시장 **1위 CSP**
- IaaS 분야 **국내 최초 [[csap|CSAP]] 인증**
- 전국 **13개 IDC** 운영 (국내 CSP 중 최다) → [[data-sovereignty|데이터 국내 보관]] 요건 충족에 유리
- **DaaS 인증 보유 유일 사업자** → 공공기관 인터넷망 PC 대체(VDI) 프로젝트 독점적 위치
- 공공기관 전용 리전 별도 운영 (민간과 [[network-isolation|논리적 분리]])

## CSAP 인증 사업자 분포 (조사 시점)

| 유형 | 인증 사업자 수 |
|------|---------------:|
| IaaS | 9개사 (NHN Cloud 포함) |
| SaaS 표준 | 22개사 |
| SaaS 간편 | 44개사 |
| DaaS | 1개사 (NHN Cloud) |

## CSAP 지원 프로그램

- CSAP 프로모션: 인증심사·서류 준비 전담팀 + 인프라 사용료 500만원 크레딧
- 사전 진단·맞춤 컨설팅으로 취득 필요 등급·필수 서류 안내

## 국내 경쟁 CSP

NHN Cloud 외 네이버클라우드(NCP)·KT Cloud·삼성SDS가 공공 시장 경쟁. 공공 분야 점유율·CSAP 인증 경험·IDC 수에서 NHN Cloud가 우위로 평가됨.

## AWS와의 결정적 차이

| 항목 | NHN Cloud | AWS ([[foreign-csp]]) |
|------|-----------|----------------------|
| 데이터 국내 보관 | 13개 국내 IDC | 서울 리전 있으나 공공 고도 시스템 제약 |
| 물리적 망분리 | 공공 전용 리전 | 곤란 |
| CSAP 상·중등급 | 보유·취득 가능 | 사실상 불가 |
| 국내 운영 조직 | 보유 | 제한적 |

## OfficeAgent 마이그레이션 설계 시사점

- AWS 컴포넌트 → NHN 대응 서비스 매핑이 설계서의 핵심 (`MIGRATION_PLAN.md`)
- NHN이 보유한 CSAP 등급을 설계 시점에 NHN 공식 docs로 직접 확인 (등급 현황은 변동)
- NHN Object Storage / NHN DB / NHN Kubernetes Service 등 구체 서비스명을 docs에서 확인해 매핑
- [[migration-checklist]] 참조

## 1차 자료

- info.nhncloud.com/2024-csap-promotion — CSAP 프로모션
- docs.nhncloud.com/ko/nhncloud/ko/region-guide — 리전 가이드
- zdnet.co.kr (2023-02) — CSAP 사업자 분포
