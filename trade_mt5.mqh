// MAIN TRADING CLASS
#ifdef __MQL5__
#include <Trade/Trade.mqh>
CTrade Trade;
CDealInfo DealInfo;
#endif 


#include "definition.mqh"




// ------------------------------- CLASS ------------------------------- //

class CIntervalTrade{

   protected:
   private:
      
      
   public: 
      // TRADE PARAMETERS
      float       order_lot;
      double      entry_price, sl_price, tp_price, tick_value, trade_points, delayed_entry_reference, true_risk, true_lot, ACCOUNT_DEPOSIT, ACCOUNT_CUTOFF;
      
      // FUNDED 
      double      funded_target_equity, funded_target_usd; 
      
      CIntervalTrade();
      ~CIntervalTrade(){};
      
      // INIT 
      void              SetRiskProfile();
      void              SetFundedProfile();
      void              InitializeSymbolProperties();
      double            CalcLot();
      double            ValueAtRisk();
      
      // ENCAPSULATION
      double            TICK_VALUE()      { return tick_value; }
      double            TRADE_POINTS()    { return trade_points; }
      double            TRUE_RISK()       { return true_risk; }
      
      
      // TRADE PARAMS
      void              TradeParamsLong(string trade_type);
      void              TradeParamsShort(string trade_type);
      void              GetTradeParams(string trade_type);
      double            ClosePrice();
      void              SetDelayedEntry(double price);
      bool              DelayedEntryPriceValid();
      
      // TRADE LOG 
      void              SetOrderOpenLogInfo(double open_price, datetime open_time, datetime target_close_time, long ticket);
      void              SetOrderCloseLogInfo(double close_price, datetime close_time, long ticket);
      
      // TRADE QUEUE
      void              SetNextTradeWindow();
      datetime          WindowCloseTime(datetime window_open_time);
      bool              IsTradeWindow();
      bool              IsNewDay();
      
      // TRADES ACTIVE
      void              SetTradeOpenDatetime(datetime trade_datetime, long ticket);
      void              SetTradeCloseDatetime();
      bool              CheckTradeDeadline(datetime trade_open_time);
      void              AppendActivePosition(ActivePosition &active_pos);      
      bool              TradeInPool(int ticket);
      void              AddOrderToday();
      void              ClearOrdersToday();
      void              ClearPositions();
      int               NumActivePositions();
      int               RemoveTradeFromPool(int ticket);
      
      // MAIN METHODS
      bool              UpdateCSV(string log_type); //
      bool              DelayedAndValid(); //
      int               SendMarketOrder(); //
      int               SendLimitOrder(); //
      int               CloseOrder(); //
      int               WriteToCSV(string data_to_write, string log_type); //
      int               OrdersEA(); //
      bool              ModifyOrder();//
      int               SetBreakeven(); //
      int               TrailStop(); //
      int               TrailStopsOnClose();
      void              CheckOrderDeadline();
      bool              CorrectPeriod();
      bool              ValidTradeOpen();
      bool              MinimumEquity();
      bool              IsRiskFree(int ticket);
      bool              OrderIsClosed(int ticket);
      
      
      
      // FUNDED
      float             RiskScaling();
      double            CalcTP(int ticket);
      double            CalcTradePoints(double target_amount);
      bool              ProfitTargetReached();
      bool              EvaluationPhase();
      bool              BelowAbsoluteDrawdownThreshold();
      bool              BelowEquityDrawdownThreshold();
      bool              EquityReachedProfitTarget();
      double            EquityDrawdownScaleFactor();
      double            SetChallengeAccountTakeProfit();
      bool              IsUnderperforming();
      
      // TRADE OPERATIONS
      
      int               PosTotal();
      int               PosTicket();
      double            PosLots();
      string            PosSymbol();
      int               PosMagic();
      datetime          PosOpenTime();
      datetime          PosCloseTime();
      double            PosOpenPrice(); 
      double            PosProfit();
      ENUM_ORDER_TYPE   PosOrderType();
      double            PosSL();
      double            PosTP();
      int               PosHistTotal();
      double            PosCommission();
      
      int               OP_OrdersCloseAll();
      int               OP_CloseTrade(int ticket);
      int               OP_OrderOpen(string symbol, ENUM_ORDER_TYPE order_type, double volume, double price, double sl, double tp);
      bool              OP_TradeMatch(int index);
      int               OP_OrderSelectByTicket(int ticket);
      int               OP_OrderSelectByIndex(int index);
      int               OP_HistorySelectByIndex(int index);
      int               OP_ModifySL(double sl);
      int               OP_ModifyTP(double tp);
      int               OP_SelectTicket(); // mql5 only
      
      // UTILITIES AND WRAPPERS
      double            util_tick_val();
      double            util_trade_pts();
      double            util_last_candle_open();
      double            util_last_candle_close();    
      double            util_entry_candle_open();
      int               util_shift_to_entry();
      double            util_market_spread();
      double            util_price_ask();
      double            util_price_bid();
      int               util_interval_day();
      int               util_interval_current();
      double            util_delayed_entry_reference();
      ENUM_ORDER_TYPE   util_market_ord_type();
      ENUM_ORDER_TYPE   util_pending_ord_type();
      int               util_is_pending(ENUM_ORDER_TYPE ord_type);
      double            util_trade_diff();
      double            util_trade_diff_points();
      double            util_symbol_minlot();
      double            util_symbol_maxlot();
      
      
      double            account_balance();
      double            account_equity();
      string            account_server();
      double            account_deposit();
      
      int               logger(string message, bool notify = false, bool debug = false);
      void              errors(string error_message);
      bool              notification(string message);
      
      
      // HISTORY
      void              InitHistory();
      double            HighestEquity();
      int               ConsecutiveLosses(EnumLosingStreak losing_streak = Max);
      bool              OnLosingStreak();
      void              ClearHistory();
      bool              IsHistoryUpdated();
      int               AppendToHistory(TradesHistory &history);
      TradesHistory     LastEntry(); // return the last entry as struct
      void              UpdatePortfolioValues(TradesHistory &history);
      void              UpdateHistoryWithLastValue();
      int               PortfolioHistorySize();
      bool              BreachedConsecutiveLossesThreshold();
      bool              BreachedEquityDrawdownThreshold();
      ulong             PortfolioLatestTradeTicket();
      bool              TicketInPortfolioHistory(int ticket);
      bool              AccountInDrawdown();
      double            LatestTradeIsLoss();
};


// ------------------------------- CLASS ------------------------------- //

CIntervalTrade::CIntervalTrade(void){
   InitializeSymbolProperties();
   ACCOUNT_DEPOSIT = account_deposit();
   ACCOUNT_CUTOFF = ACCOUNT_DEPOSIT * InpCutoff;
   TRADES_ACTIVE.candle_counter = 0;
   TRADES_ACTIVE.orders_today = 0;
}

void CIntervalTrade::InitializeSymbolProperties(void){
   tick_value = util_tick_val();
   trade_points = util_trade_pts();
}


// ------------------------------- HISTORY ------------------------------- //

/*

NEEDED:
track history as struct
track consecutive losses for sizing down. 
track equity drawdown 

METHODS: 

Check history list if data is already tracked. 

If number of items in history struct is not equal to the number of trades
in history, recalculate everything. only do this every new day, or every closed trade. 

Append to history - called when trade is closed. 

current drawdown 
*/

