# PVDataStructure.md — Parsa Vault Data, Logic & Structure

> This file covers the data models, algorithms, app state, API integrations, and business logic behind Parsa Vault. It is a reference for how the app thinks and moves data around.

---

## 1. Overview

Parsa Vault is a local-first app. All user data lives on the device. There is no server-side backend in v1. API calls go out only to fetch live market prices. Everything else — users, portfolios, trades, XP — is stored locally using a local database.

As the app scales to macOS and web, a cloud sync layer can be added on top of this structure without breaking the core logic.

---

## 2. Data Models

### 2.1 User

The central record for each registered account on the device.

| Field | Type | Description |
|-------|------|-------------|
| id | String (UUID) | Unique user identifier |
| fullName | String | User's full name |
| username | String | Unique username, lowercase, no spaces |
| email | String | Unique email address |
| website | String? | Optional website URL |
| passwordHash | String | Hashed password (bcrypt or equivalent) |
| cashBalance | Double | Current virtual cash in USD |
| xp | Int | Total XP earned all time |
| level | Int | Current level (1–10) |
| createdAt | DateTime | Account creation timestamp |
| updatedAt | DateTime | Last update to this record |
| lastLoginAt | DateTime | Last time the user logged in |

**Starting values on registration:**
- cashBalance: 10,000.00
- xp: 0
- level: 1

---

### 2.2 Holding

Represents a position the user currently holds. One row per asset owned.

| Field | Type | Description |
|-------|------|-------------|
| id | String (UUID) | Unique holding ID |
| userId | String | Foreign key to User |
| symbol | String | Asset ticker (e.g. AAPL, BTC) |
| assetName | String | Full name (e.g. Apple Inc, Bitcoin) |
| assetType | Enum | "stock" or "crypto" |
| shares | Double | Number of shares/units owned |
| averageBuyPrice | Double | Average price paid per share/unit |
| lastUpdatedAt | DateTime | When this holding was last modified |

**Notes:**
- When a user buys more of an asset they already own, the averageBuyPrice is recalculated as a weighted average
- When shares drop to 0, the holding row is deleted (or marked inactive)
- Fractional shares are supported for crypto

---

### 2.3 Transaction

A permanent log of every trade, deposit, and withdrawal. Never deleted.

| Field | Type | Description |
|-------|------|-------------|
| id | String (UUID) | Unique transaction ID |
| userId | String | Foreign key to User |
| type | Enum | "buy", "sell", "deposit", "withdraw" |
| symbol | String? | Asset ticker — null for deposits/withdrawals |
| assetName | String? | Full asset name — null for deposits/withdrawals |
| assetType | Enum? | "stock", "crypto", or null |
| shares | Double? | Number of shares — null for deposits/withdrawals |
| priceAtTime | Double? | Price per share at time of trade — null otherwise |
| totalAmount | Double | Total USD value of the transaction |
| xpAwarded | Int | XP earned from this transaction |
| timestamp | DateTime | When the transaction happened |
| profitOrLoss | Double? | Gain or loss from a sell — null for buy/deposit/withdraw |

---

### 2.4 Asset (Live Data — Not Stored)

Asset data is always fetched live and held in memory. It is never written to the database.

| Field | Type | Description |
|-------|------|-------------|
| symbol | String | Ticker symbol |
| name | String | Full asset name |
| type | Enum | "stock" or "crypto" |
| currentPrice | Double | Latest price in USD |
| change24h | Double | Price change in USD over 24 hours |
| changePercent24h | Double | Percentage change over 24 hours |
| volume24h | Double? | Trading volume over 24 hours |
| marketCap | Double? | Current market cap |
| priceHistory | List<PricePoint> | List of price points for chart display |

---

### 2.5 PricePoint (Chart Data)

| Field | Type | Description |
|-------|------|-------------|
| timestamp | DateTime | Point in time |
| price | Double | Price at that time |

---

