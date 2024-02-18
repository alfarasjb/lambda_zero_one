// DEFITIONS AND 
#include <MAIN/CalendarDownloader.mqh>

enum Orders{
   Long,
   Short
};

enum SpreadManagement{
   Interval, 
   Recursive,
   Ignore
};

enum TradeManagement{
   Breakeven,
   Trailing,
   OpenTrailing,
   None
};

enum PositionSizing{
   Dynamic,
   Static,
};

enum AccountType{
   Personal, 
   Challenge,
   Funded,
};

enum HistoryInterval{
   Monthly,
   Yearly,
   All
};

enum EnumLosingStreak{
   Max, 
   Last,
};

enum DrawdownScaling{
   MODE_LINEAR,
   MODE_EXPONENTIAL,
   MODE_NONE
};

enum EnumOrderSendError{
   ERR_INTERVAL_BAD_SPREAD = -10,
   ERR_INTERVAL_INVALID_PRICE = -20,
   ERR_RECURSIVE_DEADLINE_REACHED = -30,
   ERR_IGNORE_DEADLINE = -40,
   ERR_IGNORE_BAD_SPREAD = -50,
   ERR_ORDER_SEND_FAILED = -1,
      
} ERR;

enum AlgoMode{
   MODE_LIVE,
   MODE_BACKTEST,
};

enum OrderSendMethod{
   MODE_MARKET, 
   MODE_PENDING
};

// ------------------------------- TEMPLATES ------------------------------- //

struct RiskProfile{

   double            RP_amount;
   float             RP_lot, RP_spread; 
   int               RP_holdtime, RP_min_holdtime;
   Orders            RP_order_type; 
   ENUM_TIMEFRAMES   RP_timeframe;
   bool              RP_early_close;
   OrderSendMethod   RP_order_method;
   
} RISK_PROFILE;

struct TradeLog{

   double      order_open_price, order_open_spread;
   datetime    order_open_time, order_target_close_time;
   
   double      order_close_price, order_close_spread;
   datetime    order_close_time;
   
   long        order_open_ticket, order_close_ticket;

} TRADE_LOG;

struct TradeQueue{

   datetime next_trade_open, next_trade_close, curr_trade_open, curr_trade_close, curr_trade_early_close, next_trade_early_close; 
} TRADE_QUEUE;

struct ActivePosition{
   /*
   Template for holding information used for validating if trades exceeded deadlines
   */
   
   datetime    pos_open_time, pos_close_deadline;
   int         pos_ticket;
};

struct TradesActive{

   datetime    trade_open_datetime, trade_close_datetime;
   long        trade_ticket;
   int         candle_counter, orders_today;
   
   ActivePosition    active_positions[];
} TRADES_ACTIVE;

struct TradesHistory{
   datetime    trade_open_time;
   uint        ticket; 
   double      profit;
   double      rolling_balance; 
   double      max_equity; 
   double      percent_drawdown; 
};

struct PortfolioSeries{
   // Portfolio Analytics
   bool        in_drawdown, is_losing_streak; 
   double      current_drawdown_percent, max_drawdown_percent, peak_equity; 
   int         max_consecutive_losses, last_consecutive_losses, data_points;

   TradesHistory trade_history[];
} PORTFOLIO;



