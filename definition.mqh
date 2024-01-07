// DEFITIONS AND 


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
   None
};

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
RISK AMOUNT:
   Overall Aggregated Risk Amount (Overall loss if basket fails)
   
   User Defined. 
   
   Scales True Risk Amount from Risk Profile to match this. 
   
   Scales True Lot Size based on Risk Amount
   
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
input int               InpRPHoldTime     = 5; // RISK PROFILE: Hold Time
input Orders            InpRPOrderType    = Long; // RISK PROFILE: Order Type
input ENUM_TIMEFRAMES   InpRPTimeframe    = PERIOD_M15; // RISK PROFILE: Timeframe
input float             InpRPSpread       = 10; // RISK PROFILE: Spread

input string            InpEntry          = "========== ENTRY WINDOW =========="; // ========== ENTRY WINDOW ==========
input int               InpEntryHour      = 1; // ENTRY WINDOW HOUR 
input int               InpEntryMin       = 0; // ENTRY WINDOW MINUTE

input string            InpRiskMgt        = "========== RISK MANAGEMENT =========="; // ========== RISK MANAGEMENT ==========
input float             InpRiskAmount     = 1000; // RISK AMOUNT - Scales lot to match risk amount (10 lots / 1000USD)
input float             InpAllocation     = 1; // ALLOCATION - Percentage of Total Risk
input TradeManagement   InpTradeMgt       = None; // TRADE MANAGEMENT - BE / Trail Stop
input float             InpTrailInterval  = 50; // TRAIL STOP INTERVAL - Trail Points Increment
input float             InpMinimumEquity  = 1000; // MINIMUM EQUITY - Minimum required equity to enable trading.


input string            InpMisc           = "========== MISC =========="; // ========== MISC ==========
input SpreadManagement  InpSpreadMgt      = Recursive; // SPREAD MANAGEMENT
input float             InpSpreadDelay    = 1; // SPREAD DELAY (seconds)
input int               InpMagic          = 232323; // MAGIC NUMBER


input string            InpLog            = "========== LOGGING =========="; // ========== LOGGING ==========
input bool              InpLogging        = true; // CSV LOGGING - Enables/Disables Trade Logging
input bool              InpTerminalMsg    = true; // TERMINAL LOGGING - Enables/Disables Terminal Logging

// ========== INPUTS ========== //


// ========== UI ========== //

int   UI_X        = 5;
int   UI_Y        = 400;
int   UI_WIDTH    = 235;
int   UI_HEIGHT   = 300; 

string   UI_FONT     = "Segoe UI Semibold";
string   UI_FONT_BOLD   = "Segoe UI Bold";
int   DEF_FONT_SIZE = 8;
color DEF_FONT_COLOR = clrWhite;