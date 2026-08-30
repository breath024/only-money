# Only Money 대시보드 — 인수인계서

> **다음 Claude(또는 호윤)가 코드 수정 시 첫 30초 안에 읽고 시작하는 문서.**
> 작업 시작 전 "빠른 시작" → 작업 후 "검증 프로토콜" → 히스토리에 한 줄 추가.

---

## ⚡ 빠른 시작 (다음 클로드 30초 가이드)

1. **호윤이 뭐 고치라고 했나?** → "현재 기능 표" + "Grep 마커" 보고 해당 위치 점프
2. **새 변수 const/let 선언?** → **반드시 grep으로 중복 체크**. 중복 const는 전체 JS 실행 실패 (사고 4c)
3. **`ACTIONS.push(...)` 같은 호출은?** → `const ACTIONS = [...]` 선언 **이후 위치**여야 함. 위에 있으면 `setTimeout(() => ..., 0)`로 defer (사고 4d)
4. **수정 후 검증?** → V8 syntax + Playwright headless 둘 다 통과 필수 ("검증 프로토콜" 참고)
5. **수정 후 마지막에?** → 코드에 `// 2026-MM-DD-X 호윤요청` 주석 + 이 문서 히스토리 한 줄 추가

---

## 📁 파일 위치

- **작업 폴더**: `C:\Users\USER\iCloudDrive\Only Money\`

### 현재 폴더 안 파일 (10개)
| 파일 | 역할 | 크기 |
|---|---|---|
| `index.html` | 메인 앱 (~6,500줄) | ~400KB |
| `HANDOFF.md` | 이 문서 (개발자용) | ~30KB |
| `README.md` | 사용자용 가이드 | ~7KB |
| `prompts.json` | 5단계 파이프라인 분석 프롬프트 | ~5KB |
| `manifest.json` | PWA 매니페스트 | ~1KB |
| `icon.svg` | 앱 아이콘 ($ 그라데이션) | ~1KB |
| `sw.js` | Service Worker | ~1.5KB |
| `serve.bat` | Windows 로컬 서버 실행 | ~2KB |
| `serve.ps1` | PowerShell 버전 | ~2.5KB |
| `serve.sh` | macOS/Linux 버전 | ~1KB |

---

## 🏗 프로젝트 개요

단일 HTML 파일 SPA. 빌드/패키지 없음. 브라우저에서 바로 열기.
- **모든 사용자 데이터는 localStorage만** (외부 서버 0)
- **TradingView 임베드** 위젯 (차트·티커·히트맵·스크리너)
- **Claude API 직접 호출** (옵션 1, 사용자 키)
- **Ollama 로컬 LLM** 호출 (옵션 2, 무료)
- RSS 프록시 경유 (allorigins/corsproxy/codetabs/cors.lol 등 6단 폴백)

### 권장 실행 방법
1. **로컬 서버**: `serve.bat` 더블클릭 → `http://localhost:8000` (RSS·F&G·PWA 정상 작동)
2. **직접 열기 (`file://`)**: 일부 기능 제한 (RSS 차단·manifest CORS·SW 등록 불가). 페이지 상단에 자동 경고 배너 표시됨.

---

## ✅ 코드 수정 후 검증 프로토콜 (필수!)

**과거 사고 4c·4d 이후 의무화**. 둘 다 통과해야 함.

### 1단계: V8 Syntax 검증 (중복 선언·괄호 불일치)
```bash
cd "/c/Users/USER/iCloudDrive/Only Money"
PYTHONIOENCODING=utf-8 python -c "
import re
from py_mini_racer import MiniRacer
with open('index.html', encoding='utf-8') as f: html = f.read()
m = re.search(r'<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)</script>', html)
ctx = MiniRacer()
try:
    ctx.eval('new Function(' + repr(m.group(1)) + ')')
    print('V8 OK')
except Exception as e:
    print('SYNTAX:', str(e)[:300])
"
```

### 2단계: Playwright 실제 페이지 테스트 (TDZ·런타임)
```python
# _check_browser.py
import os
from playwright.sync_api import sync_playwright
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    errors = []
    page.on('pageerror', lambda e: errors.append(('PAGEERROR', str(e))))
    page.on('console', lambda msg: errors.append((msg.type, msg.text)) if msg.type == 'error' else None)
    path = os.path.abspath('index.html').replace(os.sep, '/')
    page.goto(f'file:///{path}', wait_until='domcontentloaded', timeout=15000)
    page.wait_for_timeout(3000)
    fatal = [e for e in errors if e[0] == 'PAGEERROR']
    if fatal:
        print('FATAL:'); [print(f'  [{t}] {m[:300]}') for t, m in fatal]
    else:
        print('OK: no PAGEERROR')
    browser.close()
```
실행: `PYTHONIOENCODING=utf-8 python _check_browser.py`

작업 끝나면 `_check_browser.py` 삭제 (`Remove-Item _check_browser.py`).

### 흔한 버그 패턴 (체크리스트)
- [ ] 새 `const VARNAME` 선언 전 grep으로 중복 체크 (사고 4c)
- [ ] `XXX.push(...)` 호출이 `const XXX` 선언 이전이면 `setTimeout(() => ..., 0)`로 defer (사고 4d)
- [ ] 새 `<script>` block은 기존 script 안에 합치기 (별도 block은 변수 스코프 분리됨)

---

## 🔍 Grep 마커 인덱스 (라인 번호 신뢰 X)

라인 번호는 코드 추가하면 어긋남. **이 검색어로 grep해서 점프**:

