# PSX Portfolio Tracker — Flutter App Specification

## Overview

A mobile portfolio tracking app for Pakistan Stock Exchange (PSX) long-term investors. This is NOT a trading app — it tracks investments, shows profit/loss, provides long-term buy/hold/sell signals, and suggests market opportunities.

**Platform:** Flutter (iOS + Android)
**State Management:** Riverpod (or Provider)
**Local Storage:** Hive or SharedPreferences (for portfolio persistence)
**API:** PSX Terminal REST API (free, no auth required)
**Design:** Dark theme, mobile-first, financial data dashboard

---

## API Integration

Base URL: `https://dps.psx.com.pk` — the **official PSX Data Portal** (free, no API key, no auth).

> **History:** The app originally used `https://psxterminal.com/api`, which stopped working — its price/kline endpoints began returning HTTP 403 "Access denied" (the `/symbols` endpoint still responds but the data endpoints are dead). It was replaced with PSX's own public Data Portal, the upstream source. The portal exposes more data per call and has no documented rate limit.

### Endpoints Used

| Endpoint | Purpose | When Called |
|----------|---------|------------|
| `GET /symbols` | All PSX symbols (with name, sector, ETF/debt flags) for autocomplete | On app launch (cache locally) |
| `GET /market-watch` | Live snapshot of **every** symbol (price, change, %, day high/low, volume) — also the source for market overview gainers/losers/totals | On app launch + refresh |
| `GET /timeseries/eod/{SYMBOL}` | ~5 years of daily closing prices (one call) → 52-week high/low | On launch + refresh, for each portfolio stock |

A full refresh therefore costs `2 + N` requests (symbols + market-watch + one EOD call per portfolio stock), vs. `2 + 2N` previously.

### API Response Shapes

**`/symbols`** returns a JSON array of objects:
```json
[{ "symbol": "HBL", "name": "Habib Bank Limited", "sectorName": "COMMERCIAL BANKS", "isETF": false, "isDebt": true }]
```
Debt instruments (`isDebt: true`, e.g. TFCs/bonds) are filtered out — this is an equity tracker.

**`/market-watch`** returns an **HTML table** (parsed with the `html` package), one `<tr>` per symbol. Column order (`<td>` cells):
`symbol, sector, listed, ldcp, open, high, low, close, change, percentChange, volume, [order-book columns]`.
- Live price = `close`; day change = `change`; day % = `percentChange` (already a percentage, e.g. `"3.92%"`); day high/low = `high`/`low`; volume = `volume` (comma-formatted).
- Market stats are computed from the table: `gainers`/`losers`/`unchanged` by sign of `change`; `topGainers`/`topLosers` by sorting on `percentChange`; `totalValue` ≈ Σ(price × volume) (traded value is not exposed). `totalTrades` is unavailable (reported as 0).

**`/timeseries/eod/HBL`** returns `{ "status": 1, "data": [[timestamp, close, volume, prevClose], ...] }`, newest-first, ~5 years deep. The series has no per-day high/low, so the 52-week range is computed from **closing prices** over the most recent ~365 days (standard for a long-term range).

### Fetching Strategy

1. On app open: fetch `/symbols` (cache for autocomplete) and `/market-watch` (populates market stats **and** the in-memory live-price snapshot for all symbols in one request). Per-portfolio-stock prices are then read from that snapshot (no extra network call), and `/timeseries/eod/{SYM}` is fetched per stock for 52-week data.
2. On manual refresh (pull-to-refresh or button): re-fetch everything.
3. Show loading status: "Fetching HBL...", "Loading 52-week data for MCB...", etc.
4. Handle failures gracefully — if a stock price fails, show "—" instead of crashing.

---

## Data Models

### Stock (user's portfolio entry — stored locally)

```dart
class PortfolioStock {
  String id;           // unique ID
  String symbol;       // e.g. "HBL"
  String name;         // e.g. "Habib Bank Ltd"
  String sector;       // key from sector map, e.g. "banking"
  double avgCost;      // average purchase price per share
  int qty;             // number of shares held
}
```

### StockPrice (fetched from API — in memory only)