void CIntervalTrade::InitHistory(void){
   
   /*
   Initializes history data. Iterates through Account History to generate portfolio analytics (drawdown, etc)
   
   Mainly used for scaling down on losing streaks. 
   */

   int num_history = PosHistTotal();
   //int year = 2024;
   int month = 1;
   
   double peak = ACCOUNT_DEPOSIT;
   double cumulative_profit = 0;
   double max_drawdown_pct = 0;
   
   
   MqlDateTime current; 
   TimeToStruct(TimeCurrent(), current);
   
   int current_year = current.year;
   
   for (int i = 0; i < num_history; i ++){
      
      int s = OP_HistorySelectByIndex(i);
      double profit = PosProfit(); 
      uint ticket = PosTicket();
      datetime open_time = PosOpenTime();
      
      MqlDateTime OrderOpenTimeStruct; 
      
      TimeToStruct(open_time, OrderOpenTimeStruct);
      
      
      if (OrderOpenTimeStruct.year != current_year && InpHistInterval == Yearly) continue;
      if (OrderOpenTimeStruct.mon != month && InpHistInterval == Monthly && OrderOpenTimeStruct.year != current_year) continue; 
      if (profit == 0 || profit == ACCOUNT_DEPOSIT) continue;
      
      // Append P/L 
      cumulative_profit += profit; 
      
      // calculate rolling equity and drawdown 
      double rolling_equity = ACCOUNT_DEPOSIT + cumulative_profit; 
      peak = rolling_equity > peak ? rolling_equity : peak;
      
      double drawdown = rolling_equity < peak ? (1 - (rolling_equity / peak)) * 100 : 0;
      
      max_drawdown_pct = drawdown > max_drawdown_pct ? drawdown : max_drawdown_pct;
      
      TradesHistory TRADE_HISTORY; 
      TRADE_HISTORY.trade_open_time = open_time;
      TRADE_HISTORY.ticket = ticket;
      TRADE_HISTORY.profit = profit;
      TRADE_HISTORY.rolling_balance = rolling_equity; 
      TRADE_HISTORY.max_equity = peak; 
      TRADE_HISTORY.percent_drawdown = drawdown;
      
      // APPEND TO PORTFOLIO 
      AppendToHistory(TRADE_HISTORY);
      
   }
   
   
   PORTFOLIO.peak_equity = peak; 
   PORTFOLIO.in_drawdown = AccountInDrawdown();
   PORTFOLIO.current_drawdown_percent = PORTFOLIO.in_drawdown ? (1 - (account_balance() / PORTFOLIO.peak_equity)) * 100 : 0; 
   PORTFOLIO.is_losing_streak = OnLosingStreak(); 
   PORTFOLIO.max_consecutive_losses = ConsecutiveLosses();
   PORTFOLIO.last_consecutive_losses = ConsecutiveLosses(Last);
   PORTFOLIO.max_drawdown_percent = max_drawdown_pct;
   PORTFOLIO.data_points = PortfolioHistorySize();
   
   logger(StringFormat("Initialized History. %i data points found.", PORTFOLIO.data_points));
   logger(StringFormat("Drawdown: %i, DD Percent: %f, Losing Streak: %i, Last Consecutive: %i, Peak: %f, Current: %f", 
      PORTFOLIO.in_drawdown, PORTFOLIO.current_drawdown_percent, PORTFOLIO.is_losing_streak, PORTFOLIO.last_consecutive_losses,
      PORTFOLIO.peak_equity, account_balance()));
}


int CIntervalTrade::ConsecutiveLosses(EnumLosingStreak losing_streak = Max){
   /*
   iterate through portfolio and determines number of consecutive losses. 
   
   Used for scaling down losing streaks. 
   */
   
   int num_portfolio = PortfolioHistorySize();
   int streak = 0; // tracks streak. reset to 0 if profit is > 0
   int max_losses = 0; // tracks maximum losses. replaced everytime streak > 0 
   
   double consecutive_losses[]; 
   double current_streak[];
   
   for (int i = num_portfolio - 1; i >= 0; i--){
   
      TradesHistory portfolio = PORTFOLIO.trade_history[i]; // each item in portfolio list created by inithistory
      
      if (portfolio.trade_open_time < 2024) continue;
      if (portfolio.profit >= 0 || i == 0) { // resets everything if streak ends by: winning a trade, or last item in the list. 
         if (streak > max_losses) {
            // replace max losses 
            max_losses = streak; 
            // reset consecutive losses, resize to match max losses, copy current streak 
            ArrayFree(consecutive_losses);
            ArrayResize(consecutive_losses, max_losses);
            ArrayCopy(consecutive_losses, current_streak);
            if (losing_streak == Last) return max_losses;
            
         }
         streak = 0; // reset streak and continue
         ArrayFree(current_streak);
         continue;
      }
      
      // append current p/l to losing streak list 
      int size = ArraySize(current_streak);
      ArrayResize(current_streak, size + 1);
      current_streak[size] = portfolio.profit;
      
      streak++; // increment if profit < 0 
   }
     
   
   return max_losses;
}

bool CIntervalTrade::OnLosingStreak(void){
   
   /*
   Checks last entry in account history if p/l. 
   
   Returns True if last trade is at a loss. 
   */
   
   int size = ArraySize(PORTFOLIO.trade_history);
   if (size <= 0) return false; 
   TradesHistory history = PORTFOLIO.trade_history[size - 1]; 
   if (history.profit < 0) return true;
   return false;   
}

void CIntervalTrade::ClearHistory(void){
   /*
   Clears portfolio data. 
   */
   ArrayFree(PORTFOLIO.trade_history);
   ArrayResize(PORTFOLIO.trade_history, 0);
   PORTFOLIO.peak_equity = 0;
   PORTFOLIO.in_drawdown = 0;
   PORTFOLIO.current_drawdown_percent = 0;
   PORTFOLIO.is_losing_streak = 0;
   PORTFOLIO.max_consecutive_losses = 0;
   PORTFOLIO.last_consecutive_losses = 0;
   PORTFOLIO.max_drawdown_percent = 0;
   
}

bool CIntervalTrade::IsHistoryUpdated(void){

   /*
   Boolean validation for checking if stored history data in portfolio matches account history. 
   
   Returns false on mismatch, true if otherwise. 
   */

   int size = PortfolioHistorySize();
   if (size <= 0) return false; 
   
   TradesHistory history = PORTFOLIO.trade_history[size - 1];
   if (PortfolioHistorySize() < PosHistTotal()) return false; 
   return true;
}

TradesHistory CIntervalTrade::LastEntry(void){

   /*
   Gets last entry in account history and stores into TRADE_HISTORY struct. 
   */

   int num_history = PosHistTotal();
   //int s = OrderSelect(num_history - 1, SELECT_BY_POS, MODE_HISTORY);
   int s = OP_HistorySelectByIndex(num_history - 1);
   int size = PortfolioHistorySize();
   
   //double stored_max_equity = size == 0 ? 0 : PORTFOLIO.trade_history[size - 1].max_equity; 
   double stored_max_equity = PORTFOLIO.peak_equity == 0 ? ACCOUNT_DEPOSIT : PORTFOLIO.peak_equity;
   
   TradesHistory TRADE_HISTORY; 
   TRADE_HISTORY.trade_open_time = PosOpenTime();
   TRADE_HISTORY.ticket = PosTicket();
   TRADE_HISTORY.rolling_balance = account_balance();
   TRADE_HISTORY.profit = PosProfit();
   TRADE_HISTORY.max_equity = stored_max_equity; 
   TRADE_HISTORY.percent_drawdown = TRADE_HISTORY.rolling_balance < TRADE_HISTORY.max_equity ? (1 - (TRADE_HISTORY.rolling_balance / TRADE_HISTORY.max_equity)) * 100 : 0; 
   
   return TRADE_HISTORY;
}

void CIntervalTrade::UpdatePortfolioValues(TradesHistory &history){

   /*
   Updates portfolio analytics based on latest data in account history. 
   */
   PORTFOLIO.data_points = PortfolioHistorySize();
   PORTFOLIO.peak_equity = history.rolling_balance > PORTFOLIO.peak_equity ? history.rolling_balance : PORTFOLIO.peak_equity; 
   PORTFOLIO.in_drawdown = AccountInDrawdown();
   PORTFOLIO.current_drawdown_percent = PORTFOLIO.in_drawdown ? (1 - (account_balance() / PORTFOLIO.peak_equity)) * 100 : 0; 
   PORTFOLIO.is_losing_streak = OnLosingStreak(); 
   PORTFOLIO.max_consecutive_losses = ConsecutiveLosses();
   PORTFOLIO.last_consecutive_losses = ConsecutiveLosses(Last);
   PORTFOLIO.max_drawdown_percent = history.percent_drawdown > PORTFOLIO.max_drawdown_percent ? history.percent_drawdown : PORTFOLIO.max_drawdown_percent;
   //PrintFormat("HISTORY: %f, MAX: %f", history.percent_drawdown, PORTFOLIO.max_drawdown_percent);
   //Print(history.percent_drawdown);
}

void CIntervalTrade::UpdateHistoryWithLastValue(void){

   /*
   Updates PORTFOLIO data with the latest data in account history. 
   */

   // latest entry in account history. 
   TradesHistory history = LastEntry(); 

   
   int size = PortfolioHistorySize();
   ArrayResize(PORTFOLIO.trade_history, size + 1);
   PORTFOLIO.trade_history[size] = history;
   
   UpdatePortfolioValues(history);
   
   
   
   logger(StringFormat("Updated History. Latest: %i", PortfolioLatestTradeTicket()));
   
   logger(StringFormat("Drawdown: %i, DD Percent: %f, Losing Streak: %i, Last Consecutive: %i, Peak: %f, Current: %f", 
      PORTFOLIO.in_drawdown, PORTFOLIO.current_drawdown_percent, PORTFOLIO.is_losing_streak, PORTFOLIO.last_consecutive_losses,
      PORTFOLIO.peak_equity, account_balance()));
}

int CIntervalTrade::AppendToHistory(TradesHistory &history){
   /*
   Appends trade history to portfolio history. 
   */
   int size = PortfolioHistorySize(); 
   
   ArrayResize(PORTFOLIO.trade_history, size + 1); 
   PORTFOLIO.trade_history[size] = history; 
   
   return PortfolioHistorySize();  
}

ulong CIntervalTrade::PortfolioLatestTradeTicket(void){

   /*
   Returns ticket of the latest entry stored in portfolio history. 
   */
   
   int size = PortfolioHistorySize();
   
   if (size == 0) return 0; 
   
   ulong latest_ticket = PORTFOLIO.trade_history[size - 1].ticket;
   return latest_ticket;
}

