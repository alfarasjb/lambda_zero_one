// MAIN TRADING CLASS
#ifdef __MQL5__
#include <Trade/Trade.mqh>
CTrade Trade;
#endif 


#include "definition.mqh"

// ------------------------------- TEMPLATES ------------------------------- //

struct RiskProfile{

   double            RP_amount;
   float             RP_lot, RP_spread; 
   int               RP_holdtime;
   Orders            RP_order_type; 
   ENUM_TIMEFRAMES   RP_timeframe;
   
} RISK_PROFILE;

struct TradeLog{

   double      order_open_price, order_open_spread;
   datetime    order_open_time, order_target_close_time;
   
   double      order_close_price, order_close_spread;
   datetime    order_close_time;
   
   long        order_open_ticket, order_close_ticket;

} TRADE_LOG;

struct TradeQueue{

   datetime next_trade_open, next_trade_close, curr_trade_open, curr_trade_close;
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


// ------------------------------- TEMPLATES ------------------------------- //


// ------------------------------- CLASS ------------------------------- //

class CIntervalTrade{

   protected:
   private:
      
      
   public: 
      // TRADE PARAMETERS
      float       order_lot;
      double      entry_price, sl_price, tick_value, trade_points, delayed_entry_reference, true_risk, true_lot;
      
      CIntervalTrade();
      ~CIntervalTrade(){};
      
      // INIT 
      void              SetRiskProfile();
      double            CalcLot();
      
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
      void              CheckOrderDeadline();
      bool              CorrectPeriod();
      bool              ValidTradeOpen();
      bool              MinimumEquity();
      
      // TRADE OPERATIONS
      
      int               PosTotal();
      int               PosTicket();
      double            PosLots();
      string            PosSymbol();
      int               PosMagic();
      int               PosOpenTime();
      double            PosOpenPrice(); 
      double            PosProfit();
      ENUM_ORDER_TYPE   PosOrderType();
      double            PosSL();
      double            PosTP();
      
      int               OP_OrdersCloseAll();
      int               OP_CloseTrade(int ticket);
      int               OP_OrderOpen(string symbol, ENUM_ORDER_TYPE order_type, double volume, double price, double sl, double tp);
      bool              OP_TradeMatch(int index);
      int               OP_OrderSelectByTicket(int ticket);
      int               OP_ModifySL(double sl);
      int               OP_SelectTicket(); // mql5 only
      
      // UTILITIES AND WRAPPERS
      double            util_tick_val();
      double            util_trade_pts();
      double            util_last_candle_open();
      double            util_last_candle_close();    
      double            util_market_spread();
      double            util_price_ask();
      double            util_price_bid();
      int               util_interval_day();
      int               util_interval_current();
      double            util_delayed_entry_reference();
      ENUM_ORDER_TYPE   util_market_ord_type();
      ENUM_ORDER_TYPE   util_pending_ord_type();
      int               util_is_pending(ENUM_ORDER_TYPE ord_type);
      
      double            account_balance();
      string            account_server();
      
      int               logger(string message);
      void              errors(string error_message);
      
};


// ------------------------------- CLASS ------------------------------- //

CIntervalTrade::CIntervalTrade(void){
   tick_value = util_tick_val();
   trade_points = util_trade_pts();
   
   TRADES_ACTIVE.candle_counter = 0;
   TRADES_ACTIVE.orders_today = 0;
}

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
   */
   double risk_amount_scale_factor = InpRiskAmount / RISK_PROFILE.RP_amount;
   true_risk = InpAllocation * InpRiskAmount; 
   
   double scaled_lot = RISK_PROFILE.RP_lot * InpAllocation * risk_amount_scale_factor;
   scaled_lot = scaled_lot > InpMaxLot ? InpMaxLot : scaled_lot; 
   
   true_lot = scaled_lot;
   
   
   return scaled_lot;
}

// ------------------------------- INIT ------------------------------- //


// ------------------------------- TRADE PARAMS ------------------------------- //

void CIntervalTrade::TradeParamsLong(string trade_type){
   /*
   Sets entry price and sl price for Long positions
   */
   
   if (trade_type == "market") entry_price = util_price_ask();
   if (trade_type == "pending") entry_price = util_last_candle_open();
   
   sl_price = entry_price - ((RISK_PROFILE.RP_amount) / (RISK_PROFILE.RP_lot * tick_value * (1 / trade_points)));
}