### 큰 블록 마커 (최신 → 과거 순)
| 검색어 | 무엇 |
|---|---|
| `2026-05-28c 호윤요청 업그레이드` | 5단계 파이프라인 (제일 끝) |
| `2026-05-28b 호윤요청` | Ollama sequential·취소·RSS 프록시 확장 |
| `2026-05-28 호윤요청 업그레이드` | Ollama 통합 (provider toggle) |
| `2026-05-27-2 호윤요청 업그레이드` | 토스트·온보딩·설정·About·PWA |
| `2026-05-27 호윤요청 업그레이드` | Daily Brief·PF 리스크·저널 통계·종목별 AI |
| `2026-05-26-4 호윤요청 업그레이드` | AI 종합 분석 (Claude 6명 페르소나) |
| `2026-05-26-3 호윤요청 업그레이드` | 메모탭·포트폴리오 메모·저널편집·cmdk 확장 |
| `2026-05-26 호윤요청 업그레이드` | 차트 모달·자동완성·메모 자동저장·STOCK_DB |

### 기능별 마커
| 기능 | Grep 패턴 |
|---|---|
| **🤖 AI 시스템** | |
| Claude API 호출 | `async function callClaude` |
| Ollama API 호출 | `async function callOllama` |
| AI 통합 디스패처 | `async function callAI` |
| AI 종합 패널 오케스트레이터 | `runAIAnalysisV3` (최신, V2/V1 패치 적용됨) |
| 5단계 파이프라인 러너 | `async function runLayeredAnalysis` |
| 종목별 AI 모달 | `function openStockAI` 또는 `STOCK_AI_SYSTEM_PROMPT` |
| AI 컨텍스트 빌더 | `function buildAIContext` |
| AI 페르소나 정의 (6명) | `const AI_PERSONAS = [` |
| PRO 파이프라인 layer 정의 (9단) | `const PROMPTS_OVERRIDE_KEY` 또는 `prompts.json` (외부 파일, v3) |
| 시세·지표 계산 (RSI/ATR/SMA) | `function computeIndicators` 또는 `async function fetchOneQuote` |
| 시세 컨텍스트 주입 | `function buildQuotesSection` / `async function ensureQuotesForAnalysis` |
| 경제 지표 (FRED) 패널 | `const FRED_SERIES` / `function renderEconIndicators` / `async function loadEconIndicators` |
| FRED 패치 (키/keyless) | `async function fetchFredSeries` / `function getFredKey` / `async function computeBuffett` |
| 경제지표 AI 주입 | `function buildEconSection` |
| 마크다운 파서 | `function aiFormatMarkdown` |
| **HTML 핵심 ID** | |
| 오버레이 비교 차트 | `id="sec-overlay"` 또는 `OVERLAY_PRESETS` |
| AI 종합 패널 | `id="sec-ai"` |
| 5단계 파이프라인 패널 | `id="sec-layered"` |
| AI 키 모달 | `id="ai-key-overlay"` |
| Ollama CORS 가이드 | `id="ollama-cors-overlay"` |
| 프롬프트 편집기 | `id="prompts-edit-overlay"` |
| Daily Brief | `id="sec-brief"` |
| 포트폴리오 리스크 | `id="sec-pf-risk"` |
| 설정 모달 | `id="settings-overlay"` |
| About 모달 | `id="about-overlay"` |
| 온보딩 위저드 | `id="onboarding-overlay"` |
| 토스트 컨테이너 | `id="toast-container"` |
| file:// 경고 배너 | `id="file-mode-banner"` |
| **데이터/계산** | |
| 종목 DB (~150개) | `const STOCK_DB = [` |
| Fear & Greed | `===== Fear & Greed` |
| 시장 뉴스 | `===== Sentiment / News =====` |
| 글로벌 속보 | `===== Global Breaking News =====` |
| 매크로 신호 | `===== Macro Signals Panel =====` |
| 프로 지표 | `===== Pro Indicators / Sector Rotation =====` |
| 프로 지표 읽는 법 모달 | `PRO_GUIDE_CONTENT` 또는 `id="proguide-overlay"` |
| 포트폴리오 리스크 (HHI·베타) | `function renderPortfolioRisk` |
| 저널 P&L 통계 (FIFO) | `function renderJournalStats` 또는 `_journalFIFOMatch` |
| 양도세 정산 | `===== Tax Reconciliation` |
| Export/Import | `===== Data Export / Import =====` |
| **UX/유틸** | |
| 토스트 함수 | `function showToast` 또는 `const toast = {` |
| 설정 모달 | `function openSettings` 또는 `SETTING_KEYS = {` |
| 온보딩 단계 | `const ONBOARDING_STEPS = [` |
| 자동완성 | `function setupAutocomplete` |
| 차트 모달 | `function openChartModal` |
| 메모 자동저장 | `function flushNotesSave` |
| 메모 모음 탭 | `function renderMemoTab` |
| cmdk 통합 검색 | `function getCmdkContentResults` |
| 저널 편집 상태 | `editingJournalIdx` |
| 전역 단축키 | `===== Global Keyboard Shortcuts =====` |
| RSS 프록시 (6단 폴백) | `async function fetchViaProxy` |
| 암호화폐 그리드 | `TOP_CRYPTOS` 또는 `id="crypto-grid"` |

---

## 💾 localStorage 스키마

