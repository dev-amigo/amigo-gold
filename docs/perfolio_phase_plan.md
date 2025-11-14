# PerFolio iOS – Phase-wise Implementation Plan

**Architecture:** Privy-based auth + RPC-first Web3 integration + Gold theme  
**Timeline:** 5 phases over 2 days for MVP demo  
**Goal:** Demo-ready iOS app mirroring web app functionality (contracts as backend, no centralized DB)

---

## Theme Tokens Reference

| Token | Value | Usage |
|-------|-------|-------|
| `primaryBackground` | `#1D1D1D` (RGB 29,29,29) | Main app background |
| `secondaryBackground` | `#242424` | Card backgrounds |
| `tintColor` | `#D0B070` | Tab indicators, accents |
| `buttonBackground` | `#9D7618` | Primary action buttons |
| `goldenBoxGradient` | `#D0B070 → #B88A3C` | Hero cards, highlights |

---

## Phase 1 – Shell, Theme & 3 Tabs ✅

**Timeline:** Day 1 – Morning  
**Goal:** Gold-themed app shell with 3 tabs, static content only (no Web3 yet)

### Tasks

#### Theme System
- Create `PerFolioTheme` structure:
  - Define all theme tokens as `Color` extensions
  - Create theme manager for consistent styling
  - Support dark mode variants
  
#### Navigation
- Build `TabView` with 3 tabs:
  1. **Dashboard** (icon: coins)
  2. **Deposit & Buy** (icon: arrow.right.left)
  3. **Withdraw** (icon: wallet)
- Use `SceneStorage` for tab persistence
- Apply global theme:
  - App background: `primaryBackground`
  - Card surfaces: `secondaryBackground`
  - Tab tint: `tintColor`
  - Primary buttons: `buttonBackground` + white text

#### Dashboard Static Layout
- **Golden Hero Card** (`goldenBoxGradient`):
  - Headline: "Your Gold Portfolio"
  - Subtitle with value placeholder
  - Static chart placeholder
  - "BUY GOLD" button (non-functional)
  
- **Two Feature Cards:**
  - "Your Gold Holdings" (PAXG/USDT static values)
  - "Get Instant Loan" (placeholder form)

#### Deposit & Buy Tab
- Section header: "Buy Crypto with INR"
- Placeholder text and form inputs

#### Withdraw Tab
- Section header: "Cash Out Your Crypto"
- Placeholder text

**Deliverable:** Gold-themed 3-tab iOS app with beautiful static UI

---

## Phase 2 – Privy Auth + Wallet + Basic RPC Reads ✅

**Timeline:** Day 1 – Afternoon  
**Goal:** Email login → embedded wallet → live on-chain balances on Dashboard

### Tasks

#### Privy Integration
- Configure Privy SDK:
  - Email-only login flow
  - `createOnLogin: "users-without-wallets"` for embedded wallet creation
  - Dark theme with gold accent (`#D0B070`)
  - Extract `user.wallet.address` after auth
  
- Post-auth flow:
  - Store wallet address securely
  - Display wallet badge + address in header
  - Add copy-to-clipboard for address

#### Web3 Client Layer
- Implement `Web3Client` service:
  - **Primary RPC:** Alchemy Ethereum Mainnet (same as web)
  - **Fallback RPC:** `https://ethereum.publicnode.com`
  - Generic `eth_call` helper for contract reads
  - Error handling with automatic fallback
  
#### ERC-20 Contract Wrapper
- Create `ERC20Contract` helper:
  - `balanceOf(address)` implementation
  - Support for:
    - **PAXG** (Paxos Gold Token)
    - **USDT** (or USDC based on vault configuration)
  - Decimal handling (PAXG: 18, USDT: 6)
  - Human-readable formatting

#### Dashboard – Live Balances
- Update "Your Gold Holdings" card:
  - **Wallet Connection Status:**
    - Active (green badge) / Not Connected (gray badge)
  - **Deposit Address:**
    - Display truncated address (e.g., `0x1234...5678`)
    - Copy button with toast feedback
  - **Live Balances:**
    - PAXG balance (from chain via RPC)
    - USDT balance (from chain via RPC)
    - Loading states (skeleton loaders)
    - Error states with retry button
  - **Action Buttons:**
    - "Deposit PAXG"
    - "Buy Gold" → links to Deposit & Buy tab

**Deliverable:** Login flow → Dashboard displays real-time on-chain PAXG & USDT balances via RPC

---

## Phase 3 – Borrow Against PAXG (Fluid Vault Integration) 🔁

**Timeline:** Day 2 – Morning  
**Goal:** User can borrow USDT against PAXG collateral using Fluid Protocol contracts

### Tasks