bool CIntervalTrade::TicketInPortfolioHistory(int ticket){
   /*
   Checks input ticket if it is already stored in portfolio history. 
   
   Ideally, this function should be called prior to appending to portfolio history. 
   
   Limitation: Only checks last stored ticket, not the ones prior. 
   */
   
   int size = PortfolioHistorySize();
   
   if (size == 0) return false; 
   if (ticket == PortfolioLatestTradeTicket()) return true; 
   return false; 
   
}

int CIntervalTrade::PortfolioHistorySize(void) { return ArraySize(PORTFOLIO.trade_history); }
bool CIntervalTrade::AccountInDrawdown(void)   { return account_balance() < PORTFOLIO.peak_equity; }
// ------------------------------- HISTORY ------------------------------- //


// ------------------------------- FUNDED ------------------------------- //


/*
FUNDED NOTES: 

Scale Lot and risk until target equity is reached, then normalize (1). 
Calculate TP until target equity is reached, then normalize (0)

SAFEGUARD CHALLENGE DRAWDOWN Size Down to 1 

** USE TRAILING STOP 
*/
void CIntervalTrade::SetFundedProfile(void){

   funded_target_usd = ACCOUNT_DEPOSIT * (InpProfitTarget / 100);
   funded_target_equity = ACCOUNT_DEPOSIT + funded_target_usd;
}


float CIntervalTrade::RiskScaling(void){
   /*
   Scales lot size based on account type and drawdown rules.
   
   Personal Account: 
      DD Scale = 0.5 
      Default = 1;
      
   Challenge: 
      ProfitTargetReached = Live
      DD Scale = Input (ChallDDScale)
      Default = Challenge (Input)
      
   Funded:
      DD Scale = Input (ChallDDScale)
      Default = Live
      
      
   */
   switch(InpAccountType){
      case Personal: 
         if (IsUnderperforming()) return InpDDScale;
         return 1; 
         break;
         
      case Challenge:
         if (BelowAbsoluteDrawdownThreshold()) {
            if (!ProfitTargetReached()) return InpChallDDScale;
            return InpLiveDDScale;
         }
         
         if (ProfitTargetReached() && IsUnderperforming()) return InpLiveDDScale;
         if (ProfitTargetReached()) return InpLiveScale;
         return InpChallScale;
         break;
         
      case Funded:
         if (IsUnderperforming()) return InpLiveDDScale;
         return InpLiveScale;
         break;
         
      default: 
         return 1; 
         break;
   }
}

bool CIntervalTrade::IsUnderperforming(void){
   /*
   Equity Drawdown: Portfolio in drawdown, balance below equity drawdown threshold
   Absolute Drawdown: Portfolio in drawdown, balance below absolute drawdown threshold 
   Consecutive Losses: Portfolio in drawdown, last N consecutive trades are losers. 
   */
   if (BelowEquityDrawdownThreshold() || BelowAbsoluteDrawdownThreshold() || BreachedConsecutiveLossesThreshold()) return true;
   return false;
}

double CIntervalTrade::CalcTP(int ticket){
   /*
   Calculates TP Points. 
   
   Used with challenge account, sets a take profit needed to achieve profit target. 
   */
   
   double commission = PosCommission();
   
   double current_account_profit = account_balance() - ACCOUNT_DEPOSIT; 
   
   double remaining_profit_target = funded_target_usd - current_account_profit + commission; // add commission here 
   
   
   
   double take_profit_points = (remaining_profit_target) / (CalcLot() * tick_value * (1 / trade_points)); 
   double points = take_profit_points / trade_points;
   
   double tp = entry_price + take_profit_points;
   
   if (points < InpMinTargetPts) return (InpMinTargetPts * trade_points);
  
   
   return take_profit_points;   
}



bool CIntervalTrade::ProfitTargetReached(void){
   /*
   Boolean validtion for checking if account balance is below target equity.
   
   Returns false if profit target is not yet reached. 
   True if otherwise
   */
   if (account_balance() < funded_target_equity) return false; 
   return true; 
}

bool CIntervalTrade::EvaluationPhase(void){
   /*
   Boolean validation for checking if account is still in evaluation phase (below target equity.)
   */
   if (InpAccountType == Challenge && !ProfitTargetReached()) return true;
   return false;
}

bool CIntervalTrade::BelowAbsoluteDrawdownThreshold(void){
   /*
   Boolean Validation. Checks if current balance is below threshold of drawdown. 
   
   If current balance is below drawdown threshold, algo must size down. 
   
   Returns true if current balance is below threshold. 
   False if otherwise. 
   
   Example: 
   Chall Thresh - 5% 
   deposit = 100000 
   threshold = 95000 
   balance = 98000 -> false 
   balance = 93000 -> false
   
   Safeguard for Challenge MaxDD
   */
   
   double threshold = InpAccountType == Personal ? InpAbsDDThresh : InpPropDDThresh; 
  
   
   double equity_threshold = ACCOUNT_DEPOSIT * (1 - (threshold / 100));
   
   if (account_balance() < equity_threshold) return true; 
   return false;
}

bool CIntervalTrade::BelowEquityDrawdownThreshold(void){
   double threshold = InpAccountType == Personal ? InpEquityDDThresh : InpPropDDThresh; 
   
   double equity_threshold = PORTFOLIO.peak_equity * (1 - (threshold / 100));
   
   if (PORTFOLIO.in_drawdown && (account_balance() < equity_threshold)) return true; 
   return false;
}

bool CIntervalTrade::EquityReachedProfitTarget(void){
   /*
   Boolean validation for checking if account equity has reached profit target. 
   
   Difference with ProfitTargetReached is that this method is called on tick instead of 
   per trade. 
   
   Used for manually closing if equity ticks above target equity. 
   */
   
   if ((account_equity() >= funded_target_equity) && (account_balance() < funded_target_equity)) return true; 
   return false;
}

double CIntervalTrade::EquityDrawdownScaleFactor(void){
   // UNDER CONSTRUCTION
   
   /*
   Find a non-linear function to scale lots using drawdown percentage and consecutive losses. 
   */
   if (!PORTFOLIO.in_drawdown) return 1; 
   
   return 1; 
}

bool CIntervalTrade::BreachedConsecutiveLossesThreshold(void){
   //if (PORTFOLIO.last_consecutive_losses < InpMinLoseStreak && !AccountInDrawdown() && !LatestTradeIsLoss()) return false;
   //return true;
   if (PORTFOLIO.last_consecutive_losses > InpMinLoseStreak && LatestTradeIsLoss()) return true; 
   return false;
}

bool CIntervalTrade::BreachedEquityDrawdownThreshold(void){
   if (PORTFOLIO.current_drawdown_percent < InpEquityDDThresh) return false;
   return true;
}

double CIntervalTrade::LatestTradeIsLoss(void){
   int t = PortfolioLatestTradeTicket();
   
   OP_OrderSelectByTicket(t);
   
   if (PosProfit() >= 0) return false;
   Print("LOSS");
   return true;
}
// ------------------------------- FUNDED ------------------------------- //


// ------------------------------- INIT ------------------------------- //

void CIntervalTrade::SetRiskProfile(void){
      /*
      Initializes risk profile based on inputs.
      */
      RISK_PROFILE.RP_amount = (InpRPRiskPercent / 100) * InpRPDeposit;
      RISK_PROFILE.RP_lot = InpRPLot;
      RISK_PROFILE.RP_holdtime = InpRPHoldTime; //
      RISK_PROFILE.RP_order_type = InpRPOrderType;
      RISK_PROFILE.RP_timeframe = InpRPTimeframe;
      RISK_PROFILE.RP_spread = InpRPSpread;
}

double CIntervalTrade::CalcLot(){
   /*
   Calculates lot size based on scale factor, risk amount, percentage basket allocation
   
   Risk Profile Scaling - scales overall risk amount based on account size. (dependent on risk profile created by optimization on python 
   using tradetestlib.)
   
   Equity scaling creates a multiplier that adjusts lot size base on current equity over initial investment. 
   Disabled if account is in evaluation phase (Account Type is challenge and balance below target equity.)
   
   Ex.
   Deposit = 100000
   Current = 110000
   
   equity_scaling = 1.1 
   
   Risk Scaling - scales lot size based on account type and drawdown rules defined in RiskScaling();
   */
   
   // RISK PROFILE SCALING
   double risk_amount_scale_factor = InpRiskAmount / RISK_PROFILE.RP_amount;
   true_risk = InpAllocation * InpRiskAmount; 
   
   // EQUITY SCALING
   double equity_scaling = !EvaluationPhase() ? InpSizing == Dynamic ? account_balance() / ACCOUNT_DEPOSIT : 1 : 1; 
   
   // RISK SCALING 
   double risk_scaling = RiskScaling();
   
   double scaled_lot = RISK_PROFILE.RP_lot * InpAllocation * risk_amount_scale_factor * equity_scaling * risk_scaling;
   
   // Clipping. Prevents over sizing.
   scaled_lot = scaled_lot > InpMaxLot ? InpMaxLot : scaled_lot; 
   
   
   true_lot = scaled_lot;
   
   double symbol_minlot = util_symbol_minlot();
   double symbol_maxlot = util_symbol_maxlot();
   
   if (scaled_lot < symbol_minlot) return symbol_minlot;
   if (scaled_lot > symbol_maxlot) return symbol_maxlot;
   
   return scaled_lot;
}