| 키 | 형식 | 설명 |
|---|---|---|
| **사용자 데이터** | | |
| `watchlist` | `string[]` | 관심종목 티커 목록 |
| `watchlist_notes` | `{ [ticker]: string }` | 메모 본문 |
| `watchlist_notes_meta` | `{ [ticker]: { updatedAt: iso } }` | 마지막 수정 시간 |
| `portfolio` | `{ ticker, shares, avgCost, addedDate }[]` | 보유 종목 |
| `journal` | `{ date, ticker, action, price, shares, reason }[]` | 트레이딩 저널 |
| `goals` | `{ name, target, current, targetDate, monthlyContrib, createdAt }[]` | 투자 목표 |
| `checklist` | `{ date, checked: { [id]: bool } }` | 일일 체크리스트 (자정 자동 리셋) |
| **AI 시스템** | | |
| `anthropic_api_key` | `string` (sk-ant-...) | Claude API 키 |
| `ai_history` | `{ ts, usage, results: [{id, text, error}] }[]` | AI 분석 이력 (최대 10) |
| `layered_history` | `{ ts, provider, model, layers, cancelled }[]` | 파이프라인 분석 이력 (최대 5) |
| `prompts_override` | `string` (JSON) | 사용자가 수정한 prompts.json (없으면 원본 파일 사용) |
| **설정** | | |
| `setting_ai_provider` | `'anthropic'` \| `'ollama'` | AI 프로바이더 |
| `setting_ollama_url` | `string` | Ollama 서버 URL (기본 http://localhost:11434) |
| `setting_ollama_model` | `string` | 선택된 Ollama 모델 |
| `setting_refresh_interval` | `number` (ms) | 뉴스 자동 갱신 주기 |
| `setting_default_fx` | `number` | 기본 환율 (원/$) |
| `setting_ai_model` | `string` | Claude 모델 (현재 코드는 ANTHROPIC_MODEL 상수 사용. 적용은 추후 callClaude 수정 필요) |
| `setting_news_filter` | `'true'` \| `'false'` | 시장 무관 뉴스 필터 |
| **상태 플래그** | | |
| `theme` | `'dark' \| 'oled' \| 'bloomberg' \| 'contrast'` | 테마 |
| `onboarded` | `'1'` | 첫 방문 온보딩 완료 |
| `file_mode_warned` | `'1'` | file:// 모드 토스트 표시 완료 |
| `file_banner_dismissed` | `'1'` | file:// 배너 사용자가 닫음 |
| **캐시** | | |
| `tr_cache` | `{ [enText]: koText }` | 번역 캐시 (최대 800) |
| `fg_cache` | `{ data, source, ts }` | Fear & Greed 캐시 |

**⚠ 스키마 변경 시**: 마이그레이션 로직 필수. 호윤이 옛 데이터로 들어올 수 있음:
```js
const v = localStorage.getItem('schema_version') || '1';
if(v === '1'){ /* migrate */; localStorage.setItem('schema_version', '2'); }
```

---

## 🤖 AI 시스템 구조 (3가지 모드 공존)

### 1. 🎭 6명 페르소나 종합 분석 (`#sec-ai`)
- **Bull / Bear / Macro / Technical / Quant** (5명) → 병렬 (Anthropic) 또는 순차 (Ollama)
- **Synthesis** (1명) → 마지막에 4-5명 결과 받아 통합
- 함수: `runAIAnalysisV3` → `callAI` → `callClaude` 또는 `callOllama`
- 진행 표시: 버튼이 `⏳ N초 · M/5 · 취소 클릭`로 토글, 클릭 시 AbortController로 즉시 중단

### 2. 🧱 PRO 파이프라인 9단 (`#sec-layered`, 2026-06-12 5단→9단 재설계)
- 외부 `prompts.json` v3 로드 (localStorage override 지원)
- 각 layer가 이전 layer 출력을 **누적 context**로 받음. 순서: 레짐→뉴스→🧠군중심리→🎯종목셋업(실지표)→🛡리스크→⚔️1차콜→🔴레드팀→🧘내매매심리→✅최종콜
- 그라운딩: `buildAIContext`가 RSI/ATR/이평선/VIX(실계산) + 포트 집중도 + 매매 저널을 컨텍스트로 주입
- 함수: `runLayeredAnalysis` → `callAI`. layer 수는 `renderLayerCards`가 자동 대응(추가/삭제 자유)
- 인라인 편집기: textarea에 JSON 표시 → 검증 후 localStorage 저장. 원본 복원 가능.
- 코드 안 건드리고 prompts만 수정해서 분석 방향 바꿀 수 있음

### 3. 🔍 종목별 AI 심층 분석 (`#stock-ai-overlay`, 차트 모달 내 버튼)
- 단일 종목에 대한 사업모델·강점·약점·매크로영향·밸류에이션·진입가이드·결론
- 호윤 보유·메모 컨텍스트 자동 전달
- 단일 호출 (분석가 1명)

### 🏠 Ollama vs ☁️ Claude — 자동 분기
- 설정 → AI 프로바이더 토글 (`setting_ai_provider`)
- Ollama: API 키 불필요, 무료, `/v1/chat/completions` OpenAI 호환 사용, 순차 실행
- Claude: API 키 필요, 유료, `cache_control: ephemeral` 프롬프트 캐싱, 병렬 가능
- **CORS 주의**: Ollama 사용 시 `OLLAMA_ORIGINS="*"` 환경변수 설정 필수 (가이드 모달 제공)

### 🚨 Ollama 무한 hang 주의 (2026-05-28b 사고)
- 4명 병렬 호출은 단일 GPU에서 메모리 폭주 → 무한 hang
- **반드시 sequential 실행** (`callOllama` 직접 부르지 말고 `callAI` 거치기)
- 5분 타임아웃 + AbortController 필수 (`_ollamaAbortController`)

---

## 🌐 외부 의존성 + CORS 우회

| 서비스 | 용도 | 안정성 | 폴백 |
|---|---|---|---|
| TradingView 임베드 | 차트·티커·히트맵·스크리너 | ⭐⭐⭐⭐⭐ | — |
| Anthropic API | AI 분석 | ⭐⭐⭐⭐⭐ | 키 만료/잔액 시 사용자가 알림 |
| Ollama (`localhost:11434`) | 로컬 LLM | 사용자 환경 의존 | CORS 가이드 모달 |
| MyMemory + Google Translate | 뉴스 번역 | ⭐⭐⭐ | 캐시 (`tr_cache`) |
| CNN `production.dataviz.cnn.io` | F&G 실시간 | ⭐⭐ (CORS 차단 다발) | GitHub 미러 `whit3rabbit/fear-greed-data` |
| alternative.me | 크립토 F&G | ⭐⭐⭐⭐ | — |
| RSS 피드 (Yahoo/MarketWatch/CNBC/Investing/WSJ/BBC/NPR/Al Jazeera) | 뉴스 | ⭐⭐ (프록시 필수) | `fetchViaProxy()` |
| Clearbit Logo | 회사 로고 | ⭐⭐⭐⭐ | 티커 2글자 텍스트 fallback |

### RSS 프록시 (6단 폴백, 2026-05-28b 확장)
순서 (안정성 순):
1. `api.codetabs.com/v1/proxy/?quest=` (가장 안정)
2. `api.allorigins.win/raw?url=` (자주 죽음)
3. `corsproxy.io/?` (403 자주)
4. `api.cors.lol/?url=`
5. `proxy.cors.sh/`
6. `cors.bridged.cc/`

**프록시당 8초 타임아웃** (`AbortController`). 봇 차단 응답 (`I'm a teapot` 등) 자동 감지. 함수: `async function fetchViaProxy`

---

## 📊 TradingView 심볼 권장값

⚠️ 무료 임베드 위젯은 일부 지수/금리/VIX 심볼 차단. 안 보이면 ETF로 교체.

| 자산 | 권장 심볼 | 비고 |
|---|---|---|
| S&P 500 | `FOREXCOM:SPXUSD` / `AMEX:SPY` | 위젯에 따라 |
| 나스닥100 | `FOREXCOM:NSXUSD` / `NASDAQ:QQQ` | |
| **VIX** | **`AMEX:VIXY`** | TVC/CBOE/INDEX VIX 전부 차단 → VIXY ETF |
| USD Index | `CAPITALCOM:DXY` / `AMEX:UUP` | |
| Gold | `TVC:GOLD` / `AMEX:GLD` | |
| WTI | `TVC:USOIL` / `AMEX:USO` | |
| **US 1-3Y 채권** | `AMEX:SHY` | TVC:US02Y 차단 |
| **US 7-10Y 채권** | `AMEX:IEF` | TVC:US10Y 차단 |
| **US 20Y+ 채권** | `NASDAQ:TLT` | TVC:US30Y 차단 |
| 인플레 연동채 | `AMEX:TIP` | |
| USDKRW | `FX_IDC:USDKRW` | |
| BTC | `BITSTAMP:BTCUSD` | |
| 신용 위험 | `AMEX:HYG` / `AMEX:LQD` | 정크/투자등급 |
| 소형주 | `AMEX:IWM` | Russell 2000 |

**원칙**: `TVC:` = TradingView Cloud (지수/금리), 임베드 차단 多. `AMEX/NASDAQ/NYSE:` = 거래소 상장 ETF, 거의 항상 됨.

### TradingView 위젯 종류
| 위젯 | URL | 최소 높이 |
|---|---|---|
| Mini sparkline (1x) | `embed-widget-mini-symbol-overview.js` | 130px+ |
| 단일 차트 | `embed-widget-symbol-overview.js` | 250px+ |
| 풀 차트 (모달용 권장) | `embed-widget-advanced-chart.js` | 400px+ |
| 티커 테이프 | `embed-widget-ticker-tape.js` | 고정 56px |
| 히트맵 | `embed-widget-stock-heatmap.js` | 300px+ |
| 스크리너 | `embed-widget-screener.js` | 400px+ |
| 캘린더 | `embed-widget-events.js` | 300px+ |
| 기술분석 게이지 | `embed-widget-technical-analysis.js` | 400px |

⚠️ `embed-widget-crypto-coins-heatmap.js` / `embed-widget-cryptocurrency-market.js` 둘 다 종종 빈 박스로 나옴. **mini-symbol-overview 그리드로 자체 구성** 권장 (`TOP_CRYPTOS` 참고).

### 위젯 추가 패턴 (필수)
```html
<div class="tradingview-widget-container">
  <div class="tradingview-widget-container__widget"></div>
</div>
```
+ JS로 `<script>` 동적 생성. config JSON을 `script.text`에 할당. 기존 `createMiniWidget()` 함수 패턴 재사용 권장.

---

## 🔧 내부 API (다음 클로드가 호출 가능)

```js
// 차트 모달
openChartModal('NASDAQ:AAPL')                        // 거래소 포함
openChartModal('AAPL')                                // 티커만 (DB 자동 매핑)
openChartModal('VIX', '변동성 지수')                  // 표시명 override

// STOCK_DB 검색
searchStocks('apple', 5)                             // → 상위 5개 [{t,ex,n,ko,s,d}]
findStockByTicker('AAPL')                            // → 객체 or null
tickerWithExchange({t:'AAPL', ex:'NASDAQ'})          // → 'NASDAQ:AAPL'

// 자동완성 (새 input)
setupAutocomplete('input-id', 'suggest-div-id', (stock) => { /* 선택 시 */ });

// 로고
getLogoUrl({ d:'apple.com' })                        // → Clearbit URL

// 메모 메타
getNoteMeta('AAPL')                                  // → { updatedAt: iso } or null
setNoteMeta('AAPL', { updatedAt: ... })              // null 주면 삭제
flushNotesSave()                                     // 펜딩 저장 강제 flush

// AI 호출 (provider 자동 분기)
await callAI(persona, contextText, extraContext)
// persona = { id, icon, name, desc, systemPrompt, isSynthesis? }
// 반환: { text, usage:{input,output,model,...} } 또는 { error }

// 토스트 알림
toast.success('저장됨')
toast.error('오류: ...', 5000)  // 지속시간 override
toast.info('정보 메시지')
toast.warning('경고')

// 설정 값 읽기/쓰기
getSetting('refresh') / getSetting('aiModel') / getSetting('provider')
setSetting('fx', 1380)
```

### 새 카드 섹션 추가 패턴
```html
<div class="section-header">🎯 섹션 이름 <span class="hint">— 부제</span></div>
<section class="card col-N h-M" id="sec-xxx">
  <div class="card-title">
    <div class="card-title-left"><span class="dot"></span>제목</div>
    <span class="badge">메타</span>
  </div>
  <div class="card-body">...</div>
</section>
```
- col: 12분할 (col-3/4/5/6/7/8/12)
- h: `h-tiny`(160) / `h-sm`(320) / `h-md`(400) / `h-lg`(480)
- focus banner & cmdk jump 위해 `id="sec-xxx"` 부여
- 카드에 차트 → `data-symbol="EXCHANGE:TICKER"` 속성 (클릭 시 모달 트리거)

### 새 커맨드 / 단축키 추가
```js
setTimeout(() => {
  if(typeof ACTIONS !== 'undefined'){
    ACTIONS.push({ id:'xxx', icon:'🔥', name:'설명', keys:['x'], fn: () => {...} });
  }
}, 0);
```
**중요**: `ACTIONS`는 cmdk 섹션에서 `const`로 선언되므로 그 이전 위치에서 push하면 TDZ 에러. **항상 `setTimeout(..., 0)`** 으로 감싸기.

---

## 🎨 코딩 규칙 (호윤 선호)

- **한국어 UI** + 한국어 주석
- 섹션 구분 이모지 적극 사용 (🌙 📊 💰 🤖 ...)
- 강조색: 골드 `#f7b500` (CSS 변수 `--gold`)
- 다크 테마 기본 (`--bg:#0b0e14`, `--panel:#131722`)
- 사용자 데이터는 **localStorage만** (외부 서버 X, 분석 도구 X, 추적 X)
- 모달은 `.modal-overlay` + `.modal` 패턴 통일
- 토스트 사용 (`toast.success/error/info/warning`). 가급적 `alert()` 안 쓰기 (confirm은 파괴적 액션에만)
- 수정 시 코드에 `// YYYY-MM-DD-N 호윤요청` 주석으로 추적성 확보

---

## 🧪 테스트 / 실행 방법

1. **로컬 서버 권장**: 폴더 안 `serve.bat` 더블클릭 (Windows) / `serve.sh` (Mac/Linux)
2. **그냥 열기 (`file://`)**: 빠르지만 RSS·F&G·manifest·SW 제한. 페이지가 자동 경고 배너 표시.
3. F12 콘솔 로그:
   - `💰 Only Money v1.0.0 (2026-MM-DD)` ← 정상 시작 배너
   - `[FG] realtime via xxx` 또는 `[FG] github mirror used` ← F&G 소스
   - `[PWA] SW registered` ← Service Worker 등록 성공 (localhost일 때만)
4. localStorage 검사: 콘솔 → `Application` 탭 → `Local Storage`
5. 단축키: `?` = 도움말, `Ctrl+K` = 커맨드 팔레트, `Ctrl+,` = 설정

---

## ⚠️ 과거 사고 패턴 (다음 클로드는 같은 실수 안 하기)

### 사고 4c: 변수 중복 선언
**증상**: 페이지가 전혀 작동 안 함 (모든 버튼 무반응)
**원인**: 이미 `const _origFlushNotesSave`가 있는데 새 wrap에서 또 `const` 선언 → SyntaxError
**예방**: 새 const/let 선언 전 `Grep "const VARNAME"`. 같은 이름 있으면 `_origXXX2` 처럼 rename + 체이닝.

### 사고 4d: TDZ (Temporal Dead Zone)
**증상**: 똑같이 모든 버튼 무반응 (V8 syntax는 통과)
**원인**: `ACTIONS.push(...)`가 `const ACTIONS = [...]` 선언 **이전 위치**에 있음. 런타임에 TDZ 에러로 스크립트 멈춤.
**예방**: V8 syntax 통과만으론 부족. **Playwright headless로 실제 페이지 로드 테스트** 필수.

### 사고 28b: Ollama 무한 hang
**증상**: AI 분석 실행 시 3분 넘게 응답 없음
**원인**: 4명 페르소나 `Promise.all` 병렬 호출 → 단일 GPU에서 메모리 폭주
**예방**: Ollama는 무조건 sequential (`for` loop). AbortController + 5분 타임아웃 필수.

### 사고 5: 감성 분석 키워드 누락
**증상**: "US attacks Iran" 같은 명백한 악재가 "중립"으로 분류
**원인**: NEG 단어집이 금융 용어 중심 (`miss`, `plunge`)이라 지정학 단어 없음
**예방**: 새 도메인 추가 시 키워드 사전 확장 필수 (war/attack/missile/airstrike 등).

### 사고: file:// 모드 한계
**증상**: 만든 사람 입장에선 잘 되는데 사용자가 "RSS 안 보임"
**원인**: 사용자가 HTML을 더블클릭으로 열면 `file://`. CORS 정책상 외부 fetch 다 차단.
**예방**: `serve.bat`/`serve.sh` 제공 + 페이지에 file:// 감지 배너 자동 표시. README에 명시.

---

## 👤 호윤 정보

- Only Money는 본인 투자 관리용 사이드 프로젝트
- **한국어로 소통**. 작업 폴더 `C:\Users\USER\iCloudDrive\Only Money\`
- "ㅋㅋ" 자주 씀. 가볍게 소통하면서 빠른 결과 선호.
- 종종 "[기능명] 안 보여" → 위젯 문제일 수도, file:// CORS일 수도, 광고차단기일 수도. 다층 가능성 고려.
- Anthropic API 키 잔액 떨어졌을 때 Ollama로 fallback 함. **AI 관련 작업은 양쪽 다 호환 확인**.

---

## 📜 히스토리

작업 후 한 줄씩 추가. 최신이 위.

- **2026-06-17**: 🤖 **로컬 LLM 모델 최신화** (호윤: "Only Money 분석용 로컬 AI 추천 + 구형 삭제"). 하드웨어 확인 RTX 5070 Ti **16GB**(Win32는 4GB로 오보고, nvidia-smi 기준 16303MiB)·RAM 31GB. **`qwen3:14b` 다운로드**(권장—qwen2.5:14b 대체, 추론력↑, VRAM 전량 적재). About 모달의 모델 추천 목록·`ollama pull` 명령·"설치된 모델 없음" 안내·timeout 힌트를 qwen3/gemma3 기준으로 교체(qwen3:14b★/qwen3:30b-a3b/gemma3:27b/gemma3:4b). ollama 구형 3종 삭제(qwen2.5:14b·qwen2.5:32b·exaone3.5:7.8b, **~32.8GB 회수**), 유지=gemma3:4b/gemma3:27b/qwen3:14b. ⚠️ 같은 ollama 공유하는 **COMET 라우터 동반 수정**(comet.py medium `qwen2.5:14b→qwen3:14b`·heavy `qwen2.5:32b→gemma3:27b`, ai_core.py model→qwen3:14b) — 안 고치면 COMET 부팅 시 모델 못 찾고 죽음. ⚠️ **`Desktop\Only Money`와 `iCloudDrive\Only Money` 두 사본 발견** → 양쪽 동기 수정(정식=iCloud). 검증 V8 OK.
- **2026-06-16b**: 🧩 **오버레이 4종 확장**(호윤: "다 하자"). ① **직접 선택 프리셋**(`✏️ 직접 선택`): `setupAutocomplete('overlay-custom-input',...)`로 종목 검색→추가, `_overlayCustom`(localStorage `overlay_custom`, 최대 8개) 칩으로 표시/삭제. preset==='custom'일 때만 `#overlay-custom-bar` 노출. ② **상관계수**(`🔗` 토글): `fetchCloses`(Yahoo chart, 기간별 range)→`_returnsByDate`(일간수익률)→`_pearson` 기준자산(첫 심볼) 대비. `_tvToYahoo`로 TV심볼→야후(크립토 `BTCUSD`→`BTC-USD`, ETF/주식은 베어티커). 결과 `_corrCache`(키=preset:period:syms) 캐시, 색=±0.4 기준 녹/적/회. 프록시 의존이라 on-demand(버튼 켤 때만 fetch). ③ **sparkline**: 의존성 없는 인라인 SVG `miniSparkline(vals,{h,color})`. F&G=`fear_and_greed_historical.data` 최근 90p 추세선(게이지 아래), 버핏=`computeBuffett`가 `series`(8년 월별 비율) 반환→행에 추세선. ④ **FRED 강제 새로고침**=기존 `econ-reload-btn`이 이미 `loadEconIndicators(true)`라 OK, 대신 **SW 캐시 v1.0.0→v1.1.0** 범프(편집 후 옛 shell 캐싱 방지). 검증 V8 OK·PAGEERROR 0·커스텀추가/칩·상관토글+Pearson자기상관=1.0·심볼매핑·F&G/버핏 sparkline 렌더(mock) 전부 확인. ⚠️ 상관계수는 프록시로 종목당 1 fetch라 묶음 크면 느릴 수 있음(캐시로 완화). Grep: `OVERLAY_PRESETS`/`computeOverlayCorr`/`miniSparkline`.
- **2026-06-16**: 📈 **오버레이 비교 차트 신설**(호윤: "큰 애들(S&P·BTC 등)+지표를 한 차트에 겹쳐 흐름 읽기"). `📈 흐름 분석` 섹션 안, EMA차트+기술분석 행 아래·히트맵 위에 `#sec-overlay`(col-12 h-md). **TradingView advanced-chart의 `compare_symbols`**(position:'SameScale'=자동 %정규화)로 여러 심볼을 같은 출발선에 겹침. 묶음 칩 5개(`OVERLAY_PRESETS`): 🔥위험자산(SPY/QQQ/BTC/금/달러)·🛡️안전vs위험(SPY/TLT/HYG/금/달러)·🌡️거시지표(SPY/VIXY/TLT/달러/금)·₿코인(BTC/ETH/SOL/QQQ)·⭐내관심종목(getWatchlist→동적, 없으면 안내). 기간 칩 4개(3M/6M/12M/60M, `range`). 첫 심볼=main, 나머지=compare. 심볼은 HANDOFF 권장 ETF 위주(VIX=AMEX:VIXY 등 차단 회피). `renderOverlayChart`/`setupOverlayChips`, 초기화는 const 이후 보장 위해 `setTimeout(...,0)` defer(사고 4d). style:'2'(라인). 검증 V8 OK·PAGEERROR 0·칩 전환(코인/5년/내관심종목) 동작·동적 프리셋 렌더 확인. ⚠️ TV 무료 임베드라 일부 심볼 차단 가능(안 겹치면 ETF로 교체). Grep: `id="sec-overlay"` / `OVERLAY_PRESETS`.
- **2026-06-15**: 🦅 **버핏지수 안 뜨던 버그 수정**. 원인=`computeBuffett`이 쓰던 FRED `WILL5000PRFC`(Wilshire5000 풀캡)가 **FRED에서 단종**(데이터 2023-05-30 종료, 2024-06 DB 제거) → 현재값 fetch 실패→throw→`_econRunConcurrent`의 `catch{}`에 먹혀 버핏 행만 조용히 누락(다른 FRED 지표는 시리즈 살아있어 정상이라 "버핏만 안 뜸"). Wilshire 풀캡 계열(`WILL5000INDFC` 등)도 전부 단종 확인. 수정=시장 프록시를 **`SP500`**(S&P500, FRED 최근 10년 일봉, 활성 유지)로 교체. 패널이 어차피 "8년 범위 퍼센타일(근사)"만 표시 → 8년<10년 보유분이라 동일 동작, 라벨/주석/desc를 'S&P500÷GDP 근사'로 갱신. 검증 V8 OK·PAGEERROR 0. ⚠️ 키 없으면 keyless CSV라 프록시 의존(HANDOFF 기존 경고대로 FRED 키 등록 권장). ⚠️ SP500은 가격지수라 절대 비율은 진짜 시총/GDP와 다름(퍼센타일은 유효) — 정밀값은 GuruFocus.
- **2026-06-12c**: 📊 **경제 지표 패널 (FRED 실데이터)** 신설 (호윤: "버핏지수도 없고 경제지표 부실"). 기존 매크로 패널은 일드커브·VIX·DXY가 "상단 카드 참고" 텍스트뿐(실값 X)이었음. 새 `#sec-econ`(col-7, `.macro-row` 스타일 재활용) + FRED 데이터 레이어. **지표 8+버핏**: 일드커브 T10Y2Y(역전 감지)·CPI/근원CPI YoY·실업률·기준금리(DFEDTARU)·실질금리(DFII10)·하이일드스프레드(BAMLH0A0HYM2)·M2 YoY + 🦅버핏지수(WILL5000PRFC÷GDP 8년 퍼센타일, 근사). `FRED_SERIES` 설정배열 + zones(good/warn/bad 색). `buildEconSection()`이 econ_cache→AI 컨텍스트 주입(매크로 페르소나가 실값 사용). **⚠️ 프록시 함정**: FRED `fredgraph.csv`는 키 없이 되지만 **CSV 콘텐츠타입을 corsproxy(403)·codetabs(400)가 막음** → keyless는 allorigins/get(JSON래핑, 8초 타임아웃)만 best-effort. 안정성 위해 **FRED 무료 API 키**(localStorage `fred_api_key`) 지원: 키 있으면 공식 JSON API를 corsproxy로(JSON은 통과) 안정적으로. 패널 🔑 버튼으로 키 등록(prompt). **UX**: UNRATE 프로브 한 방으로 ~8초 내 판정(실패 시 키 안내 빈 상태), 성공 시 종목별 증분 렌더. `renderEconIndicators`는 실데이터 0이면 "—"행 대신 키 안내(hasAny 가드). 캐시 6h(`econ_cache`). 검증: V8 OK·PAGEERROR 0·프록시막힘 시 키안내 정상·캐시주입 시 전지표 렌더(버핏 거품경계/일드커브 역전 등)·AI컨텍스트 주입 확인. ⚠️ 매크로 패널(#sec-macro)의 일드커브/VIX "참고" 행은 이제 econ 패널과 중복 — 향후 정리 여지. ⚠️ 내 샌드박스에선 allorigins 불안정(keyless 자주 실패) → 호윤 환경에선 키 등록 권장.
- **2026-06-12b**: 🎨 **UX 친화성 5종 개선** (호윤: "사용자 친화적으로 고칠 부분 찾아서 고쳐"). ① **🔴 손익·시세 화면 표시(핵심)**: 그동안 시세가 AI 컨텍스트에만 들어가고 화면엔 평단·투자금만 보였음(투자앱인데 손익 안 보임). 포트폴리오 아이템에 `.pf-quote`(현재가·등락%·평가금액·손익$/%), 관심종목에 `.wl-quote`(현재가·등락%·RSI) 추가. `refreshQuoteDisplays`/`applyQuoteDisplays`/`_normTicker` 신설, `ensureQuotesForAnalysis(extra,onEach)`에 증분 콜백(느린 종목이 전체 표시 안 막게). `renderWatchlist`는 `_quoteCache`(let) TDZ 회피 위해 `setTimeout(...,0)` defer 필수(HANDOFF 4d). ⚠️ **버그픽스**: 일간 등락엔 `m.previousClose` 사용(`chartPreviousClose`는 range 시작=1년 전 종가라 쓰면 등락%가 1년수익률 됨). ② **직관적 보유 추가**: 관심종목 hover→`＋보유` 버튼(`.wl-add`)→`prefillHoldingFrom`(티커+현재가를 평단 후보로 프리필, 수량 입력 포커스+스크롤). addHolding alert→toast. ③ **위젯 폴백**: `createMiniWidget`에 4.5s 후 iframe 없으면 텍스트 시세로 `.widget-fallback`(빈 박스 방지). ④ **모바일 ≤480px** @media 보강(브리프 2열, 입력 2x2, 터치타겟 30px, 액션버튼 항상표시, 모달 패딩, AI가이드 1열). ⑤ **AI 3모드 안내**: `#sec-ai-guide` 비교 박스(6명/9단/종목별 + 비용·시간·'처음이면 이거'), '5명/6명' 불일치 수정. 검증: V8 OK·PAGEERROR 0·라이브 손익 렌더(TSLL −16.7%)·모바일 390px 가로오버플로우 0·가이드 1열·터치타겟 30px. ⚠️ 포트폴리오 edit은 아직 prompt()(향후 인라인 편집 개선 여지).
- **2026-06-12**: 🧱 **PRO 파이프라인 (5단→9단 전면 재설계)** + Stage0 데이터 그라운딩. 호윤: "전업러 씹어먹게, 심리분석도". 솔직 프레이밍=데이터로 프로 못 이김, LLM 엣지는 ①감정0 규율 ②종합 폭/속도 ③자기판단 채점. 호윤 선택=핵심4단(데이터강화+군중심리+레드팀+내매매심리), 기존 5단 교체. ① **Stage0 실지표**: `fetchOneQuote`를 1mo→**1y 일봉**으로, OHLCV에서 `computeIndicators`로 **RSI14·SMA50/200 이격·ATR14·20일수익률**을 JS 실계산(`_rsi`/`_atr`/`_sma`). `ensureQuotesForAnalysis`에 **^VIX** 자동 포함. `buildQuotesSection`이 VIX 레짐 + 종목별 RSI/이평선/ATR/거래량/52주 표시("추정 아님"). ② **buildAIContext 확장**: `## ⚖️ 포트폴리오 집중도`(최대비중%) + `## 📓 매매 저널`(최근14건, getJournal) 섹션 추가 → 8단계 심리 레이어 먹이. ③ **prompts.json v3 = 9 layer**: 1레짐(VIX/F&G) 2뉴스촉매 3🧠군중심리(역발상) 4🎯종목셋업(실지표·ATR손절) 5🛡리스크/사이징 6⚔️1차콜초안 7🔴레드팀(악마의변호인) 8🧘내매매심리(보복/물타기/과집중) 9✅최종콜(레드팀·심리반영). `renderLayerCards`가 layer수 자동대응(코드수정 불필요). UI 헤더 '5단계'→'PRO'로. **검증**: V8 OK, JSON 9layer, PAGEERROR 0, localhost 라이브 TSLL 지표 실계산 확인(RSI39·200일선-24%·ATR9.3%·VIX19.98), 저널/집중도 컨텍스트 주입 확인. ⚠️ 여전히 `prompts_override` 있으면 v3 무시(편집기 '원본 복원' 필요). ⚠️ Ollama는 9단 순차라 느림(~수분). 미구현(향후): Stage9 캘리브레이션 스코어카드(콜 기록→실결과 채점).
- **2026-06-11**: 🔥 AI 영양가 업그레이드 (호윤: "너무 중립적·관망, 영양가 없다 / TSLL 체결강도도 못 잡음"). 두 갈래로 수정. ① **실시간 시세 주입**: `fetchOneQuote()`(Yahoo chart 엔드포인트 → 기존 `fetchViaProxy` 6단 프록시 경유)·`ensureQuotesForAnalysis()`·`buildQuotesSection()` 신설. 보유+관심종목(+종목AI는 해당 티커) 현재가·등락률·**거래량 배수(volRatio=오늘÷20일평균)**·52주 위치를 `_quoteCache`(2분)에 담아 `buildAIContext` 맨 위 `## 📈 실시간 시세` 섹션으로 AI에 전달. volRatio 1.5x↑=🔥급증(체결강도 급등 대용), <0.7=💤한산. **⚠️ 체결강도·호가 원자료는 미국 종목엔 없음** → 거래량 배수가 대용. 5개 분석 러너 전부 `await ensureQuotesForAnalysis()` 선반입. ② **프롬프트 확신형 재작성**: `AI_PERSONAS`(이름도 '트레이더'로)·`STOCK_AI_SYSTEM_PROMPT`·`prompts.json`(v2) — '균형/관망' 도망 제거, 방향 단정+확신도%+진입가/손절/목표/비중 숫자 강제, `PERSONA_COMMON` 공통 규칙으로 거래량 신호 활용 지시. `callClaude` max_tokens 700/900→1500/2200, `callOllama` 900/1200→1400/2000. **검증**: V8 OK, Playwright PAGEERROR 0, localhost에서 TSLL 실데이터 fetch 성공(corsproxy.io 경유; file://에선 프록시 차단됨=정상). ⚠️ 프록시 중 codetabs는 Yahoo URL에 400, 현재 corsproxy.io만 안정. ⚠️ localStorage `prompts_override` 있으면 prompts.json 무시됨(앱 프롬프트 편집기에서 '원본 복원' 필요).
- **2026-06-07b**: 프로 지표 모달에 `📌 내 스타일` 박스 추가 (`.proguide-mine`) — 호윤이 주식 스윙·비트 단타만 함. 섹터 모달=스윙 진입/보유 팁, 매크로 모달=스윙+비트 단타 팁. (검증 통과)
- **2026-06-07**: ℹ️ 프로 지표 "읽는 법" 가이드 모달 — 🔥섹터 로테이션 / 📊프로 매크로 지표 카드 제목에 `ℹ️ 읽는 법` 버튼(`[data-proguide]`) 추가. 클릭 시 `#proguide-overlay` 모달에 Risk On/Off 그룹·6개 지표 뜻·신호 조합·실전 팁 표시. 내용은 `PRO_GUIDE_CONTENT` 객체. 코드 무수정으로 텍스트만 고치려면 이 객체 편집. (검증 V8+Playwright 통과)
- **2026-05-29**: 인수인계서 전면 재구성 — 패치 누적으로 어지러워진 구조 정리. 10개 파일 명시, 검증 프로토콜 명확화, 사고 패턴 섹션 신설, AI 시스템 3가지 모드 정리, 코딩 규칙 간결화 (by Claude Opus 4.7)
- **2026-05-28c**: 🧱 5단계 파이프라인 분석 — 외부 `prompts.json` + 인라인 편집기. 시장인식→뉴스→포트→리스크→액션 누적 분석. Ollama 순차 실행에 최적. `layered_history` 저장 (최근 5)
- **2026-05-28b**: Ollama hang 해결 — 4명 병렬 → sequential. 5분 AbortController, 실시간 경과초 표시, 취소 가능. RSS 프록시 6단 확장 + 8초 per-proxy 타임아웃. serve.bat 재작성 (Microsoft Store stub 회피 · pause 보장 · 영어). serve.ps1 추가. 암호화폐 위젯을 mini-symbol-overview 그리드로 자체 구성. file:// 모드 감지 배너 + 명령 복사 버튼
- **2026-05-28**: 🏠 Ollama 통합 — provider 토글, `callOllama()`, `callAI()` 디스패처, 설치 모델 자동 감지, 연결 테스트, CORS 가이드 모달 (Windows/Mac/Linux), 비용 0 표시
- **2026-05-27-2**: 🎁 상품화 폴리시 (v1.0.0) — 토스트, 온보딩 위저드, 설정 모달, About 모달, PWA (manifest/sw/icon), README, 푸터 폴리시. 1개 파일 → 6개 파일
- **2026-05-27**: ☀️ Daily Brief + 🛡 포트폴리오 리스크 + 📊 저널 P&L (FIFO) + 🤖 종목별 AI + 🧮 퀀트 페르소나 (5명→6명)
- **2026-05-26-5**: 글로벌 속보 정확도 — 감성 NEG에 지정학·전쟁·재해 키워드 35개, `MARKET_RELEVANCE_KEYWORDS` 필터
- **2026-05-26-4d**: 🚨 TDZ 사고 — `ACTIONS.push`가 `const ACTIONS` 이전. `setTimeout(()=>...,0)` defer. Playwright 검증 의무화
- **2026-05-26-4c**: 🚨 변수 중복 사고 — `_origFlushNotesSave` 두 번 선언. `_origFlushNotesSave2`로 rename. py-mini-racer 검증 의무화
- **2026-05-26-4**: 🤖 AI 종합 분석 패널 추가 — Claude API 직접 호출, 5명 페르소나, 프롬프트 캐싱, 분석 이력, 단축키 `a`
- **2026-05-26-3**: 메모 모음 탭, 포트폴리오 메모 버튼, 저널 편집, cmdk 통합 검색
- **2026-05-26-2**: 차트 모달 메모 미리보기, ←→ 순회, cmdk 종목 통합, 로고, Export v2
- **2026-05-26**: 초기 인수인계서 + VIX/DXY 심볼 수정, 차트 모달, 자동완성, 메모 자동저장