// ------------------------------- TEMPLATES ------------------------------- //
/*
INPUTS:
-------
// ===== RISK PROFILE ===== //
Optimized Hyperparameters from python backtest. Will be scaled accordingly based on 
input RISK AMOUNT and ALLOCATION.

Deposit: 
   Initial Deposit Conducted in main Python backtest.
   
Risk Percent:
   Optimized Risk Percent from Python Backtest.
   
Lot:
   Optimized Lot from Python Backtest
   
Hold Time:
   Optimized Hold Time from Python Backtest
   
Order Type:
   Order Type from Python Backtest
   
Timeframe:
   Timeframe from Python Backtest
   
Spread:
   Entry Window Mean Spread from Python Backtest
   
// ===== ENTRY WINDOW ===== // 
ENTRY WINDOW HOUR:
   Entry Time (Hour)
   
ENTRY WINDOW MINUTE: 
   Entry Time (Minute)
   
// ===== RISK MANAGEMENT ===== // 
BASE RISK AMOUNT:
   Overall Aggregated Risk Amount (Overall loss if basket fails)
   
   User Defined. 
   
   Scales True Risk Amount from Risk Profile to match this. 
   
   Scales True Lot Size based on Risk Amount
   
   Live - Base Risk 
   Challenge - Base * Chall Scale 
   Live Funded - Base * Live Scale
   
   Recommended: 
      Chall Scale = 2.5
      Live Funded = 0.5
   
ALLOCATION: 
   Percentage of overall RISK AMOUNT to allocate to this instrument. 
   
   Example: 
      Deposit - 100000 USD
      Risk Amount - 1000 USD (1% - specified by Risk Profile)
      Allocation - 0.3 (30% of total Risk Amount is allocated to this instrument)
      
      True Risk Amount - 1000 USD * 0.3 = 300 USD 

TRAIL INTERVAL:
   Minimum distance from market price to update trail stop. 
   
TRADE MANAGEMENT:
   Trade Management Option
      1. Breakeven -> Sets breakeven within trade window. Closes trade at deadline. 
      2. Trailing -> Updates trail stop until hit by market price. Manually closes trade if in floating loss.
      3. None -> Closes at deadline.
      
MINIMUM EQUITY:
   Minimum equity required to open a trade. 
   
   Safeguard. Prevents severe drawdown. 
   
MAX LOT: 
   Maximum Allowable lot size. 
   
   Safeguard. Prevents entering trades with disproportionate lot-account size. 
   
INITIAL DEPOSIT: 
   Initial Deposit 
   
   Used for measuring equity scaling for dynamic sizing 
   
POSITION SIZING:
   Mode for position sizing
   
   Static - uses base calculated size 
   Dynamic - scales size based on ratio of equity over initial deposit. 
  
DRAWDOWN SCALING: 
   Factor for sizing down position size when account balance is below drawdown threshold. 

ABSOLUTE DRAWDOWN THRESHOLD
   Maximum Absolute Drawdown as percentage of initial deposit that triggers drawdown scaling 
   if account balance breaches dd equity. 
   
   Ex. 
   ADT = 10%
   Deposit = 100000 
   Floor = 1 - (Deposit * (ADT / 100))
   
   If balance < Floor -> SIZE DOWN 

// ===== FUNDED ===== // 

PROFIT TARGET 
   Profit target as a percent of initial deposit. 
   
   
CHALLENGE ACCOUNT SCALING 
   Lot scaling for challenge account until profit target is reached
  
   Recommended = 2.5 
   
   
CHALLENGE ACCOUNT DRAWDOWN SCALING 
   Lot scaling for challenge account if balance breaches prop absolute drawdown threshold 
   
   Recommended = 1
   
   
LIVE ACCOUNT SCALING 
   Lot scaling for live funded account. Preferred conservative sizing to preserve account. 
   
   Recommended = 0.5
   

LIVE ACCOUNT DRAWDOWN SCALING 
   Lot scaling for live funded account if balance breaches prop absolute drawdown threshold 
   
   Recommended = 0.25 
   
MIN TARGET POINTS 
   Minimum Take Profit points allowed. Used for challenge accounts where profit target is not yet reached. 
   
   Recommended = 50 


PROP ABSOLUTE DRAWDOWN THRESHOLD
   Maximum Absolute Drawdown as percentage of initial deposit that triggers drawdown scaling 
   if account balance breaches dd equity.
   
// ===== MISC ===== // 
SPREAD MANAGEMENT:
   Technique for handling bad spreads. 
      1. Interval -> If bad spread, enters on next timeframe interval
      2. Recursive -> If bad spread, executes a while loop with a delay specified by InpSpreadDelay (seconds)
            Breaks the loop if spread improves, and price is within initial bid-ask range set with entry window
            candle opening price. (Executing recursion causes problems)
      3. Ignore -> Does nothing. Halts trading for the day.
      
SPREAD DELAY:
   Delay in seconds to execute recursive loop. 

MAGIC NUMBER:
   Magic Number
   
// ===== LOGGING ===== //
CSV LOGGING:
   Enables/Disables CSV Logging
  
TERMINAL LOGGING:
   Enables/Disables Terminal Logging   
*/

// ========== INPUTS ========== //
input string            InpRiskProfile    = "========== RISK PROFILE =========="; // ========== RISK PROFILE ==========
input float             InpRPDeposit      = 100000; // RISK PROFILE: Deposit
input float             InpRPRiskPercent  = 1; // RISK PROFILE: Risk Percent
input float             InpRPLot          = 10; // RISK PROFILE: Lot
input int               InpRPSecure       = 5; // RISK PROFILE: Early Lock Profits
input int               InpRPHoldTime     = 5; // RISK PROFILE: Hold Time
input Orders            InpRPOrderType    = Long; // RISK PROFILE: Order Type
input ENUM_TIMEFRAMES   InpRPTimeframe    = PERIOD_M15; // RISK PROFILE: Timeframe
input float             InpRPSpread       = 10; // RISK PROFILE: Spread
input bool              InpRPEarlyClose   = true; // RISK PROFILE: Early Close
input OrderSendMethod   InpOrderMethod    = MODE_MARKET; // RISK PROFILE: Order Send Method

input string            InpEntry          = "========== ENTRY WINDOW =========="; // ========== ENTRY WINDOW ==========
input int               InpEntryHour      = 0; // ENTRY WINDOW HOUR 
input int               InpEntryMin       = 0; // ENTRY WINDOW MINUTE