```dart
class StockPrice {
  double currentPrice;
  double dayChange;
  double dayChangePct;
  double dayHigh;
  double dayLow;
  int volume;
  double w52High;      // 52-week high (from klines)
  double w52Low;       // 52-week low (from klines)
}
```

### ComputedStock (derived — for display)

```dart
class ComputedStock {
  // From PortfolioStock:
  String id, symbol, name, sector;
  double avgCost;
  int qty;
  
  // From StockPrice:
  double currentPrice;
  double dayChange, dayChangePct;
  double w52High, w52Low;
  bool hasPrice;       // true if currentPrice > 0
  
  // Calculated:
  double invested;     // avgCost * qty
  double currentValue; // currentPrice * qty (or invested if no price)
  double profit;       // currentValue - invested
  double profitPct;    // (profit / invested) * 100
  double portfolioWeight; // (currentValue / totalPortfolioValue) * 100
}
```

### Sector

```dart
class Sector {
  String key;          // e.g. "banking"
  String name;         // e.g. "Banking"
  String icon;         // emoji e.g. "🏦"
  Color color;         // e.g. Color(0xFF0EA5E9)
  double invested;
  double currentValue;
  double profit;
  double profitPct;
  double investPct;    // % of total portfolio
  List<ComputedStock> stocks;
}
```

### Sector Definitions (hardcoded)

```
banking     -> Banking         🏦  #0EA5E9
energy      -> Energy & Oil    ⚡  #F59E0B
cement      -> Cement          🏗️  #8B5CF6
fertilizer  -> Fertilizer      🌿  #10B981
tech        -> Technology      💻  #EC4899
textile     -> Textile         🧵  #F97316
pharma      -> Pharma          💊  #14B8A6
auto        -> Automobile      🚗  #6366F1
fmcg        -> FMCG            🛒  #A855F7
insurance   -> Insurance       🛡️  #06B6D4
power       -> Power           💡  #EAB308
chemicals   -> Chemicals       🧪  #E11D48
telecom     -> Telecom         📡  #3B82F6
other       -> Other           📦  #94A3B8
```

---

## Long-Term Signal Engine

This is the core intelligence of the app. It generates ACCUMULATE / HOLD / BOOK PROFIT signals for each stock based on 4 factors. This is for long-term investors, NOT day traders.

### Input

- `currentPrice`: live price
- `avgCost`: user's average buy price
- `profitPct`: how much gain/loss from cost
- `w52High`: 52-week high price
- `w52Low`: 52-week low price
- `portfolioWeight`: what % this stock is of total portfolio value

### Scoring System

Start with `score = 0`. Negative score = buy signal. Positive score = sell signal. Near zero = hold.

#### Factor 1: 52-Week Position

Calculate where price sits in the yearly range:
```
w52Position = (currentPrice - w52Low) / (w52High - w52Low)
// 0.0 = at 52-week low, 1.0 = at 52-week high
```

| Condition | Score Change | Reason Text |
|-----------|-------------|-------------|
| w52Position < 0.25 | score -= 3 | "Near 52-week low — X% below yearly high. Accumulation zone." |
| w52Position 0.25–0.40 | score -= 1.5 | "In lower range of 52-week band (Xth percentile)." |
| w52Position 0.75–0.90 | score += 1.5 | "In upper 52-week range (Xth percentile)." |
| w52Position > 0.90 | score += 3 | "Near 52-week high — only X% from peak. Consider profit booking." |
| else (0.40–0.75) | no change | "Mid-range of 52-week band (Xth percentile)." |

#### Factor 2: Distance from Cost Basis

| Condition | Score Change | Reason Text |
|-----------|-------------|-------------|
| profitPct < -20% | score -= 2.5 | "X% below cost — strong averaging opportunity if thesis intact." |
| profitPct -10% to -20% | score -= 1.5 | "X% below cost. Consider averaging down." |
| profitPct > 60% | score += 2 | "X% gain — consider booking partial profits." |
| profitPct 35%–60% | score += 1 | "Healthy X% return. Let winners run." |
| profitPct 10%–35% | no change | "Moderate X% gain — hold and monitor." |
| else (-10% to +10%) | no change | "Near cost basis. Wait for clarity." |

