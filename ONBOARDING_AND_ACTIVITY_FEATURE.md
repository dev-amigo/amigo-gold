# Onboarding Timeline & Activity Tracking Feature

**Branch:** `feature/onboarding-timeline-activity`  
**Status:** ✅ Core Implementation Complete  
**Remaining:** Activity logging integration into ViewModels

---

## 📋 Features Implemented

### ✅ Phase 1: SwiftData Activity Model (COMPLETE)
- `UserActivity` model with @Model decorator
- Activity types: deposit, swap, borrow, repay, addCollateral, withdraw, loanClose
- Activity statuses: pending, completed, failed
- `ActivityService` with full CRUD operations
- Search, filter, and grouping capabilities
- Analytics methods (hasCompleted, counts)

**Files Created:**
- `PerFolio/Core/Data/Models/UserActivity.swift`
- `PerFolio/Core/Data/Services/ActivityService.swift`

### ✅ Phase 2: Onboarding Timeline UI (COMPLETE)
- Game Center-style expandable/collapsible card
- 5 timeline steps with completion tracking
- Progress indicator and animations
- Navigation shortcuts to each section

**Files Created:**
- `PerFolio/Features/Onboarding/TimelineStepCard.swift`
- `PerFolio/Features/Onboarding/OnboardingViewModel.swift`
- `PerFolio/Features/Onboarding/OnboardingTimelineView.swift`

### ✅ Phase 3: Dashboard Integration (COMPLETE)
- Fresh user detection (0 USDC, 0 PAXG)
- Show timeline for new users
- Show regular dashboard for returning users
- Navigation callbacks between tabs

**Files Modified:**
- `PerFolio/Features/Tabs/PerFolioDashboardView.swift`
- `PerFolio/Features/Tabs/PerFolioShellView.swift`

### ✅ Phase 4: Activity Tab (COMPLETE)
- Activity list with grouping by date
- Search functionality (.searchable)
- Filter by activity type
- Context menu (delete, view on Etherscan)
- Pull-to-refresh
- Empty state and loading states

**Files Created:**
- `PerFolio/Features/Activity/ActivityRowView.swift`
- `PerFolio/Features/Activity/ActivityViewModel.swift`
- `PerFolio/Features/Activity/ActivityView.swift`

### ✅ Phase 6: Tab Bar Update (COMPLETE)
- Added Activity as 5th tab
- Icon: clock.arrow.circlepath
- Tab order: Dashboard | Wallet | Borrow | Loans | Activity

**Files Modified:**
- `PerFolio/Features/Tabs/PerFolioShellView.swift`

---

## 🚧 Phase 5: Activity Logging Integration (REMAINING)

### TODO: Add Activity Logging to ViewModels

#### 1. DepositBuyViewModel
**File:** `PerFolio/Features/Tabs/DepositBuyViewModel.swift`

Add after successful deposit:
```swift
ActivityService.shared.logDeposit(
    amount: usdcAmount,
    currency: "USDC",
    txHash: nil
)
```

Add after successful swap:
```swift
ActivityService.shared.logSwap(
    fromAmount: usdcAmount,
    fromToken: "USDC",
    toAmount: paxgAmount,
    toToken: "PAXG",
    txHash: txHash
)
```

#### 2. BorrowViewModel
**File:** `PerFolio/Features/Borrow/BorrowViewModel.swift`

Add after successful borrow:
```swift
ActivityService.shared.logBorrow(
    amount: borrowAmount,
    collateral: collateralAmount,
    txHash: txHash
)
```

#### 3. ActiveLoansViewModel
**File:** `PerFolio/Features/ActiveLoans/ActiveLoansViewModel.swift`

Add after successful repay:
```swift
ActivityService.shared.logRepay(
    amount: repayAmount,
    txHash: txHash
)
```

Add after add collateral:
```swift
ActivityService.shared.logActivity(
    type: .addCollateral,
    amount: collateralAmount,
    tokenSymbol: "PAXG",
    txHash: txHash,
    description: "Added \(collateralAmount) PAXG collateral"
)
```

#### 4. WithdrawViewModel
**File:** `PerFolio/Features/Tabs/WithdrawViewModel.swift`

Add after successful withdrawal:
```swift
ActivityService.shared.logWithdraw(
    amount: usdcAmount,
    currency: "USDC",
    txHash: nil
)
```

---

## 🎨 UI/UX Highlights

### Onboarding Timeline
- **Collapsed State:** Game Center-style card with progress indicator
- **Expanded State:** 5 steps with descriptions and action buttons
- **Completion:** Green checkmarks for completed steps
- **Animation:** Smooth spring animations on expand/collapse

### Activity Tab
- **Search:** Native .searchable modifier
- **Filter:** Bottom sheet with type selection
- **Grouping:** Activities grouped by date (Today, Yesterday, etc.)
- **Icons:** Color-coded icons for each activity type
- **Context Menu:** Long-press for delete or view on Etherscan

---

## 📊 Data Flow

```
User Action (e.g., Deposit)
    ↓
ViewModel executes transaction
    ↓
On success, call ActivityService.logActivity()
    ↓
Activity saved to SwiftData
    ↓
ActivityService publishes update
    ↓
Activity tab refreshes automatically
    ↓
Onboarding timeline checks completion
```

---

## 🧪 Testing Checklist

### Onboarding Timeline
- [ ] Fresh user (0 USDC, 0 PAXG) sees timeline
- [ ] After first deposit, shows regular dashboard
- [ ] Step completion persists across app restarts
- [ ] Navigation shortcuts work correctly
- [ ] Expand/collapse animation is smooth

### Activity Tab
- [ ] Activities load on tab open
- [ ] Search filters activities correctly
- [ ] Filter by type works
- [ ] Pull-to-refresh updates list
- [ ] Activities grouped by date correctly
- [ ] Context menu delete works
- [ ] Etherscan link opens correctly

### Activity Logging
- [ ] Deposit creates activity entry
- [ ] Swap creates activity entry
- [ ] Borrow creates activity entry
- [ ] Repay creates activity entry
- [ ] Withdrawal creates activity entry
- [ ] Activities persist across app restarts

---

## 🚀 Next Steps

1. **Integrate Activity Logging:** Add logging calls to all ViewModels (Phase 5)
2. **Test End-to-End:** Complete full flow from onboarding to activity tracking
3. **Polish UI:** Fine-tune animations and transitions
4. **Performance:** Ensure SwiftData queries are optimized
5. **Merge to Main:** After thorough testing

---

## 📝 Notes

- SwiftData automatically handles persistence
- Activity search uses debounce (300ms) for performance
- Timeline completion is checked via ActivityService
- Fresh user detection happens on dashboard load
- All activities are logged with optional transaction hash

---

## ✅ Ready for Testing

The core infrastructure is complete. Once activity logging is integrated into ViewModels, the feature will be fully functional and ready for testing.

**Branch is ready for pull request after Phase 5 completion.**