// ------------------------------- INIT ------------------------------- //

// NEW 

double CIntervalTrade::SetChallengeAccountTakeProfit(){
   if (InpAccountType != Challenge) return 0;
   if (!EvaluationPhase()) return 0;
   int active = NumActivePositions(); 
   
   for (int i = 0; i < active; i++){
      int ticket = TRADES_ACTIVE.trade_ticket;
      int t = OP_OrderSelectByTicket(ticket);
      
      
      double tp_points = CalcTP(PosTicket());
      
      int factor = PosOrderType() == ORDER_TYPE_SELL ? -1 : 1; 
      double take_profit_price = EvaluationPhase() ? (entry_price + (tp_points * factor)) : 0;
      
      int m = OP_ModifyTP(take_profit_price);
      if (m) logger(StringFormat("Modified Take Profit for Ticket: %i", ticket), true);
   }
   
   return 0;   
}


// ------------------------------- TRADE PARAMS ------------------------------- //

void CIntervalTrade::TradeParamsLong(string trade_type){
   /*
   Sets entry price and sl price for Long positions
   */
   
   if (trade_type == "market") entry_price = util_price_ask();
   if (trade_type == "pending") entry_price = util_last_candle_open();
   
   sl_price = entry_price - ((RISK_PROFILE.RP_amount) / (RISK_PROFILE.RP_lot * tick_value * (1 / trade_points)));
   
   
   // SET TP PRICE ONLY IF CHALLENGE, AND BELOW TARGET EQUITY 
   //tp_price = EvaluationPhase() ? (entry_price + CalcTP()) : 0; 
}

void CIntervalTrade::TradeParamsShort(string trade_type){
   /*
   Sets entry price and sl price for Short positions
   */
   if (trade_type == "market") entry_price = util_price_bid();
   if (trade_type == "pending") entry_price = util_last_candle_open();
   
   sl_price = entry_price + ((RISK_PROFILE.RP_amount) / (RISK_PROFILE.RP_lot * tick_value * (1 / trade_points)));

   //tp_price = EvaluationPhase() ? (entry_price - CalcTP()) : 0;

}

void CIntervalTrade::GetTradeParams(string trade_type){
   /*
   Sets entry price and sl based on order type
   */
   switch(RISK_PROFILE.RP_order_type){
      case Long:
         TradeParamsLong(trade_type);
         break;
      case Short:
         TradeParamsShort(trade_type);
         break;
      default:
         break;
   }
}

double CIntervalTrade::ClosePrice(){
   /*
   Returns Close price depending on order type
   
   Long: Closes on Bid
   Short: Closes on Ask
   
   Compensates for spreads on exotics
   */
   double trade_close_price;
   switch(RISK_PROFILE.RP_order_type){
      case Long: 
         trade_close_price = SymbolInfoDouble(Symbol(), SYMBOL_BID); 
         break;
      case Short: 
         trade_close_price = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
         break;
      default: 
         trade_close_price = 0;
         break; 
   }
   return trade_close_price;
}

void CIntervalTrade::SetDelayedEntry(double price){
   /*
   Sets delayed entry reference price when spreads are too wide
   */
   logger(StringFormat("Last Open: %f", util_delayed_entry_reference()));
   logger(StringFormat("Set Delayed Entry Reference Price: %f, Spread: %f", price, util_market_spread()), true);
   
   delayed_entry_reference = price;
}


bool CIntervalTrade::DelayedEntryPriceValid(){
   /*
   Bool for checking if delayed entry price is valid. 
   
   Ex: ask < delayed reference for longs
   
   Called when spreads are too wide.
   */
   bool valid;
   switch(RISK_PROFILE.RP_order_type){
   
      case Long:
      
         valid = delayed_entry_reference > util_price_ask() ? true : false; 
         break;
         
      case Short: 
      
         valid = delayed_entry_reference < util_price_bid() ? true : false;
         break;
         
      default: 
      
         valid = false;
         break;
         
   }
   if (valid) logger(StringFormat("Delayed Entry Valid: %i, Reference: %f, Entry: %f", valid, delayed_entry_reference, entry_price));
   
   return valid;
}


// ------------------------------- TRADE PARAMS ------------------------------- //


// ------------------------------- TRADE LOG ------------------------------- //


void CIntervalTrade::SetOrderOpenLogInfo(
   double   open_price,
   datetime open_time,
   datetime target_close_time,
   long     ticket){

   /*
   Sets order opening information for csv logging.
   */

   TRADE_LOG.order_open_price = open_price;
   TRADE_LOG.order_open_time = open_time;
   TRADE_LOG.order_target_close_time = target_close_time;
   TRADE_LOG.order_open_spread = util_market_spread();
   TRADE_LOG.order_open_ticket = ticket;
}

void CIntervalTrade::SetOrderCloseLogInfo(
   double   close_price,
   datetime close_time,
   long     ticket){

   /*
   Sets order close information for logging.
   */

   TRADE_LOG.order_close_price = close_price;
   TRADE_LOG.order_close_time = close_time;
   TRADE_LOG.order_close_spread = util_market_spread();
   TRADE_LOG.order_close_ticket = ticket;
}

// ------------------------------- TRADE LOG ------------------------------- //


// ------------------------------- TRADE QUEUE ------------------------------- //

void CIntervalTrade::SetNextTradeWindow(void){
   
   /*
   Sets the next trading window. 
   
   If current time has exceeded the closing time for the current day, next trade window is calculated on the next day. 
   */
   
   MqlDateTime current;
   TimeToStruct(TimeCurrent(), current);
   
   current.hour = InpEntryHour;
   current.min = InpEntryMin;
   current.sec = 0;
   
   datetime entry = StructToTime(current);
   
   TRADE_QUEUE.curr_trade_open = entry;
   TRADE_QUEUE.next_trade_open = TimeCurrent() > entry ? entry + util_interval_day() : entry;
   
   TRADE_QUEUE.curr_trade_close = WindowCloseTime(TRADE_QUEUE.curr_trade_open);
   TRADE_QUEUE.next_trade_close = WindowCloseTime(TRADE_QUEUE.next_trade_open);
   
}

datetime CIntervalTrade::WindowCloseTime(datetime window_open_time){

   /*
   Returns trading window closing time.
   */

   window_open_time = window_open_time + (util_interval_current() * RISK_PROFILE.RP_holdtime);
   return window_open_time;
   
}


bool CIntervalTrade::IsTradeWindow(void){

   /*
   Boolean validation for checking if current time is within the trading window.
   */

   if (TimeCurrent() >= TRADE_QUEUE.curr_trade_open && TimeCurrent() < TRADE_QUEUE.curr_trade_close) { return true; }
   
   return false;
   
}


bool CIntervalTrade::IsNewDay(void){
   
   /*
   Boolean validation for checking if current date is a new day
   */
   
   if (TimeCurrent() < TRADE_QUEUE.curr_trade_open) { return true; }
   return false;
   
}

// ------------------------------- TRADE QUEUE ------------------------------- //


// ------------------------------- TRADES ACTIVE ------------------------------- //



void CIntervalTrade::SetTradeOpenDatetime(datetime trade_datetime,long ticket){
   
   /*
   Sets trade open datetime. 
   */
   
   TRADES_ACTIVE.trade_open_datetime = trade_datetime;
   TRADES_ACTIVE.trade_ticket = ticket;
   SetTradeCloseDatetime();
}


void CIntervalTrade::SetTradeCloseDatetime(void){

   /*
   Method for setting target trade close datetime based on holdtime (intervals)
   */

   MqlDateTime trade_open_struct;
   MqlDateTime trade_close_struct;
   
   datetime next = TimeCurrent() + (util_interval_current() * RISK_PROFILE.RP_holdtime);
   TimeToStruct(next, trade_close_struct);
   trade_close_struct.sec = 0;
   
   TRADES_ACTIVE.trade_close_datetime = StructToTime(trade_close_struct);
}

bool CIntervalTrade::CheckTradeDeadline(datetime trade_open_time){
   
   /*
   Checks if trade has exceeded deadline. 
   */
   
   // under construction
   datetime deadline = trade_open_time + (util_interval_current() * RISK_PROFILE.RP_holdtime);
   
   if (TimeCurrent() >= deadline) return true;
   return false;
}