#### Factor 3: Portfolio Concentration

| Condition | Score Change | Reason Text |
|-----------|-------------|-------------|
| weight > 20% | score += 2 | "⚠️ X% of portfolio — overweight. Consider trimming." |
| weight 12%–20% | score += 0.5 | "X% of portfolio — slightly heavy." |
| weight < 3% and profitable | score -= 0.5 | "Only X% — small position. Room to add." |

#### Factor 4: Trend Direction

```
w52Mid = (w52High + w52Low) / 2
```

| Condition | Score Change | Reason Text |
|-----------|-------------|-------------|
| price > w52Mid * 1.1 | no change | "Above 52-week midpoint — uptrend intact." |
| price < w52Mid * 0.9 | score -= 0.5 | "Below 52-week midpoint — verify fundamentals." |

#### Final Signal Mapping

| Score Range | Signal | Badge | Color | Icon |
|-------------|--------|-------|-------|------|
| score <= -4 | STRONG ACCUMULATE | STRONG ADD | Green #10B981 | 🟢 |
| -4 < score <= -2 | ACCUMULATE | ADD | Green #10B981 | 🟢 |
| -2 < score <= -0.5 | LEAN ADD | LEAN ADD | Light Green #6EE7B7 | 🟢 |
| -0.5 < score < 0.5 | HOLD | HOLD | Blue #3B82F6 | 🔵 |
| 0.5 <= score < 2 | LEAN REDUCE | LEAN SELL | Yellow #FCD34D | 🟡 |
| 2 <= score < 4 | BOOK PARTIAL | BOOK PROFIT | Amber #F59E0B | 🟡 |
| score >= 4 | STRONG REDUCE | REDUCE | Red #EF4444 | 🔴 |

Each signal includes a `reasons` list (array of strings) — one from each factor. Display all reasons in the detail view.

#### Market Opportunity Signals (for non-portfolio stocks)

For stocks in topGainers/topLosers that are NOT in the portfolio:

| Condition | Signal | Color |
|-----------|--------|-------|
| dayChangePct >= 5% | "MOMENTUM" | Green |
| dayChangePct >= 2% | "GAINING" | Light Green |
| dayChangePct <= -7% | "BIG DIP" | Amber |
| dayChangePct <= -4% | "PULLBACK" | Yellow |

---

## App Structure — 5 Tabs

Use a `BottomNavigationBar` with these tabs:

### Tab 1: Dashboard (Home) 🏠

**Summary Card** (gradient background):
- "Portfolio Value" label
- Total value in large font with monospace: `₨X.XXM`
- Profit badge: `▲ +X.XX%` (green) or `▼ -X.XX%` (red)
- Row of 3 stats: Total Invested | Total P&L | Today's P&L
- API status indicator: green dot + "14 prices loaded · 2:35 PM" or loading spinner

**Quick Insight Cards** (horizontal scroll):
- 🟢 N stocks with "Accumulate" signal
- 🟡 N stocks with "Book Profit" signal
- 📊 Total holdings count
- 🏷️ Total sectors count

**Sector Allocation** (donut chart + legend):
- SVG donut chart showing sector weights by color
- Legend: sector name + percentage for each

**Top Holdings** (first 4 stocks):
- Stock cards with signal badges
- "View all N holdings →" button at bottom

### Tab 2: Holdings 💼

**Header**: "All Holdings (N)" with sort buttons
**Sort Options**: P&L% | Value | Day Change
**Sector Filter Chips**: horizontal scroll with "All", then each sector chip (tap to filter)
**Stock Cards**: for each filtered/sorted stock

### Tab 3: Signals 🎯

**Description text**: "Long-term signals based on 52-week range, cost basis, and portfolio weight."

**Signal Category Cards** (4 in a row):
- All (total count)
- 🟢 Accumulate (count)
- 🟡 Book Profit (count)
- 🔵 Hold (count)
Tap to filter.

**Stock Cards with signals**: show signal badge + 52-week range bar + reason text

### Tab 4: Market 🔍

**Market Overview Card**:
- PSX Market Today: Gainers count | Losers count | Unchanged count
- Total symbols, volume, value