#### Contract Constants
- Define Ethereum mainnet addresses (from web app):
  - PAXG token address: `0x45804880De22913dAFE09f4980848ECE6EcbAf78`
  - USDT token address: `0xdAC17F958D2ee523a2206206994597C13D831ec7`
  - Fluid PAXG/USDT vault address
  - Fluid vault resolver address

#### ABI Integration
- Copy relevant ABIs from web app:
  - **ERC20:** `balanceOf`, `allowance`, `approve`
  - **Fluid Vault:** `operate(nftId, newCol, newDebt, ...)`
  - **Fluid Resolver:** `getVaultEntireData`, `positionsByUser`

#### Fluid Service Layer
- Implement `FluidService`:
  ```
  - fetchVaultConfig() → min borrow, max LTV, liquidation threshold
  - fetchUserPositions(address) → array of position NFTs
  - approvePaxgIfNeeded(amount) → ERC20 approval if needed
  - depositAndBorrow(collateral, borrowAmount) → execute operate call
  ```

#### Math Helpers
- Port calculation logic from web app:
  - `healthFactor(collateralValue, debtValue, liqThreshold)`
  - `currentLTV(collateralValue, debtValue)`
  - `liquidationPrice(collateral, debt, threshold)`
  - `maxBorrowAmount(collateral, price, maxLTV)`
  - Color-coded health status: Safe (>1.5), Warning (1.2-1.5), Danger (<1.2)

#### Dashboard – Borrow Section
- Update "Get Instant Loan" card:
  
  **Inputs:**
  - PAXG Collateral amount
    - Decimal input with precision
    - Quick percentage chips: 25% / 50% / 75% / 100% of balance
  - USDT Borrow amount
    - Auto-calculated (default 75% of max)
    - Manual override allowed
    - Real-time validation against max borrow
  
  **Loan Preview Metrics:**
  - Current gold price (from oracle or CoinGecko)
  - Loan-to-Value (LTV) percentage
  - Health Factor with color coding
  - Liquidation price
  - Available to borrow (remaining capacity)
  - Borrow APY (from resolver)
  
  **Transaction Flow:**
  - "Borrow USDT" button
  - Step 1: Approve PAXG (if needed) → show transaction pending
  - Step 2: Execute `operate` call → show transaction pending
  - Success toast with transaction hash
  - Error handling with user-friendly messages
  - Warnings if LTV > 70% or Health < 1.3

#### Dashboard – Position Management
- **Empty State:** "No active positions"
  
