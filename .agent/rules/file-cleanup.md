---
trigger: always_on
glob:
description: 임시 파일 및 분석 결과 정리 규칙
---

# File Cleanup Rules

## Analysis Files
- 코드 문제를 해결하거나 분석 작업을 마친 후에는 항상 임시 분석 결과 파일(예: `analysis_output.txt`, `final_analysis.txt`)을 삭제하십시오.
- 목적을 달성한 임시 텍스트 파일을 프로젝트 루트 디렉토리에 남겨두지 마십시오.
- 디버깅을 위해 일시적으로 생성한 커스텀 분석 설정이 있다면 원래 상태로 되돌리거나 더 이상 필요하지 않을 때 제거하십시오.