void CIntervalTrade::AppendActivePosition(ActivePosition &active_pos){

   /*
   Appends a struct ActivePosition to active positions list. 
   */

   int arr_size = ArraySize(TRADES_ACTIVE.active_positions);
   ArrayResize(TRADES_ACTIVE.active_positions, arr_size + 1);
   TRADES_ACTIVE.active_positions[arr_size] = active_pos;
   logger(StringFormat("Updated active positions: %i, Ticket: %i", NumActivePositions(), active_pos.pos_ticket));
}


bool CIntervalTrade::TradeInPool(int ticket){
   
   /*
   Boolean validation for checking if selected ticket is already in the order pool, and active positions list
   
   Returns true if found in the list, false if otherwise.
   */
   
   int arr_size = NumActivePositions();
   
   for (int i = 0; i < arr_size; i++){
      if (ticket == TRADES_ACTIVE.active_positions[i].pos_ticket) return true;
   }
   
   return false;
   
}

int CIntervalTrade::RemoveTradeFromPool(int ticket){
   
   int trades_in_pool = NumActivePositions();
   ActivePosition last_positions[];
   
   
   for (int i = 0; i < trades_in_pool; i++){
     
      if (ticket == TRADES_ACTIVE.active_positions[i].pos_ticket) continue; 
      int num_last_positions = ArraySize(last_positions);
      ArrayResize(last_positions, num_last_positions + 1);
      last_positions[num_last_positions] = TRADES_ACTIVE.active_positions[i];
   }
   ArrayFree(TRADES_ACTIVE.active_positions);
   ArrayCopy(TRADES_ACTIVE.active_positions, last_positions);
   
   
   return ArraySize(last_positions);
   
   
}

void  CIntervalTrade::AddOrderToday(void)       { TRADES_ACTIVE.orders_today++; } // Increments orders today
void  CIntervalTrade::ClearOrdersToday(void)    { TRADES_ACTIVE.orders_today = 0; } // Sets orders today to 0
void  CIntervalTrade::ClearPositions(void)      { ArrayFree(TRADES_ACTIVE.active_positions); } // Clears active positions
int   CIntervalTrade::NumActivePositions(void)  { return ArraySize(TRADES_ACTIVE.active_positions); } // Returns number of positions in the list




// ------------------------------- TRADES ACTIVE ------------------------------- //


// ------------------------------- MAIN ------------------------------- //

bool CIntervalTrade::ValidTradeOpen(void){
   /*
   Boolean function for checking trade validity based on: 
      1. Entry Window -> IsTradeWindow()
      2. Active Positions -> NumActivePositions()
      3. OrdersEA -> OrdersEA() -> redundancy
      4. OrdersToday -> OrdersToday()
   
   Returns true if all conditions are satisfied (still in entry window, no active positions, no trades opened yet)
   Otherwise, return false
   */
   
   
   if (IsTradeWindow() && NumActivePositions() == 0 && OrdersEA() == 0 && TRADES_ACTIVE.orders_today == 0) return true; 
   return false;
}

bool CIntervalTrade::CorrectPeriod(void){
   
   /*
   Boolean validation for checking if current timeframe matches desired input timeframe
   
   Prevents algo from executing trades if timeframe is mismatched. This prevents the algo 
   from not holding trades correctly, since holdtime is determined by candle intervals. 
   
   If not corrected, the algo may hold a trade longer, or shorter than desired, and may cause
   undesired algo performance. 
   */
   
   if (Period() == RISK_PROFILE.RP_timeframe) return true;
   errors(StringFormat("INVALID TIMEFRAME. USE: %s", EnumToString(RISK_PROFILE.RP_timeframe)));
   return false;
   
}

void CIntervalTrade::CheckOrderDeadline(void){
   /*
   Iterates through the active_positions list, and checks their deadlines. If deadline has passed, 
   trade is requested to close.
   
   Redundancy in case close_order() fails.
   
   */
   
   
   //if (InpAccountType == Challenge && !EquityReachedProfitTarget() && InpTradeMgt == Trailing) return;
   if (InpTradeMgt == OpenTrailing) return;
   
   int active = NumActivePositions();
   logger(StringFormat("Checking Order Deadline. %i order/s found.", active));
   for (int i = 0; i < active; i++){
   
      ActivePosition pos = TRADES_ACTIVE.active_positions[i];
      if (pos.pos_close_deadline > TimeCurrent()) continue;
      
      if (OrderIsClosed(pos.pos_ticket)) {
         logger(StringFormat("Order Ticket: %i is already closed. %i Positions in Order Pool", pos.pos_ticket, NumActivePositions()));
         if (!TicketInPortfolioHistory(pos.pos_ticket)) {
            // check latest data in account history if ticket matches. 
            TradesHistory latest = LastEntry();
            
            if (pos.pos_ticket == latest.ticket) UpdateHistoryWithLastValue();         
            
            else logger(StringFormat("Ticket Mismatch. Latest: %i, Closed: %i", latest.ticket, pos.pos_ticket)); 
         }
         continue;
      }
      OP_CloseTrade(pos.pos_ticket); 
   }
}




int CIntervalTrade::OrdersEA(void){
   /*
   Periodically clears, and repopulates trades_active.active_positions array, with an 
   ActivePosition object, containing trade open time, close deadline, ticket.
   
   The active_positions array is then checked by check_deadline if a trade close has missed a deadline. 
   
   The loop iterates through all open positions in the trade pool, finds a matching symbol and magic number.    
   Gets that trade's open time, and sets a deadline, then appends to a list. 
   
   the active_positions list is then checked for trades that exceeded their deadlines. 
   

   if trades_found, and ea_positions == 0, that means there are no trades in order_pool,
   and no trades were added to the list. If num_active_positions >0, there are trades in the 
   internal pool. Do: clear the pool. 
   */

   int open_positions = PosTotal();
   
   //ArrayFree(trades_active.active_positions);
   int ea_positions = 0; // new trades found in pool that are not in internal trade pool
   int trades_found = 0; // trades found in pool that match magic and symbol
   
   for (int i = 0; i < open_positions; i++){
   
      if (OP_TradeMatch(i)){
         trades_found++;
         int ticket = PosTicket();
         if (TradeInPool(ticket)) { continue; }
         
         ActivePosition ea_pos; 
         ea_pos.pos_open_time = PosOpenTime();
         ea_pos.pos_ticket = ticket;
         ea_pos.pos_close_deadline = ea_pos.pos_open_time + (util_interval_current() * RISK_PROFILE.RP_holdtime);
         AppendActivePosition(ea_pos);
         ea_positions++; 
      }
   }
   
   // checks: trades_found, ea_positions, trades_active. 
   /*
   trades_found > ea_positions: a trade is found, and already exists in the active_positions list
   trades_found == ea_positions: a trade is found, and added in the active_positions list
   trades_found == ea_positions == 0, and num_active_positions > 0: a trade was closed or stopped. if this happens, clear the list, and run again (recursion)
   */
   if (trades_found == 0 && ea_positions == 0 && NumActivePositions() > 0) { 
      ClearPositions();
      
      // UPDATE HISTORY HERE   
      TradesHistory last_entry = LastEntry();
      if (!TicketInPortfolioHistory(last_entry.ticket)) UpdateHistoryWithLastValue();
   }
   return trades_found; 
}

int CIntervalTrade::TrailStop(void){
   
   /*
   Iterates through active positions, sets trail stop 
   */
   
   int active = NumActivePositions();
   
   for (int i = 0; i < active; i++){
      
      int ticket = TRADES_ACTIVE.active_positions[i].pos_ticket;
      datetime deadline = TRADES_ACTIVE.active_positions[i].pos_close_deadline;
      int s = OP_OrderSelectByTicket(ticket);
      
      double trade_open_price = PosOpenPrice();
      double last_open_price = util_last_candle_open();
      

      // diff is the gap between trade open price and last open price. 
      // determines if trailing is valid 
      double diff = MathAbs(trade_open_price - last_open_price) / trade_points;
      
      
      //if (InpTradeMgt == TrailOnClose && TimeCurrent() < deadline) continue; 
      //if (InpTradeMgt == TrailOnClose && PosProfit() < 0) OP_CloseTrade(ticket);
      
      
      
      if (diff < InpTrailInterval) {
         continue;
      }
      ENUM_ORDER_TYPE position_order_type = PosOrderType();
      
      double updated_sl = PosSL();
      double current_sl = updated_sl;
      
      int c = 0; 
      double trail_factor = InpTrailInterval * trade_points; 
      switch(position_order_type){
         // CASES ARE REPLACED FROM 0 AND 1, TO ENUM FLAGS, ORDERTYPEBUY, ORDERTYPESELL 
         // IF ALGO BECOMES BUGGY, CHECK THIS
         
         case ORDER_TYPE_BUY: 
         
            updated_sl = last_open_price - trail_factor;
            if (updated_sl <= current_sl) continue;
            break;
            
         case ORDER_TYPE_SELL:
         
            updated_sl = last_open_price + trail_factor;
            if (updated_sl >= current_sl) continue;
            break;
            
         default:
            continue;
            
      }
      
      c = OP_ModifySL(updated_sl);
      
      if (c) {
         logger(StringFormat("Trail Stop Updated. Ticket: %i", ticket), true);
         return 1;
      }
      else logger(StringFormat("ERROR UPDATING SL: %i CURRENT: %f, TARGET: %f", GetLastError(), current_sl, updated_sl));
   }
   
   return 1;
}