- **Position Cards** (one per NFT):
  - Position ID (NFT #)
  - Status badge: Healthy / Warning / At Risk
  - Health bar (visual indicator)
  - Metrics:
    - Collateral (PAXG amount + USD value)
    - Debt (USDT amount)
    - Current LTV
    - Health Factor
    - Liquidation price
  - **Action Buttons:**
    - Add Collateral
    - Repay Debt
    - Withdraw Collateral (if safe)
    - Borrow More
  - Liquidation warning banner if health < 1.2
  
- **Aggregated Stats Card:**
  - Total Collateral (across all positions)
  - Total Borrowed
  - Weighted Average Health Factor
  - Total Interest (Borrow APY)

- **Transaction History:**
  - List of recent operations (borrow, repay, withdraw)
  - Transaction hash links to Etherscan
  - Timestamps and amounts

**Deliverable:** Full borrow flow → approve PAXG → operate call → position card updates from on-chain resolver data

---

## Phase 4 – Deposit & Buy Tab with INR On-Ramp 🔁

**Timeline:** Day 2 – Afternoon  
**Goal:** INR to USDT on-ramp using OnMeta widget (same as web app)

### Tasks

#### On-Ramp Workflow UI
- **Section: "Buy Crypto with INR"**
  
  **Selectors:**
  - Fiat Currency: Default INR (locked for MVP)
  - Crypto: Fixed USDT (locked for MVP)
  - Payment Method: UPI / Bank Transfer / Card
  
  **Amount Input:**
  - INR amount field
  - Preset buttons: ₹500 / ₹1000 / ₹5000 / ₹10000
  - Min/max validation (OnMeta limits)
  - Live preview of USDT amount (simple conversion)
  
  **Button:** "Get Quote"

#### Quote Display
- **Quote Card:**
  - Provider: OnMeta (with logo/badge)
  - Amount breakdown:
    - "You pay: ₹X"
    - "Provider fee: ₹Y"
    - "Exchange rate: 1 USDT = ₹Z"
    - "You receive: ~A USDT"
  - Estimated time: "5-15 minutes"
  - Disclaimer: "Actual amount may vary slightly based on market conditions"
  
  **Button:** "Proceed to Payment"

#### OnMeta Widget Integration
- Build widget URL (mirroring web adapter):
  ```
  https://platform.onmeta.in/
    ?apiKey=<ONMETA_API_KEY>
    &walletAddress=<embedded_wallet_address>
    &fiatAmount=<amount>
    &tokenSymbol=USDT
    &fiatType=INR
    &chainId=1
    &offRamp=disabled
  ```

- Open in `SFSafariViewController`:
  - Instruction banner: "Complete your payment in the browser"
  - "Return to PerFolio after payment"
  - Handle browser close event

#### Post-Transaction Flow
- Detect app foreground (ScenePhase)
- Show loading state: "Checking for new transactions..."
- Refresh USDT balance via RPC
- Success toast: "₹X deposited! Your USDT balance updated."
- Auto-navigate to Dashboard to show new balance

#### Gold Purchase Module
- **Section: "Buy Gold (PAXG)"**
  
  **Input:**
  - USD amount to spend
  - Live gold price display ($/oz)
  - PAXG amount preview
  - USDT balance validation ("You have X USDT")
  
  **Transaction Flow:**
  - Step 1: Approve USDT if needed
  - Step 2: Swap USDT → PAXG (via DEX aggregator or direct vault deposit)
  - Success toast with transaction hash
  
  **Info Banner:**
  - "ℹ️ Gold purchases are instant and backed 1:1 by physical gold"

#### Supporting Content
- **"How It Works" Card:**
  - 3 steps: Buy USDT → Swap for PAXG → Use as collateral
  - Security badge: "Powered by Privy & Ethereum"
  
- **Gold Price Chart** (for tablet/landscape):
  - 24h price movement
  - Data from CoinGecko API

**Deliverable:** INR → USDT on-ramp via OnMeta + optional USDT → PAXG swap flow

---

## Phase 5 – Withdraw Tab + Demo Polish 🎬

**Timeline:** Day 2 – Evening  
**Goal:** Withdraw skeleton + polished demo for stakeholders

### Tasks

#### Withdraw Tab – Off-Ramp Workflow
- **Section: "Cash Out to Bank Account"**
  
  **Display:**
  - Current USDT balance (from RPC)
  - Wallet address with copy button
  
  **Inputs:**
  - USDT amount to withdraw
  - Quick buttons: 50% / Max
  - Fiat currency: INR (default)
  - Balance validation
  
  **Button:** "Start Off-Ramp (Coming Soon)"
  - Future: Open Transak widget for USDT → INR
  - URL structure similar to OnMeta

#### Withdrawal Info Card
- **Processing Time:** "Bank transfers typically take 1-2 business days"
- **Fees:** Display estimated provider fees
- **Security:** "All withdrawals are processed via secure payment partners"

#### Transaction History (Reusable Component)
- Show recent withdrawals with status:
  - Pending / Completed / Failed
  - Transaction hash links
  - Amounts and timestamps

#### UX & Copy Polish
- **Dashboard Text:**
  - Info banner: "💎 All data fetched directly from Ethereum blockchain"
  - Borrow card subtitle: "Powered by Fluid Protocol's PAXG/USDT vault"
  
- **Consistent Typography:**
  - SF Rounded weights across all tabs
  - Gold accent (`#D0B070`) for key metrics
  - Color-coded health indicators (green/yellow/red)
  
- **Loading States:**
  - Skeleton loaders for balance cards
  - Shimmer effect on data fetch
  - Manual refresh button (pull-to-refresh on scroll views)

#### Demo Script for Stakeholder
**Flow (5 minutes):**
1. **Login:**
   - Show email login → embedded wallet creation
   - Display wallet address and copy functionality

2. **Dashboard – Live Data:**
   - Point out: "These balances are live from Ethereum mainnet"
   - Show RPC endpoint info: "Using Alchemy + fallback to public node"
   - Demonstrate manual refresh

3. **Borrow Flow:**
   - Input PAXG collateral (e.g., 1 PAXG)
   - Show auto-calculated borrow amount
   - Point out health factor and LTV calculations
   - Execute approve transaction → show pending state
   - Execute operate transaction
   - Show updated position card with live data from resolver

4. **Deposit & Buy:**
   - Show INR input → Get Quote
   - Open OnMeta widget in Safari
   - (Simulate payment completion)
   - Return to app → show balance refresh

5. **Withdraw Tab:**
   - Show USDT balance
   - Explain coming soon off-ramp flow

**Key Talking Points:**
- ✅ **No centralized backend or database**
- ✅ **Same contracts, RPC providers, and math as existing web app**
- ✅ **iOS app is a thin SwiftUI layer over Web3**
- ✅ **Contracts are the backend** (Fluid Protocol + ERC20)
- ✅ **Privy provides seamless embedded wallet UX**
- ✅ **Direct RPC calls for all balance/position data**

**Deliverable:** Demo-ready iOS MVP with end-to-end flows and polished UX

---

## Phase 6 (Future) – Advanced Features

*Post-demo enhancements*

### Blockchain Service Enhancements
- Multiple RPC endpoint management with health checks
- Transaction state monitoring and confirmations
- Gas price estimation and optimization
- Batch RPC calls for efficiency
- WebSocket subscriptions for real-time updates

### Additional DeFi Features
- Multiple position management
- Position transfer/migration
- Collateral swap functionality
- Liquidation protection alerts
- Historical P&L tracking

### Provider Integrations
- Transak integration for off-ramp
- Multi-provider routing (OnMeta + Transak)
- Payment method availability checks
- Dynamic fee comparison
- Provider status monitoring

### Price Data & Charts
- CoinGecko API integration
- Real-time price updates
- Historical price charts (1D/1W/1M/1Y)
- Price alerts and notifications
- Portfolio value tracking

---

## Phase 7 (Future) – Production Readiness

*Enterprise-grade features*

### Analytics & Monitoring
- Event tracking:
  - Screen views, tab changes
  - Borrow/repay actions
  - On/off-ramp conversions
  - Transaction success/failure rates
- Crashlytics/Sentry integration
- Performance monitoring
- User journey analytics
- TVL and conversion metrics

### Testing & Quality
- Unit tests:
  - Math helpers (LTV, health factor calculations)
  - Contract interaction logic
  - RPC client with mocks
- Integration tests:
  - Borrow flow end-to-end
  - On-ramp provider routing
  - Balance refresh logic
- UI tests:
  - Complete user flows
  - Error state handling
  - Accessibility validation

### Security & Compliance
- Keychain integration for wallet keys
- Biometric authentication
- Transaction signing security
- Rate limiting
- Audit trail logging

### Accessibility & Localization
- VoiceOver support
- Dynamic Type
- High contrast mode
- Multi-language support (Hindi, English)
- RTL layout support

### Performance Optimization
- RPC response caching
- Image optimization
- Lazy loading
- Background fetch for balances
- Memory management

### App Store Preparation
- App Store assets (screenshots, videos)
- Privacy policy updates
- Terms of service
- TestFlight beta testing
- App Review guidelines compliance
- Metadata and descriptions

---

## Technical Architecture Summary

### Core Stack
- **UI:** SwiftUI (iOS 17+)
- **Auth:** Privy SDK (embedded wallets)
- **Web3:** Custom RPC client (Alchemy primary, public node fallback)
- **Contracts:** Fluid Protocol (PAXG/USDT vault)
- **On-Ramp:** OnMeta widget (INR → USDT)
- **Off-Ramp:** Transak widget (USDT → INR) - future

### Key Services
```
PerFolioApp
├── Privy Authentication
├── Web3Client (RPC)
│   ├── ERC20Contract
│   └── FluidService
├── OnMetaAdapter
├── Theme Management
└── State Management (Combine/async-await)
```

### Data Flow
```
User Action
  ↓
ViewModel
  ↓
Service Layer (Web3Client/FluidService)
  ↓
RPC Call (Alchemy/Fallback)
  ↓
Smart Contract (on-chain)
  ↓
Response Processing
  ↓
UI Update (SwiftUI @Published)
```

### No Backend Required
- All balances: RPC `eth_call` to ERC20 contracts
- All positions: RPC `eth_call` to Fluid resolver
- All transactions: Direct contract interaction via wallet
- Prices: Public APIs (CoinGecko) or on-chain oracles

---

## Success Criteria

### Phase 1-2 (Day 1)
- ✅ Beautiful gold-themed UI
- ✅ Successful Privy login flow
- ✅ Live PAXG/USDT balances displayed

### Phase 3-5 (Day 2)
- ✅ Complete borrow flow (approve + operate)
- ✅ Position data loaded from resolver
- ✅ INR on-ramp widget integration
- ✅ Demo-ready with smooth flow

### Future Phases
- Production deployment on App Store
- 1000+ active users
- $100K+ TVL in positions
- 95%+ transaction success rate
- Sub-3s balance load time

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| RPC endpoint downtime | Automatic fallback to secondary endpoint |
| Transaction failures | Clear error messages, retry mechanism |
| Privy SDK issues | Email-only login (lowest complexity) |
| OnMeta widget errors | Instruction text + support contact |
| Price data unavailable | Cached last-known value + stale indicator |
| High gas fees | Display gas estimate before transaction |

---

## Notes

- This plan prioritizes **speed to demo** over production completeness
- All core functionality mirrors the existing web app's architecture
- No custom backend/API needed – contracts are the backend
- Focus on **Ethereum mainnet only** (no L2s for MVP)
- Gold theme tokens are exact matches from design spec
- Demo script emphasizes **RPC-first, no-backend architecture**