input string            InpRiskMgt        = "========== RISK MANAGEMENT =========="; // ========== RISK MANAGEMENT ==========
input AccountType       InpAccountType    = Personal; // ACCOUNT TYPE - Account Type
input float             InpRiskAmount     = 1000; // BASE RISK AMOUNT - Scales lot to match risk amount (10 lots / 1000USD) 
input float             InpAllocation     = 1; // ALLOCATION - Percentage of Total Risk
input TradeManagement   InpTradeMgt       = None; // TRADE MANAGEMENT - BE / Trail Stop
input float             InpTrailInterval  = 50; // TRAIL STOP INTERVAL - Trail Points Increment
input double            InpCutoff         = 0.85; // EQUITY CUTOFF - Once equity breaches cutoff, trading is disabled.
input float             InpMaxLot         = 1; // MAX LOT - Maximum Allowable Lot 
input PositionSizing    InpSizing         = Dynamic; // POSITION SIZING - Position Sizing
input float             InpDDScale        = 0.5; // DRAWDOWN SCALING
input float             InpAbsDDThresh    = 10; // ABSOLUTE DRAWDOWN THRESHOLD
input HistoryInterval   InpHistInterval   = All; // HISTORY INTERVAL - Tracking Equity Drawdown
input int               InpMinLoseStreak  = 3; // MINIMUM CONSECUTIVE LOSING TRADES
input double            InpEquityDDThresh = 5; // EQUITY DRAWDOWN THRESHOLD
input DrawdownScaling   InpDrawdownScale  = MODE_LINEAR; // DRAWDOWN SCALING TYPE

input string            InpFunded         = "========== FUNDED =========="; // ========== FUNDED ==========
input float             InpProfitTarget   = 10; // PROFIT TARGET 
input float             InpChallScale     = 2.5; // CHALLENGE ACCOUNT SCALING
input float             InpChallDDScale   = 1; // CHALLENGE ACCOUNT DRAWDOWN SCALING 
input float             InpLiveScale      = 0.5; // LIVE ACCOUNT SCALING
input float             InpLiveDDScale    = 0.25; // LIVE ACCOUNT DRAWDOWN SCALING
input float             InpMinTargetPts   = 50; // MIN TP POINTS
input float             InpPropDDThresh   = 5; // CHALLENGE ACCOUNT DRAWDOWN THRESHOLD 
input int               InpTPSpreadThresh = 50; // TP Points Ceiling to Ignore RP Spread. 

input string            InpMisc           = "========== MISC =========="; // ========== MISC ==========
input SpreadManagement  InpSpreadMgt      = Recursive; // SPREAD MANAGEMENT
input float             InpSpreadDelay    = 1; // SPREAD DELAY (seconds)
input int               InpMagic          = 232323; // MAGIC NUMBER
input bool              InpShowUI         = false; // SHOW UI
input bool              InpTradeOnNews    = false; // TRADE ON NEWS
input Source            InpNewsSource     = R4F_WEEKLY; // NEWS SOURCE

input string            InpLog            = "========== LOGGING =========="; // ========== LOGGING ==========
input bool              InpLogging        = true; // CSV LOGGING - Enables/Disables Trade Logging
input bool              InpTerminalMsg    = true; // TERMINAL LOGGING - Enables/Disables Terminal Logging
input bool              InpPushNotifs     = false; // PUSH NOTIFICATIONS

input string            InpBacktest       = "========== BACKTEST =========="; // ========== BACKTEST ==========
input bool              InpUseDummy       = false; // USE DUMMY DEPOSIT
input double            InpDummyDeposit   = 100000; // BACKTEST DUMMY DEPOSIT - For strategy tester
input string            InpBacktestStart  = "2020.01.01"; // BACKTEST START DATE 
input bool              InpDebugLogging   = false; // DEBUG LOGGING
input AlgoMode          InpMode           = MODE_LIVE; // DEPLOYMENT MODE
// ========== INPUTS ========== //
/*


*/

// ========== UI ========== //

int   UI_X        = 5;
int   UI_Y        = 130;
int   UI_WIDTH    = 235;
int   UI_HEIGHT   = 300; 

string   UI_FONT     = "Segoe UI Semibold";
string   UI_FONT_BOLD   = "Segoe UI Bold";
int   DEF_FONT_SIZE = 8;
color DEF_FONT_COLOR = clrWhite;

// Syntax: <Abbreviation>-<Date Deployed>-<Base Version>
// DO NOT CHANGE
const string EA_ID = "LZO-010124-2";
const string FXFACTORY_DIRECTORY = "lambda_zero_one\\ff_news";
const string R4F_DIRECTORY = "lambda_zero_one\\r4f_news";