int CIntervalTrade::TrailStopsOnClose(void){
      
      /*
      CALCULATING DIFF: 
         If sl != open price, use open price. 
         if sl >= open price (if buy) use sl price
      */
      
      
//if (InpTradeMgt == TrailOnClose && TimeCurrent() >= deadline && PosProfit() <= 0) OP_CloseTrade(ticket);
/*
      TRAIL ON CLOSE: 
      
      ACTIVATION: On Trade Deadline
      ACTIONS: Close, Ignore, Trail 
      
      CLOSE: 
         If diff < InpTrail Interval and trade in profit 
         
         If Trade in loss and past deadline 
         
      IGNORE   
         Not yet deadline 
         
      TRAIL
         Trade in profit, diff > Trail Interval
      
   if (InpTradeMgt == TrailOnClose) {
         if (TimeCurrent() < deadline) {
            Print("NOT YET DEADLINE");
            break;
         }            
         if ((PosProfit() < 0 && TimeCurrent() >= deadline) || (diff < InpTrailInterval)) {
            Print("CLOSE BY LOSS");
            OP_CloseTrade(ticket);
            break;
         }
      }
      
      */
      
      int active = NumActivePositions();
      int num_trailed_positions = 0;
      
      for (int i = 0; i < active; i ++){
         ActivePosition active_trade = TRADES_ACTIVE.active_positions[i];
         
         uint ticket = active_trade.pos_ticket;
         int s = OP_OrderSelectByTicket(ticket);
         datetime open_time = active_trade.pos_open_time;
         datetime deadline = active_trade.pos_close_deadline;
      
         
         // Ignores if not yet deadline. TrailOnClose only works if deadline has passed.
         //if (!CheckTradeDeadline(open_time) && TimeCurrent() < deadline) continue; 
         
         // Closes trade if deadline has passed and trade is not in profit. 
         if (PosProfit() < 0 && CheckTradeDeadline(open_time) && TimeCurrent() > deadline) OP_CloseTrade(ticket);
         
         ENUM_ORDER_TYPE position_order_type = PosOrderType();
         
         double updated_sl = PosSL();
         double current_sl = updated_sl; 
         double trade_open_price = PosOpenPrice();
         double last_open_price = util_last_candle_open();
         
         int c = 0;
         double trail_factor = InpTrailInterval * trade_points;
         
         // Determines which gap to measure. if price is already risk free, use sl. if not, use trade open price
         //double trail_stop_reference_price = IsRiskFree(ticket) ? current_sl : trade_open_price;
         double trail_stop_reference_price = trade_open_price;
         double diff = MathAbs(trail_stop_reference_price - last_open_price) / trade_points;
         
         // SKIP IF GAP IS SMALL
         if (diff < InpTrailInterval) continue;
         
         switch(position_order_type){
            case ORDER_TYPE_BUY:
               updated_sl = last_open_price - trail_factor; 
               if (updated_sl < current_sl) continue; 
               break; 
            case ORDER_TYPE_SELL:
               updated_sl = last_open_price = trail_factor; 
               if (updated_sl > current_sl) continue;
               break;
            default:
               continue;
         }
         c = OP_ModifySL(updated_sl);
         if (c) {
            logger(StringFormat("Trail Stop Updated. Ticket: %i", ticket), true);
            num_trailed_positions++;
         }
         
      }
      return num_trailed_positions;
      
}

int CIntervalTrade::SetBreakeven(void){
   
   /*
   Iterates through active positions, and modifies SL to order open price - breakeven
   */

   if (InpTradeMgt == Trailing) return 0;
   
   int active = NumActivePositions();
   
   for (int i = 0; i < active; i ++){
      
      int ticket = TRADES_ACTIVE.active_positions[i].pos_ticket;
      
      if (PosProfit() < 0) continue;
      int s = OP_OrderSelectByTicket(ticket);
      int c = OP_ModifySL(PosOpenPrice());
      
   }
   
   return 1;
}

bool CIntervalTrade::ModifyOrder(void){
   if (NumActivePositions() == 0 || PosTotal() == 0) return false;
   switch(InpTradeMgt){
      case Breakeven:
         SetBreakeven();
         break;
      case Trailing:
         TrailStop();
         break;
      case OpenTrailing:
         TrailStopsOnClose();
         break;
      default:
         break;
   }
   return true;
}

int CIntervalTrade::CloseOrder(void){
   /*
   Main order close method, send to platform specific methods
   */
   int open_positions = PosTotal();
   OP_OrdersCloseAll();
   return 1;
}

bool CIntervalTrade::DelayedAndValid(void){
   /*
   Checks if trade is delayed, and valid 
   */
   GetTradeParams("market");
   
   if (TimeCurrent() >= TRADE_QUEUE.curr_trade_open && DelayedEntryPriceValid()) return true;
   return false;
}

int CIntervalTrade::SendLimitOrder(void){
   
   /*
   Provision for sending pending orders instead of spread recursion. 
   */
   
   GetTradeParams("pending");
   
   ENUM_ORDER_TYPE order_type = util_pending_ord_type();
   double pending_entry_price = iOpen(Symbol(), PERIOD_CURRENT, 0);
   int ticket = OP_OrderOpen(Symbol(), order_type, CalcLot(), pending_entry_price, sl_price, 0);
   if (ticket == -1) logger("Trade Failed");
   SetTradeOpenDatetime(TimeCurrent(), ticket);
   
   ActivePosition ea_pos;
   ea_pos.pos_ticket = ticket;
   ea_pos.pos_open_time = TRADES_ACTIVE.trade_open_datetime;
   ea_pos.pos_close_deadline = TRADES_ACTIVE.trade_close_datetime;
   AppendActivePosition(ea_pos);
   
   // trigger an order open log containing order open price, entry time, target close time, and spread at the time of the order
   SetOrderOpenLogInfo(pending_entry_price, TimeCurrent(), TRADES_ACTIVE.trade_close_datetime, ticket);
   if (!UpdateCSV("open")) { logger("Failed to Write To CSV. Order: OPEN"); }
   
   return 1; 
}

int CIntervalTrade::SendMarketOrder(void){
   // if bad spread, record the entry price (bid / ask), then enter later if still valid
   
   /*
   Potential Solutions / Ideas for handling bad spreads:
   1. Delay, recursive
      -> recursion method given an input delay. Calls the send_order function after the delay while checking the spread. 
      -> Does not check if price is optimal (entered exactly at entry window candle open price)
      -> Optional: Allow checking if price is optimal
   
   2. Interval
      -> If spread is bad, skips to next interval. 
      -> Checks if price is optimal (exactly, or better than candle open price)
      
   3. Ignore
      -> If spread is bad, halts trading for the day. 
   */
   
   
   ENUM_ORDER_TYPE order_type = util_market_ord_type();
   if (TimeCurrent() >= TRADE_QUEUE.curr_trade_open) SetDelayedEntry(util_delayed_entry_reference()); // sets the reference price to the entry window candle open price
   int delay = InpSpreadDelay * 1000; // Spread delay in seconds * 1000 milliseconds
   if (util_market_spread() > RISK_PROFILE.RP_spread) { UpdateCSV("delayed"); }
   
   
   /*
   RETURN CODES 
   
   -1 - order send failed 
   -10 - interval bad spread
   -20 - interval invalid price
   */
   
   switch (InpSpreadMgt){
      
      case Interval: // interval 
      
         if (util_market_spread() >= RISK_PROFILE.RP_spread) return -10;
         if (!DelayedAndValid()) return -20;
         break;
         
      case Recursive: // recursive
      
         while (util_market_spread() >= RISK_PROFILE.RP_spread || !DelayedAndValid()){
            Sleep(delay);
            
            if (TimeCurrent() >= TRADE_QUEUE.curr_trade_close) return -30;
         }
         break;
         
      case Ignore: // ignore 
      
         if (TimeCurrent() > TRADE_QUEUE.curr_trade_open) return -40;
         if (util_market_spread() >= RISK_PROFILE.RP_spread) return -50;
         break; 
         
      default: 
      
         break;
   }
   
   
   
   int ticket = OP_OrderOpen(Symbol(), order_type, CalcLot(), entry_price, sl_price, tp_price);
   if (ticket == -1) logger(StringFormat("ORDER SEND FAILED. ERROR: %i", GetLastError()), true);
   SetTradeOpenDatetime(TimeCurrent(), ticket);
   
   ActivePosition ea_pos;
   ea_pos.pos_ticket = ticket;
   ea_pos.pos_open_time = TRADES_ACTIVE.trade_open_datetime;
   ea_pos.pos_close_deadline = TRADES_ACTIVE.trade_close_datetime;
   AppendActivePosition(ea_pos);
   
   AddOrderToday(); // adds an order today
   // trigger an order open log containing order open price, entry time, target close time, and spread at the time of the order
   
   SetChallengeAccountTakeProfit();
   SetOrderOpenLogInfo(entry_price, TimeCurrent(), TRADES_ACTIVE.trade_close_datetime, ticket);
   if (!UpdateCSV("open")) { logger("Failed to Write To CSV. Order: OPEN"); }
   
   return ticket;
}
int CIntervalTrade::WriteToCSV(string data_to_write, string log_type){
   
   /*
   Method for writing to CSV. 
   */
   
   string filename = log_type == "delayed" ? log_type : "arb";
   
   string file = "arb\\"+account_server()+"\\"+Symbol()+"\\"+filename+".csv";
   int handle = FileOpen(file, FILE_READ | FILE_WRITE | FILE_CSV | FILE_COMMON);
   FileSeek(handle, 0, SEEK_END);
   FileWrite(handle, data_to_write);
   FileClose(handle);
   FileFlush(handle);
   return handle;
   
}