**Toggle**: 🟢 Top Gainers | 🔴 Top Losers

**Opportunity Cards**: for each non-portfolio stock:
- Symbol, price, % change, volume
- Opportunity signal badge if applicable
- Reason text

### Tab 5: Sectors 📊

**Sector Cards**: for each sector:
- Sector icon + name + stock count
- P&L % and value
- Stats row: Invested | Current | Portfolio%
- Signal summary badges: "🟢 2 accumulate", "🟡 1 book profit"
- Progress bar showing portfolio weight
- Expandable: tap to show individual stocks in sector with their signal badges

---

## UI Components

### Stock Card

Used across multiple tabs. Shows:
- Left: colored icon with first 3 letters of symbol, stock name below
- Center: mini sparkline chart (SVG/CustomPaint)
- Right: current price + P&L %
- Bottom row: Invested | Current Value | P&L | Qty
- Optional: signal badge, 52-week range bar, reason text

### Signal Badge

Small colored chip: `STRONG ADD`, `ADD`, `HOLD`, `BOOK PROFIT`, `REDUCE`
Background: signal color at 15% opacity, text in signal color.

### 52-Week Range Bar

Visual indicator showing:
- Full bar = 52-week range (low to high)
- Filled portion = current price position
- Circle dot (●) = current price
- Triangle (▲) = user's average cost
- Labels: ₨low on left, ₨high on right

### Donut Chart

Custom painted donut for sector allocation. Each slice = one sector, colored by sector color. Center text shows sector count.

### Add/Edit Stock Form (Bottom Sheet)

Fields:
1. **PSX Symbol** — text input with autocomplete dropdown. As user types, filter the symbols list fetched from `/symbols`. Show matching symbols in a dropdown. Selecting auto-fills symbol and name.
2. **Company Name** — text input (auto-filled from autocomplete, but editable)
3. **Sector** — dropdown picker with all 14 sectors (show icon + name)
4. **Average Buy Price** — number input with ₨ prefix
5. **Quantity** — number input
6. **Investment Preview** — shows calculated total (avgCost × qty) in a highlighted box
7. **Submit Button** — "＋ Add to Portfolio" or "✓ Update"

### Stock Detail Sheet (Bottom Sheet)

Opened when tapping any stock card. Shows:
- Header: symbol icon, symbol, company name, sector
- **Signal Banner**: large icon + signal name + "Long-term Signal" subtitle + all reason bullets
- **52-Week Range Bar** with current price and cost markers
- Current price (large) with day change badge
- Stats grid (2×4): Invested, Current, P&L, Return, Shares, Avg Cost, Portfolio%, Sector%
- **Edit** and **Remove** buttons (no buy/sell — this is tracking only)
- Delete confirmation inline

### Pull to Refresh

Standard Flutter `RefreshIndicator` wrapping the tab content. Triggers full data refresh.

---

## Theme / Design Tokens

### Colors

```
Background:     #0B0F1A
Card:           #131927
Card Hover:     #1A2236
Surface 1:      #1E2A3F
Surface 2:      #253349
Text Primary:   #E8ECF4
Text Secondary: #94A3B8
Text Muted:     #5E6E87
Green:          #10B981
Red:            #EF4444
Blue:           #3B82F6
Accent:         #6366F1
Amber:          #F59E0B
```

### Typography

- **Display font**: "Outfit" (Google Fonts) — weights: 400, 500, 600, 700
- **Mono font**: "JetBrains Mono" (Google Fonts) — for all numbers/prices
- All financial numbers (prices, percentages, values) use monospace font
- Labels/headers use Outfit

### Spacing & Radius

- Card padding: 14–16px
- Card margin: 0 16px 10px
- Card border radius: 14px
- Bottom sheet radius: 24px top
- Chip radius: 20px
- Button radius: 12px
- Badge radius: 4–6px

---

## Sample Data (for initial load / testing)

Pre-populate with these stocks so the app isn't empty on first launch:

```
HBL   | Habib Bank Ltd        | banking     | cost: 125.50 | qty: 500
MCB   | MCB Bank Ltd          | banking     | cost: 198.00 | qty: 300
UBL   | United Bank Ltd       | banking     | cost: 145.00 | qty: 200
OGDC  | Oil & Gas Dev Co      | energy      | cost: 89.50  | qty: 1000
PPL   | Pakistan Petroleum    | energy      | cost: 72.00  | qty: 800
PSO   | Pakistan State Oil    | energy      | cost: 210.00 | qty: 150
LUCK  | Lucky Cement          | cement      | cost: 620.00 | qty: 100
DGKC  | DG Khan Cement        | cement      | cost: 78.00  | qty: 600
EFERT | Engro Fertilizer      | fertilizer  | cost: 85.00  | qty: 700
FFC   | Fauji Fertilizer      | fertilizer  | cost: 110.00 | qty: 400
SYS   | Systems Ltd           | tech        | cost: 380.00 | qty: 200
TRG   | TRG Pakistan          | tech        | cost: 95.00  | qty: 500
SEARL | Searle Company        | pharma      | cost: 58.00  | qty: 600
INDU  | Indus Motor Co        | auto        | cost: 1280.00| qty: 50
```

---

## Key Requirements Summary

1. **No buy/sell trading** — this is a portfolio tracker only. Actions are: Add stock, Edit stock, Remove stock.
2. **Symbol autocomplete** — fetch all PSX symbols from API, show filtered dropdown as user types.
3. **Live prices on load** — automatically fetch current prices when app opens. Show loading progress. Manual refresh via button or pull-to-refresh.
4. **52-week based signals** — NOT day-trading. Use yearly high/low, cost basis distance, portfolio weight, and trend direction to generate accumulate/hold/reduce signals.
5. **Market opportunities** — show top gainers and losers from PSX that are NOT in the user's portfolio, with opportunity tags.
6. **Persistent storage** — save portfolio to local storage (Hive/SharedPreferences). Survive app restarts.
7. **Dark theme** — dark backgrounds, green for profit, red for loss, blue for hold, amber for caution.
8. **Monospace numbers** — all financial figures use JetBrains Mono or similar monospace font.
9. **Pakistani Rupee** — all currency shown as ₨ with proper formatting (K for thousands, M for millions).

---

## Flutter Package Suggestions

- `fl_chart` or `syncfusion_flutter_charts` — for donut chart, sparklines
- `hive` + `hive_flutter` — local storage
- `http` or `dio` — API calls
- `google_fonts` — Outfit + JetBrains Mono
- `riverpod` or `provider` — state management
- `intl` — number formatting
- `shimmer` — loading skeleton effects

---

## File/Folder Structure Suggestion

```
lib/
├── main.dart
├── app.dart
├── theme/
│   ├── app_theme.dart          # Colors, text styles, dark theme
│   └── app_colors.dart
├── models/
│   ├── portfolio_stock.dart
│   ├── stock_price.dart
│   ├── computed_stock.dart
│   ├── sector.dart
│   └── signal.dart
├── services/
│   ├── psx_api_service.dart    # All API calls
│   ├── storage_service.dart    # Hive/SharedPrefs
│   └── signal_engine.dart      # Long-term signal logic
├── providers/
│   ├── portfolio_provider.dart
│   ├── market_provider.dart
│   └── signal_provider.dart
├── screens/
│   ├── home_screen.dart        # Tab scaffold
│   ├── dashboard_tab.dart
│   ├── holdings_tab.dart
│   ├── signals_tab.dart
│   ├── market_tab.dart
│   └── sectors_tab.dart
├── widgets/
│   ├── stock_card.dart
│   ├── signal_badge.dart
│   ├── range_bar.dart          # 52-week range visual
│   ├── donut_chart.dart
│   ├── sparkline.dart
│   ├── progress_bar.dart
│   ├── stock_detail_sheet.dart
│   ├── stock_form_sheet.dart   # Add/Edit with autocomplete
│   ├── sector_card.dart
│   ├── insight_card.dart
│   └── market_overview_card.dart
└── utils/
    ├── formatters.dart         # ₨ formatting, pct formatting
    └── sector_data.dart        # Sector definitions map
```