### 2.6 AppSession

Holds the current active session in memory.

| Field | Type | Description |
|-------|------|-------------|
| userId | String | ID of the logged-in user |
| token | String | Session token (local UUID) |
| createdAt | DateTime | When the session started |
| expiresAt | DateTime? | Optional expiry — null means stays until manual logout |

---

## 3. State Management

### 3.1 State Layers

| Layer | What It Holds | Persistence |
|-------|--------------|-------------|
| Local DB (SQLite/Hive) | Users, holdings, transactions, session | On device, survives restarts |
| App State (in-memory) | Logged-in user, live prices, current portfolio value | Lives during app session |
| UI State (widget/component) | Form inputs, toggles, loading booleans | Lives during screen session |

---

### 3.2 Key App-Level State

| State | Type | Description |
|-------|------|-------------|
| currentUser | User? | Null if no one is logged in |
| isLoading | Bool | Global loading flag for splash/auth checks |
| assetPrices | Map<String, Asset> | Live prices keyed by symbol |
| lastPriceRefresh | DateTime? | When prices were last fetched |
| portfolioValue | Double | Computed: cash + sum of (shares × current price) for each holding |

---

### 3.3 State Update Rules

- User data (name, XP, cash) is always read from and written to the database. Never cache user data in memory without a database write.
- Live prices are refreshed on a timer (see Section 6). The UI reads from the in-memory map.
- Portfolio value is always computed on the fly — never stored. It is: cash + (each holding's shares × current market price).
- Transaction history is always read from the database on demand — not cached in memory.

---

## 4. Authentication Flow

### 4.1 App Launch Routing

```
App opens
   ↓
Check local DB for a valid session
   ↓
Session found? → Load user → Go to Home
Session not found? → Check if any users exist in DB
   ↓
Users exist? → Go to Login
No users? → Go to Onboarding → Register
```

The splash screen shows during this check (minimum 2.5 seconds for animation).

---

### 4.2 Registration

```
User fills in form → Client validation (all required fields, email format, password strength, passwords match, username uniqueness, email uniqueness)
   ↓
Validation passes → Hash password → Write User to DB → Create Session record → Award 0 XP → Navigate to Home
   ↓
Validation fails → Show field-level errors inline
```

**Password hashing:** Use a secure one-way hash with a salt. Never store a plain-text password.

**Username rules:**
- Lowercase letters, numbers, underscores only
- 3–20 characters
- Must be unique in the local DB

---

### 4.3 Login

```
User enters email/username + password → Look up user by email or username → Compare password hash
   ↓
Match → Create new Session record → Update lastLoginAt → Check if eligible for daily login XP → Navigate to Home
   ↓
No match → Show error: "We couldn't log you in. Check your details and try again."
```

---

### 4.4 Logout

```
User confirms logout → Delete Session record from DB → Clear in-memory user state → Navigate to Login
```

---

### 4.5 Change Password

```
User enters current password + new password → Verify current password hash → Validate new password (strength, confirmation match) → Hash new password → Update User record
```

---

## 5. XP and Levelling System

### 5.1 XP Award Table

| Action | XP Awarded | Notes |
|--------|-----------|-------|
| First ever trade | +50 | One-time bonus, triggers on first buy only |
| Buy any asset | +10 | Every buy trade |
| Sell at a profit | +25 + bonus | Base 25, plus 1 XP per 1% return (capped at +50 bonus) |
| Sell at a loss | +5 | Still learning — reward participation |
| Sell at break-even | +10 | Same as a buy |
| Deposit cash | +5 | Each deposit |
| Withdraw cash | +5 | Each withdrawal |
| Daily login | +5 | Once per calendar day, awarded on login |
| Reach a new level | +0 | Level-ups are triggered by XP total — no bonus XP for level-up itself |

**Profit bonus formula:**
```
returnPercent = ((sellPrice - avgBuyPrice) / avgBuyPrice) × 100
bonusXP = min(floor(returnPercent), 50)
totalXP = 25 + bonusXP
```

Example: sold at 18% profit → 25 + 18 = 43 XP

---

### 5.2 Level Thresholds

| Level | Title | Minimum XP |
|-------|-------|-----------|
| 1 | Apprentice | 0 |
| 2 | Trader | 100 |
| 3 | Investor | 300 |
| 4 | Analyst | 600 |
| 5 | Strategist | 1,000 |
| 6 | Portfolio Manager | 1,500 |
| 7 | Fund Manager | 2,500 |
| 8 | Market Expert | 4,000 |
| 9 | Wall Street Pro | 6,000 |
| 10 | Vault Master | 9,000 |

---

### 5.3 Level Calculation

Level is always derived from total XP. It is never stored separately as a source of truth — it is computed:

```
function getLevelFromXP(xp):
  thresholds = [0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 9000]
  level = 1
  for each threshold at index i:
    if xp >= threshold:
      level = i + 1
  return level
```

---

### 5.4 XP Progress Bar Values

```
function getXPProgress(xp):
  level = getLevelFromXP(xp)
  if level == 10: return (xp, 9000, 9000)  // maxed
  currentLevelMin = thresholds[level - 1]
  nextLevelMin = thresholds[level]
  progressXP = xp - currentLevelMin
  requiredXP = nextLevelMin - currentLevelMin
  return (progressXP, requiredXP, percentage)
```

---

### 5.5 Level-Up Detection

After every XP award:
```
oldLevel = user.level
newXP = user.xp + awardedXP
newLevel = getLevelFromXP(newXP)
if newLevel > oldLevel:
  triggerLevelUpAnimation()
  showLevelUpToast(newLevel, levelTitle)
user.xp = newXP
user.level = newLevel
save to DB
```

---

## 6. Live Price Fetching

### 6.1 Data Sources

| Asset Type | Primary Source | Backup |
|------------|---------------|--------|
| Stocks | Yahoo Finance (unofficial) / Polygon.io | Alpha Vantage |
| Crypto | CoinGecko API (free tier) | Binance public API |

Use free tiers initially. Design the price-fetching layer as an abstraction so the source can be swapped without changing the rest of the app.

---

### 6.2 Refresh Strategy

| Context | Refresh Interval |
|---------|-----------------|
| Markets screen (open) | Every 30 seconds for stocks, 15 seconds for crypto |
| Trade screen (open) | Every 10 seconds |
| Home screen (on load) | Once on screen load, then every 60 seconds |
| App in background | No refresh |
| App returns to foreground | Immediate refresh |

---

### 6.3 Cache Strategy

- Live prices are cached in memory keyed by symbol
- Prices older than 5 minutes are considered stale — show a "prices may be delayed" note
- Chart data (price history) is cached per symbol per time range for the current session
- No price data is written to the local DB

---

### 6.4 Error Handling

- If a price fetch fails: use the last known price and show a subtle "delayed" indicator
- If no prices are available at all: show an error state with a refresh button
- Never block a trade because prices can't load — but warn the user that the price may be outdated

---

## 7. Trade Logic

### 7.1 Buy Trade

```
Input: symbol, shares, currentPrice

1. Validate shares > 0
2. Validate currentPrice is available
3. totalCost = shares × currentPrice
4. Validate user.cashBalance >= totalCost
5. user.cashBalance -= totalCost
6. If holding exists for symbol:
     newTotalShares = holding.shares + shares
     newAvgPrice = ((holding.shares × holding.averageBuyPrice) + (shares × currentPrice)) / newTotalShares
     holding.shares = newTotalShares
     holding.averageBuyPrice = newAvgPrice
   Else:
     Create new Holding record
7. Create Transaction record (type: "buy")
8. Award XP (+10, or +50 if first ever trade)
9. Save all to DB
10. Trigger UI update (portfolio value, holdings list, XP bar)
```

---

### 7.2 Sell Trade

```
Input: symbol, shares, currentPrice

1. Find holding for symbol
2. Validate holding exists
3. Validate shares > 0 and shares <= holding.shares
4. Validate currentPrice is available
5. totalRevenue = shares × currentPrice
6. user.cashBalance += totalRevenue
7. profitOrLoss = (currentPrice - holding.averageBuyPrice) × shares
8. holding.shares -= shares
9. If holding.shares == 0: delete holding record
10. Create Transaction record (type: "sell", includes profitOrLoss)
11. Award XP based on profit/loss rules
12. Save all to DB
13. Trigger UI update
```

---

### 7.3 Deposit

```
Input: amount

1. Validate amount > 0
2. Validate amount <= deposit limit ($50,000 per deposit — configurable)
3. user.cashBalance += amount
4. Create Transaction record (type: "deposit")
5. Award +5 XP
6. Save to DB
7. Trigger UI update
```

---

### 7.4 Withdraw

```
Input: amount

1. Validate amount > 0
2. Validate amount <= user.cashBalance
3. user.cashBalance -= amount
4. Create Transaction record (type: "withdraw")
5. Award +5 XP
6. Save to DB
7. Trigger UI update
```

---

## 8. Reset Logic

### 8.1 Reset Portfolio

Clears all holdings and transactions. Resets cash to $10,000. XP and level are kept.

```
1. Delete all Holding records for userId
2. Delete all Transaction records for userId
3. user.cashBalance = 10,000.00
4. Save user to DB
5. Navigate to Home with refreshed state
```

XP is not affected. The user keeps their level — they are resetting the money, not the knowledge.

---

### 8.2 Reset All Progress

Full wipe. Everything goes back to registration defaults.

```
1. Delete all Holding records for userId
2. Delete all Transaction records for userId
3. user.cashBalance = 10,000.00
4. user.xp = 0
5. user.level = 1
6. Save user to DB
7. Navigate to Home with refreshed state
```

---

## 9. Leaderboard Logic

The leaderboard is computed from local user data only in v1. It ranks the single user against themselves (useful when multi-user on same device or when connected to a shared backend in the future).

### 9.1 Ranking Periods

| Tab | Logic |
|-----|-------|
| All Time | Sort by user.xp descending |
| This Week | Sum xpAwarded from Transactions where timestamp is within the current ISO week |
| Today | Sum xpAwarded from Transactions where timestamp is today (local date) |

---

### 9.2 Weekly XP Calculation

```
function getXPForPeriod(userId, startDate, endDate):
  transactions = DB.query("SELECT SUM(xpAwarded) FROM transactions WHERE userId = ? AND timestamp BETWEEN ? AND ?", [userId, startDate, endDate])
  return sum or 0
```

---

### 9.3 Leaderboard Entry Structure

| Field | Value |
|-------|-------|
| rank | Position in sorted list |
| userId | ID |
| username | Display name |
| level | Computed from xp |
| levelTitle | Title at that level |
| xp | Total or period XP depending on tab |
| isCurrentUser | Boolean — true for the logged-in user's row |

---

## 10. Portfolio Value Calculation

Portfolio value is computed in real time, never stored.

```
function getPortfolioValue(user, holdings, livePrices):
  holdingsValue = 0
  for each holding in holdings:
    price = livePrices[holding.symbol]?.currentPrice ?? holding.averageBuyPrice
    holdingsValue += holding.shares × price
  return user.cashBalance + holdingsValue
```

If a live price is not available for a holding, use the average buy price as a fallback.

---

## 11. Daily Login XP Logic

Award +5 XP once per calendar day on login.

```
function checkDailyLoginXP(user):
  today = currentDate (local)
  lastLogin = user.lastLoginAt
  if lastLogin is null or date(lastLogin) < today:
    awardXP(user, 5, "daily login")
    createTransaction(type: "deposit", xpAwarded: 5, totalAmount: 0)
  user.lastLoginAt = now
  save user to DB
```

---

## 12. Data Validation Rules

### User Fields
| Field | Rule |
|-------|------|
| Full Name | Required, 2–60 characters |
| Username | Required, 3–20 characters, lowercase alphanumeric and underscores only, unique |
| Email | Required, valid email format, unique |
| Website | Optional, valid URL format if provided |
| Password | Required, minimum 8 characters |

### Trade Fields
| Field | Rule |
|-------|------|
| Shares (buy) | Must be > 0, must not make total cost exceed cash balance |
| Shares (sell) | Must be > 0, must not exceed shares owned |
| Amount (deposit) | Must be > 0, must not exceed maximum deposit limit |
| Amount (withdraw) | Must be > 0, must not exceed current cash balance |

---

## 13. Local Database Schema Summary

### Tables

**users**
- id (TEXT, PRIMARY KEY)
- fullName, username, email, website, passwordHash
- cashBalance (REAL), xp (INTEGER), level (INTEGER)
- createdAt, updatedAt, lastLoginAt (TEXT/ISO8601)

**holdings**
- id (TEXT, PRIMARY KEY)
- userId (TEXT, FOREIGN KEY)
- symbol, assetName, assetType
- shares (REAL), averageBuyPrice (REAL)
- lastUpdatedAt (TEXT)

**transactions**
- id (TEXT, PRIMARY KEY)
- userId (TEXT, FOREIGN KEY)
- type, symbol, assetName, assetType
- shares (REAL), priceAtTime (REAL), totalAmount (REAL)
- xpAwarded (INTEGER), profitOrLoss (REAL)
- timestamp (TEXT)

**sessions**
- id (TEXT, PRIMARY KEY)
- userId (TEXT, FOREIGN KEY)
- token (TEXT)
- createdAt, expiresAt (TEXT)

---

## 14. App Navigation Flow

### Flow 1 — First Launch (No Users in DB)
```
Splash → Onboarding → Register → Home
```

### Flow 2 — Returning User (Active Session)
```
Splash → Home
```

### Flow 3 — Logged Out (Users Exist, No Session)
```
Splash → Login → Home
```

### Flow 4 — Make a Trade
```
Home or Markets → Markets (select asset) → Trade → Confirm → XP awarded → Home (updated)
```

### Flow 5 — Deposit or Withdraw
```
Profile → Deposit or Withdraw → Enter amount → Confirm → XP updated → Profile (updated)
```

### Flow 6 — Reset
```
Profile → Reset button → Confirmation dialogue → Confirm → DB reset → Home or Profile (refreshed)
```

---

## 15. Multi-Platform Data Considerations

### iOS (Current)
- SQLite or Hive for local storage
- All data local to device
- No sync between devices

### macOS (Future)
- Same local database structure
- iCloud sync via CloudKit to sync data between iOS and macOS of the same user
- Conflict resolution: last-write-wins on most fields, XP always additive (never subtract from sync)

### Web (Future)
- Move to a cloud backend (Supabase or Firebase) for web support
- JWT-based authentication replaces local session token
- Real-time price subscriptions via WebSocket
- Leaderboard becomes global across all users
- Local-first design means the iOS/macOS apps can work offline and sync when connected

---

## 16. Future Features (Data Notes)

These are not in v1 but the data structure should not prevent them later:

| Feature | Data Needed |
|---------|-------------|
| Watchlist | New table: watchlist (userId, symbol) |
| Price alerts | New table: alerts (userId, symbol, targetPrice, direction, triggered) |
| Social leaderboard | Backend users table, XP synced to cloud |
| Trading streaks | Add streakDays and lastTradeDate to users table |
| Portfolio history | New table: portfolioSnapshot (userId, date, totalValue) — snapshot daily |
| Asset notes | New table: notes (userId, symbol, text, createdAt) |