bool CIntervalTrade::UpdateCSV(string log_type){
   
   /*
   Updates CSV file.
   
   Receives a string log_type: "open" / "close" / "delayed"
   */
   
   // log type: order open, order close
   
   if (!InpLogging) return true; // return if csv logging is disabled
   
   logger(StringFormat("Update CSV: %s", log_type));
   
   string csv_message = "";
   datetime current = TimeCurrent();
   
   if (log_type == "open"){
      csv_message = current+",open,"+TRADE_LOG.order_open_ticket+","+TRADE_LOG.order_open_price+","+TRADE_LOG.order_open_time+","+TRADES_ACTIVE.trade_close_datetime+","+TRADE_LOG.order_open_spread;
   }
   
   if (log_type == "close"){
      csv_message = current+",close,"+TRADE_LOG.order_close_ticket+","+TRADE_LOG.order_close_price+","+TRADE_LOG.order_open_time+","+current+","+TRADE_LOG.order_close_spread;
   }
   
   if (log_type == "delayed"){
      // if delayed, write: delayed entry reference, bidask 
      // message format time, delayed, spread, price reference, entry price
      
      csv_message = StringFormat("%s,%f,%f,%f",string(current),delayed_entry_reference,entry_price,util_market_spread());
   }
   
   if (WriteToCSV(csv_message, log_type) == -1){
   
      logger(StringFormat("Failed To Write to CSV. %i", GetLastError()));
      logger(StringFormat("MESSAGE: %s", csv_message));
      return false;
   }
   
   return true;
}

bool CIntervalTrade::MinimumEquity(void){
   
   /*
   Boolean validation for checking if current account equity meets minimum trading requirements. 
   
   Returns TRUE if account_equity > InpMinimumEquity
   Returns FALSE if account_equity is below minimum requirement. 
   */

   double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   
   if (account_equity < ACCOUNT_CUTOFF) {
      logger(StringFormat("TRADING DISABLED. Account Equity is below Minimum Trading Requirement. Current Equity: %f, Required: %f", account_equity, ACCOUNT_CUTOFF));
      return false;
   }
   
   return true;
}

bool CIntervalTrade::IsRiskFree(int ticket){
   // COMPARE SL AND ENTRY PRICE
   ENUM_ORDER_TYPE position_order_type = PosOrderType();
   
   switch(position_order_type){
      case ORDER_TYPE_BUY: 
         if (PosSL() < PosOpenPrice()) return false;
         break; 
         
      case ORDER_TYPE_SELL:
         if (PosSL() > PosOpenPrice()) return false;
         break;
         
      default:
         return false;
         break;
   }
   return true;
}

bool CIntervalTrade::OrderIsClosed(int ticket){
   //int s = OP_OrderSelectByTicket(ticket);
   
   int num_open_positions = PosTotal();
   if (num_open_positions == 0) {
      RemoveTradeFromPool(ticket);
      return true; 
   }
   for (int i = 0; i < num_open_positions; i++){
      int s = OP_OrderSelectByIndex(i);
      if (PosTicket() == ticket) return false; 
      
   }
   RemoveTradeFromPool(ticket);
   return true;
}

// ------------------------------- MAIN ------------------------------- //



// ------------------------------- TRADE OPERATIONS ------------------------------- //




// ------------------------------- TRADE OPERATIONS ------------------------------- //


// ------------------------------- MQL5 ------------------------------- //

#ifdef __MQL5__ 


double            CIntervalTrade::util_tick_val()             { return SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);}
double            CIntervalTrade::util_trade_pts()            { return SymbolInfoDouble(Symbol(), SYMBOL_POINT);}
double            CIntervalTrade::util_market_spread()        { return SymbolInfoInteger(Symbol(), SYMBOL_SPREAD); }

int               CIntervalTrade::PosTotal()       { return PositionsTotal(); }
int               CIntervalTrade::PosTicket()      { return PositionGetInteger(POSITION_TICKET); }
double            CIntervalTrade::PosLots()        { return PositionGetDouble(POSITION_VOLUME); }
string            CIntervalTrade::PosSymbol()      { return PositionGetString(POSITION_SYMBOL); }
int               CIntervalTrade::PosMagic()       { return PositionGetInteger(POSITION_MAGIC); }
datetime          CIntervalTrade::PosOpenTime()    { return PositionGetInteger(POSITION_TIME); }
double            CIntervalTrade::PosOpenPrice()   { return PositionGetDouble(POSITION_PRICE_OPEN); }
double            CIntervalTrade::PosProfit()      { return PositionGetDouble(POSITION_PROFIT); }
ENUM_ORDER_TYPE   CIntervalTrade::PosOrderType()   { return PositionGetInteger(POSITION_TYPE); }
double            CIntervalTrade::PosSL()          { return PositionGetDouble(POSITION_SL); }
double            CIntervalTrade::PosTP()          { return PositionGetDouble(POSITION_TP); }
int               CIntervalTrade::PosHistTotal()   { return HistoryDealsTotal(); }
double            CIntervalTrade::PosCommission()  { return DealInfo.Commission(); }


int CIntervalTrade::OP_OrdersCloseAll(){
   int tickets[];
   
   int open_positions = PosTotal();
   for (int i = 0; i < open_positions; i ++){
      int ticket = PositionGetTicket(i);
      int t = PositionSelectByTicket(ticket);
      
      if (PosMagic() != InpMagic){ continue; }
      if (PosSymbol() != Symbol()) { continue; }
      
      //if (!trades_active.check_trade_deadline(PositionTimeOpen())) { continue; }
      
      //int c = Trade.PositionClose(t);
      // create a list, and append
      int arr_size = ArraySize(tickets);
      ArrayResize(tickets, arr_size+1);
      tickets[arr_size] = ticket;
   }
   int total_trades = ArraySize(tickets);
   //Print(total_trades, " Trades added.");
   
   
   // close added trades
   int trades_closed = 0;
   for (int i = 0; i < ArraySize(tickets); i++){
      int c = OP_CloseTrade(tickets[i]);
      if (c == -2) {
         logger("Cannot close trade. Trail Stop is set.");
         break;
      }
      if (c) { 
         trades_closed += 1;
         SetOrderCloseLogInfo(ClosePrice(), TimeCurrent(), PosTicket());
         if (!UpdateCSV("close")) {Print("Failed to write to CSV. Order: CLOSE"); }
         if (c){ Print("Closed: ",PosTicket()); }
         
     }
   }
   return trades_closed;
}


int CIntervalTrade::OP_CloseTrade(int ticket){ 
   int t = PositionSelectByTicket(ticket);
   
   if (!OrderIsClosed(ticket)){
      logger(StringFormat("Order Ticket: %i is already closed. %i Positions in Order Pool.", ticket, NumActivePositions()));
      if (!TicketInPortfolioHistory(ticket)){
         // check latest data in account history if ticket matches. 
         TradesHistory latest = LastEntry();
         if (ticket == latest.ticket) UpdateHistoryWithLastValue();
         else logger(StringFormat("Ticket Mismatch. Ltest: %i, Closed: %i", latest.ticket, ticket));
      }
      //return 1; 
   }
   
   
   ENUM_ORDER_TYPE ord_type = OrderGetInteger(ORDER_TYPE);
   int c = 0;
   switch(ord_type){
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_SELL:
         // market order 
         c = Trade.PositionClose(ticket); // closes positions in loss when using trail stop 
         if (!c) { logger(StringFormat("ORDER CLOSE FAILED. TICKET: %i, ERROR: %i", ticket, GetLastError()), true);}
         break;
      case ORDER_TYPE_BUY_LIMIT:
      case ORDER_TYPE_SELL_LIMIT:
         //pending order - delete
         c = Trade.OrderDelete(ticket);
         if (!c) { logger(StringFormat("ORDER DELETE FAILED. TICKET; %i, ERROR: %i", ticket, GetLastError()));}
         break;
         

      default:
         c = -1;
         break;     
   }
   SetOrderCloseLogInfo(ClosePrice(), TimeCurrent(), PosTicket());
   
   if (!UpdateCSV("close")) { logger("Failed to write to CSV. Order: CLOSE"); }
   if (c) { 
      logger(StringFormat("Closed: %i P/L", PosTicket(), PosProfit()), true);
      if (!TicketInPortfolioHistory(ticket)){
         int latest_ticket = LastEntry().ticket;
         if (ticket == latest_ticket) UpdateHistoryWithLastValue();
         else logger(StringFormat("Ticket Mismatch. Latest: %i, Closed: %i", latest_ticket, ticket));
      }
   }
   return c;
}