void CIntervalTrade::TradeParamsShort(string trade_type){
   /*
   Sets entry price and sl price for Short positions
   */
   if (trade_type == "market") entry_price = util_price_bid();
   if (trade_type == "pending") entry_price = util_last_candle_open();
   
   sl_price = entry_price + ((RISK_PROFILE.RP_amount) / (RISK_PROFILE.RP_lot * tick_value * (1 / trade_points)));
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
   logger(StringFormat("Last Open: %f", util_last_candle_open()));
   logger(StringFormat("Set Delayed Entry Reference Price: %f, Spread: %f", price, util_market_spread()));
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
   
   int active = NumActivePositions();
   
   for (int i = 0; i < active; i++){
      ActivePosition pos = TRADES_ACTIVE.active_positions[i];
      if (pos.pos_close_deadline > TimeCurrent()) continue;
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
   if (trades_found == 0 && ea_positions == 0 && NumActivePositions() > 0) { ClearPositions(); }
   return trades_found; 
}

int CIntervalTrade::TrailStop(void){
   
   /*
   Iterates through active positions, sets trail stop 
   */
   
   int active = NumActivePositions();
   
   for (int i = 0; i < active; i++){
   
      int ticket = TRADES_ACTIVE.active_positions[i].pos_ticket;
      int s = OP_OrderSelectByTicket(ticket);
      
      double trade_open_price = PosOpenPrice();
      double last_open_price = util_last_candle_open();
      
      double diff = MathAbs(trade_open_price - last_open_price) / trade_points;
      
      if (diff < InpTrailInterval) continue;
      
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
            if (updated_sl < current_sl) continue;
            break;
            
         case ORDER_TYPE_SELL:
         
            updated_sl = last_open_price + trail_factor;
            if (updated_sl > current_sl) continue;
            break;
            
         default:
            continue;
            
      }
      c = OP_ModifySL(updated_sl);
      if (c) logger("Trail Stop Updated");
   }
   
   return 1;
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
   switch(InpTradeMgt){
      case Breakeven:
         SetBreakeven();
         break;
      case Trailing:
         TrailStop();
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
   if (TimeCurrent() == TRADE_QUEUE.curr_trade_open) SetDelayedEntry(util_delayed_entry_reference()); // sets the reference price to the entry window candle open price
   int delay = InpSpreadDelay * 1000; // Spread delay in seconds * 1000 milliseconds
   if (util_market_spread() > RISK_PROFILE.RP_spread) { UpdateCSV("delayed"); }
   
   
   switch (InpSpreadMgt){
   
      case Interval: // interval 
      
         if (util_market_spread() >= RISK_PROFILE.RP_spread) return -1;
         if (!DelayedAndValid()) return -1;
         break;
         
      case Recursive: // recursive
      
         while (util_market_spread() >= RISK_PROFILE.RP_spread || !DelayedAndValid()){
            Sleep(delay);
            
            if (TimeCurrent() >= TRADE_QUEUE.curr_trade_close) return -1;
         }
         break;
         
      case Ignore: // ignore 
      
         if (TimeCurrent() > TRADE_QUEUE.curr_trade_open) return -1;
         if (util_market_spread() >= RISK_PROFILE.RP_spread) return -1;
         break; 
         
      default: 
      
         break;
   }
   
   
   
   int ticket = OP_OrderOpen(Symbol(), order_type, CalcLot(), entry_price, sl_price, 0);
   if (ticket == -1) logger(StringFormat("ORDER SEND FAILED. ERROR: %i", GetLastError()));
   SetTradeOpenDatetime(TimeCurrent(), ticket);
   
   ActivePosition ea_pos;
   ea_pos.pos_ticket = ticket;
   ea_pos.pos_open_time = TRADES_ACTIVE.trade_open_datetime;
   ea_pos.pos_close_deadline = TRADES_ACTIVE.trade_close_datetime;
   AppendActivePosition(ea_pos);
   
   AddOrderToday(); // adds an order today
   // trigger an order open log containing order open price, entry time, target close time, and spread at the time of the order
   
   SetOrderOpenLogInfo(entry_price, TimeCurrent(), TRADES_ACTIVE.trade_close_datetime, ticket);
   if (!UpdateCSV("open")) { logger("Failed to Write To CSV. Order: OPEN"); }
   
   return 1;
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
   
   
   if (account_equity < InpMinimumEquity) {
      logger(StringFormat("TRADING DISABLED. Account Equity is below Minimum Trading Requirement. Current Equity: %f, Required: %f", account_equity, InpMinimumEquity));
      return false;
   }
   
   return true;
}

// ------------------------------- MAIN ------------------------------- //



// ------------------------------- TRADE OPERATIONS ------------------------------- //



// ------------------------------- MQL4 ------------------------------- //

#ifdef __MQL4__
double            CIntervalTrade::util_market_spread(void)    { return MarketInfo(Symbol(), MODE_SPREAD); }
double            CIntervalTrade::util_tick_val(void)         { return MarketInfo(Symbol(), MODE_TICKVALUE); }
double            CIntervalTrade::util_trade_pts(void)        { return MarketInfo(Symbol(), MODE_POINT); }

int               CIntervalTrade::PosTotal()       { return OrdersTotal(); }
int               CIntervalTrade::PosTicket()      { return OrderTicket(); }
double            CIntervalTrade::PosLots()        { return OrderLots(); }
string            CIntervalTrade::PosSymbol()      { return OrderSymbol(); }
int               CIntervalTrade::PosMagic()       { return OrderMagicNumber(); }
int               CIntervalTrade::PosOpenTime()    { return OrderOpenTime(); }
double            CIntervalTrade::PosOpenPrice()   { return OrderOpenPrice(); }
double            CIntervalTrade::PosProfit()      { return OrderProfit(); }
ENUM_ORDER_TYPE   CIntervalTrade::PosOrderType()   { return OrderType(); }
double            CIntervalTrade::PosSL()          { return OrderStopLoss(); }
double            CIntervalTrade::PosTP()          { return OrderTakeProfit(); }



int CIntervalTrade::OP_OrdersCloseAll(void){
   
   /*
   Main method for closing all open positions.
   */
   
   int open_positions = NumActivePositions(); // CHANGED FROM ARRAYSIZE METHOD
   
   
   // FUTURE CHANGES: ENQUEUE AND DEQUEUE
   for (int i = 0; i < open_positions; i++){
   
      int ticket = TRADES_ACTIVE.active_positions[i].pos_ticket;
      OP_CloseTrade(ticket);
   }
   
   ClearPositions(); // CHANGED FROM ARRAYFREE METHOD
   
   return 1;
}

int CIntervalTrade::OP_CloseTrade(int ticket){
   
   /*
   Receives a ticket, and closes the trade for specified ticket. 
   Deletes the trade if pending order (added as option for executing pending orders instead of spread recursion)
   */
   
   int t = OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
   
   ENUM_ORDER_TYPE ord_type = OrderType();
   int pending = util_is_pending(ord_type);
   int c = 0; 
   
   // SWITCH CHANGED FROM CHECKING IS PENDING, TO ORDER TYPE FLAGS
   
   switch(ord_type){
   
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_SELL: 
      
         c = OrderClose(OrderTicket(), PosLots(), ClosePrice(), 3);
         if (!c) logger(StringFormat("ORDER CLOSE FAILED. TICKTE: %i, ERROR: %i", ticket, GetLastError()));
         break;
         
      case ORDER_TYPE_BUY_LIMIT:
      case ORDER_TYPE_SELL_LIMIT:
      
         c = OrderDelete(OrderTicket());
         if (!c) logger(StringFormat("ORDER DELETE FAILED. TICKET: %i, ERROR: %i", ticket, GetLastError()));
         
         break;
         
      default:
      
         c = -1;
         break;
         
   }
   
   SetOrderCloseLogInfo(ClosePrice(), TimeCurrent(), PosTicket());
   
   if (!UpdateCSV("close")) logger("Failed to write to CSV. Order: CLOSE");
   if (c) logger(StringFormat("Closed: %i", PosTicket()));
   
   return 1;
}

int CIntervalTrade::OP_OrderOpen(
   string            symbol,
   ENUM_ORDER_TYPE   order_type,
   double            volume,
   double            price,
   double            sl,
   double            tp){

   /*
   Sends a market order
   */

   logger(StringFormat("Symbol: %s, Ord Type: %s, Vol: %f, Price: %f, SL: %f, TP: %f, Spread: %f", symbol, EnumToString(order_type), volume, price, sl, tp, util_market_spread()));
   int ticket = OrderSend(Symbol(), order_type, CalcLot(), entry_price, 3, sl_price, 0, (string)InpMagic, InpMagic, 0, clrNONE);
   return ticket;
}

bool CIntervalTrade::OP_TradeMatch(int index){

   /*
   Boolean validation if selected trade matches attached symbol, and magic number. 
   */

   int t = OrderSelect(index, SELECT_BY_POS, MODE_TRADES);
   if (PosMagic() != InpMagic) return false;
   if (PosSymbol() != Symbol()) return false;
   return true;
}

int CIntervalTrade::OP_OrderSelectByTicket(int ticket){
   
   /*
   Selects order by ticket
   */
   
   int s = OrderSelect(ticket, SELECT_BY_TICKET, MODE_TRADES);
   return s;
}

int CIntervalTrade::OP_ModifySL(double sl){
   
   /*
   Modifies Stop Loss of selected order when breakeven or trail stop is enabled.
   */
   
   // SELECT THE TICKET PLEASE 
   int m = OrderModify(PosTicket(), PosOpenPrice(), sl, 0, 0);
   return m;
}

#endif

// ------------------------------- MQL4 ------------------------------- //

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
int               CIntervalTrade::PosOpenTime()    { return PositionGetInteger(POSITION_TIME); }
double            CIntervalTrade::PosOpenPrice()   { return PositionGetDouble(POSITION_PRICE_OPEN); }
double            CIntervalTrade::PosProfit()      { return PositionGetDouble(POSITION_PROFIT); }
ENUM_ORDER_TYPE   CIntervalTrade::PosOrderType()   { return PositionGetInteger(POSITION_TYPE); }
double            CIntervalTrade::PosSL()          { return PositionGetDouble(POSITION_SL); }
double            CIntervalTrade::PosTP()          { return PositionGetDouble(POSITION_TP); }


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
      Print("TICKETS: ", tickets[i]);
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
   
   
   ENUM_ORDER_TYPE ord_type = OrderGetInteger(ORDER_TYPE);
   int c = 0;
   switch(ord_type){
      case ORDER_TYPE_BUY:
      case ORDER_TYPE_SELL:
         // market order
         if (PositionGetDouble(POSITION_PROFIT) > 0 && InpTradeMgt == Trailing) return -2; // ignores open positions in profit when using trail stop 
         c = Trade.PositionClose(ticket); // closes positions in loss when using trail stop 
         if (!c) { logger(StringFormat("ORDER CLOSE FAILED. TICKET: %i, ERROR: %i", ticket, GetLastError()));}
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
   if (c) { logger(StringFormat("Closed: %i", PosTicket())); }
   return c;
}



int CIntervalTrade::OP_OrderOpen(
   string            symbol, 
   ENUM_ORDER_TYPE   order_type, 
   double            volume, 
   double            price, 
   double            sl, 
   double            tp){
   
   bool t = Trade.PositionOpen(symbol, order_type, volume, price, sl, tp, NULL);
   logger(StringFormat("Symbol: %s, Ord Type: %s, Vol: %f, Price: %f, SL: %f, TP: %f, Spread: %f", symbol, EnumToString(order_type), volume, price, sl, tp, util_market_spread()));
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

int CIntervalTrade::OP_OrderSelectByTicket(int ticket){
   int s = PositionSelectByTicket(ticket);
   return s;
}

int CIntervalTrade::OP_ModifySL(double sl){
   // SELECT THE TICKET PLEASE
   int m = Trade.PositionModify(PosTicket(), sl, PosTP());
   return m;
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
   
   double last_open = iOpen(Symbol(), PERIOD_CURRENT, 0);
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

int CIntervalTrade::logger(string message){
   if (!InpTerminalMsg) return -1;
   Print("LOGGER: ", message);
   return 1;
}

void CIntervalTrade::errors(string error_message)     { Print("ERROR: ", error_message); }

double   CIntervalTrade::util_price_ask(void)         { return SymbolInfoDouble(Symbol(), SYMBOL_ASK); }
double   CIntervalTrade::util_price_bid(void)         { return SymbolInfoDouble(Symbol(), SYMBOL_BID); }

double   CIntervalTrade::util_last_candle_open(void)  { return iOpen(Symbol(), PERIOD_CURRENT, 0); }
double   CIntervalTrade::util_last_candle_close(void) { return iClose(Symbol(), PERIOD_CURRENT, 0); }

double   CIntervalTrade::account_balance(void)        { return AccountInfoDouble(ACCOUNT_BALANCE); }
string   CIntervalTrade::account_server(void)         { return AccountInfoString(ACCOUNT_SERVER); }

int      CIntervalTrade::util_interval_day(void)      { return PeriodSeconds(PERIOD_D1); }
int      CIntervalTrade::util_interval_current(void)  { return PeriodSeconds(PERIOD_CURRENT); }

// ------------------------------- UTILS AND WRAPPERS ------------------------------- //