int CIntervalTrade::OP_OrderOpen(
   string            symbol, 
   ENUM_ORDER_TYPE   order_type, 
   double            volume, 
   double            price, 
   double            sl, 
   double            tp){
   
   bool t = Trade.PositionOpen(symbol, order_type, NormalizeDouble(volume, 2), entry_price, sl_price, tp_price, NULL);
   logger(StringFormat("ORDER OPEN: Symbol: %s, Ord Type: %s, Vol: %f, Price: %f, SL: %f, TP: %f, Spread: %f", symbol, EnumToString(order_type), volume, price, sl_price, tp_price, util_market_spread()), true);
   if (!t) { Print(GetLastError()); }
   int order_ticket = OP_SelectTicket();
   return order_ticket;
}


int CIntervalTrade::OP_SelectTicket(void){
   int open_positions = PosTotal();
   for (int i = 0; i < open_positions; i ++){
      int ticket = PositionGetTicket(i);
      int t = PositionSelectByTicket(ticket);
      
      if (PosMagic() != InpMagic) continue; 
      if (PosSymbol() != Symbol()) continue; 
      
      return ticket;
   }
   return 0;
}


bool CIntervalTrade::OP_TradeMatch(int index){
   int ticket = PositionGetTicket(index);
   int t = PositionSelectByTicket(ticket);
   if (PosMagic() != InpMagic) return false;
   if (PosSymbol() != Symbol()) return false;
   return true;
}

int CIntervalTrade::OP_OrderSelectByTicket(int ticket){ return PositionSelectByTicket(ticket); }

int CIntervalTrade::OP_OrderSelectByIndex(int index) { return PositionSelectByTicket(PositionGetTicket(index)); }

int CIntervalTrade::OP_HistorySelectByIndex(int index) { return HistoryDealSelect(HistoryDealGetTicket(index)); }
int CIntervalTrade::OP_ModifySL(double sl){
   // SELECT THE TICKET PLEASE
   int m = Trade.PositionModify(PosTicket(), sl, PosTP());
   if (!m) logger(StringFormat("ERROR MODIFYING SL: %i", GetLastError()));
   return m;
}

int CIntervalTrade::OP_ModifyTP(double tp){
   int m = Trade.PositionModify(PosTicket(), PosSL(), tp);
   if (!m) logger(StringFormat("ERROR MODIFYING TP: %i", GetLastError()));
   return m;
}

double CIntervalTrade::account_deposit(void){
   HistorySelect(0, TimeCurrent());
   
   int total = HistoryDealsTotal();
   
   for (int i = 0; i < total; i++){
      ulong ticket = HistoryDealGetTicket(i);
      uint type = HistoryDealGetInteger(ticket, DEAL_TYPE);
      double deposit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      
      if (type == 2) return deposit; 
   }
   //logger("Deposit not found. Using Dummy.");
   return InpDummyDeposit;
}


#endif 

// ------------------------------- MQL5 ------------------------------- //

// ------------------------------- TRADE OPERATIONS ------------------------------- //


// ------------------------------- UTILS AND WRAPPERS ------------------------------- //





int CIntervalTrade::util_is_pending(ENUM_ORDER_TYPE ord_type){
   
   /*
   Returns if order type is pending
   */
   
   switch(ord_type){
      case ORDER_TYPE_BUY: 
      case ORDER_TYPE_SELL:
         return 0;
         break;
      case ORDER_TYPE_BUY_LIMIT:
      case ORDER_TYPE_SELL_LIMIT:
         return 1;
         break;
      default:
         break;
   }
   return -1;
}

ENUM_ORDER_TYPE CIntervalTrade::util_pending_ord_type(void){

   /*
   Returns order type based on input order type
   */

   switch(RISK_PROFILE.RP_order_type){
      case Long:
         return ORDER_TYPE_BUY_LIMIT;
         break;
      case Short:
         return ORDER_TYPE_SELL_LIMIT;
         break;
      default:
         break;
   }
   return -1;
}

ENUM_ORDER_TYPE CIntervalTrade::util_market_ord_type(void){

   /*
   Returns order type based on input order type
   */
   
   switch(RISK_PROFILE.RP_order_type){
      case Long: 
         return ORDER_TYPE_BUY;
         break;
      case Short:
         return ORDER_TYPE_SELL;
         break;
      default:
         break;
   }
   return -1; 
}

double CIntervalTrade::util_delayed_entry_reference(void){
   
   /*
   Gets delayed entry reference price during time intervals with large spreads. 
   
   Short: Last open (Bid) 
   Long: Last Open + spread factor (accounting for simulated ask from input maximum desired spread)   
   */
   
   double last_open = util_shift_to_entry() == 0 ? util_last_candle_open() : util_entry_candle_open();
   double reference;
   double spread_factor = RISK_PROFILE.RP_spread * trade_points;
   
   switch(RISK_PROFILE.RP_order_type){
      case Long:
         reference = last_open + spread_factor;
         break;
      case Short:
         reference = last_open;
         break;
      default:
         break;
   }
   return reference;
}


int CIntervalTrade::logger(string message, bool notify = false, bool debug = false){
   if (!InpTerminalMsg && !debug) return -1;
   
   string mode = debug ? "DEBUGGER" : "LOGGER";
   PrintFormat("%s: %s", mode, message);
   
   if (notify) notification(message);
   
   return 1;
}

bool CIntervalTrade::notification(string message){
   /*
   Sends notification to MT4/MT5 App on Trade Open, Close, Modify
   */
   // CONSTRUCT MESSAGE 
   
   if (!InpPushNotifs) return false;
   
   bool n = SendNotification(message);
   
   if (!n) logger(StringFormat("Failed to Send Notification. Code: %i", GetLastError()));
   return n;
}

double CIntervalTrade::util_entry_candle_open(void){
   double price = iOpen(Symbol(), PERIOD_CURRENT, util_shift_to_entry());
   return price;
}

void CIntervalTrade::errors(string error_message)     { Print("ERROR: ", error_message); }

double   CIntervalTrade::util_price_ask(void)         { return SymbolInfoDouble(Symbol(), SYMBOL_ASK); }
double   CIntervalTrade::util_price_bid(void)         { return SymbolInfoDouble(Symbol(), SYMBOL_BID); }

double   CIntervalTrade::util_last_candle_open(void)  { return iOpen(Symbol(), PERIOD_CURRENT, 0); }
double   CIntervalTrade::util_last_candle_close(void) { return iClose(Symbol(), PERIOD_CURRENT, 0); }

int      CIntervalTrade::util_interval_day(void)      { return PeriodSeconds(PERIOD_D1); }
int      CIntervalTrade::util_interval_current(void)  { return PeriodSeconds(PERIOD_CURRENT); }

double   CIntervalTrade::account_balance(void)        { return AccountInfoDouble(ACCOUNT_BALANCE); }
double   CIntervalTrade::account_equity(void)         { return AccountInfoDouble(ACCOUNT_EQUITY); }
string   CIntervalTrade::account_server(void)         { return AccountInfoString(ACCOUNT_SERVER); }

double   CIntervalTrade::util_symbol_minlot(void)     { return SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN); }
double   CIntervalTrade::util_symbol_maxlot(void)     { return SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX); }

double   CIntervalTrade::util_trade_diff(void)        { return ((RISK_PROFILE.RP_amount) / (RISK_PROFILE.RP_lot * tick_value * (1 / trade_points))); }
double   CIntervalTrade::util_trade_diff_points(void) { return ((RISK_PROFILE.RP_amount) / (RISK_PROFILE.RP_lot * tick_value)); }
double   CIntervalTrade::ValueAtRisk(void)            { return CalcLot() * util_trade_diff_points(); }

int      CIntervalTrade::util_shift_to_entry(void) {
   MqlDateTime target_datetime;
   TimeToStruct(TimeCurrent(), target_datetime);
   
   target_datetime.hour = InpEntryHour;
   target_datetime.min = InpEntryMin;
   
   datetime target = StructToTime(target_datetime);
   
   int shift = iBarShift(Symbol(), PERIOD_CURRENT, target);
   return shift;
}
// ------------------------------- UTILS AND WRAPPERS ------------------------------- //

