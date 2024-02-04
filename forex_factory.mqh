

#include <B63/FFCalendarDownload.mqh>
#include "definition.mqh"



class CNewsEvents{

   protected:
   private:
      datetime    entry_window_open, entry_window_close;
   
   public:
      
      SFFEvent    NEWS_CURRENT[], NEWS_TODAY[], NEWS_SYMBOL_TODAY[], NEWS_IN_TRADING_WINDOW[];
      int         FILE_HANDLE;
      
      CNewsEvents();
      ~CNewsEvents();
      
      void        UpdateEntryWindow(datetime window_open, datetime window_end);
      
      int         FetchData();
      int         AppendToNews(SFFEvent &event, SFFEvent &news_data[]);
      int         DownloadFromForexFactory(string file_name);
      int         GetNewsSymbolToday();
      
      datetime    DateToday();
      datetime    LatestWeeklyCandle();
      datetime    GetDate(datetime parse_datetime);
      datetime    ParseDates(string date, string time);
      
      int         ClearArray(SFFEvent &data[]);
      bool        DateMatch(datetime target, datetime reference);
      bool        SymbolMatch(string country);
      bool        ArrayIsEmpty(SFFEvent &data[]);
      bool        FileExists(string file_path);
      bool        HighImpactNewsToday();
      int         NumNews();
      int         NumNewsToday();
      int         NumNewsInWindow();
      int         ClearHandle();
      int         GetHighImpactNewsInEntryWindow(datetime entry_open, datetime entry_close);
      bool        HighImpactNewsInEntryWindow();
};


CNewsEvents::CNewsEvents(void){
}

CNewsEvents::~CNewsEvents(void){
   ClearHandle();
}

void CNewsEvents::UpdateEntryWindow(datetime window_open,datetime window_end){
   entry_window_open = window_open;
   entry_window_close = window_end;
}

int CNewsEvents::ClearHandle(void){
   FileClose(FILE_HANDLE);
   FileFlush(FILE_HANDLE);
   FILE_HANDLE = 0;
   return FILE_HANDLE;
}

int CNewsEvents::FetchData(void){

   ResetLastError();
   ClearArray(NEWS_CURRENT);
   ClearHandle();

   datetime latest = LatestWeeklyCandle(); 
   int delta = (int)(TimeCurrent() - latest); 
   int weekly_delta = PeriodSeconds(PERIOD_W1);
   
   datetime file_date = delta > weekly_delta ? latest + weekly_delta : latest;
   //datetime file_date = latest;
   
   string file_name = StringFormat("%s.csv", TimeToString(file_date, TIME_DATE));
   string file_path = StringFormat("%s\\%s", FXFACTORY_DIRECTORY, file_name);
   // attempt to open file, if file does not exist, download from fxfactory
   
   
   if (!FileExists(file_path)) {
      PrintFormat("%s: File %s not found. Downloading from forex factory.", __FUNCTION__, file_path);
      if (DownloadFromForexFactory(file_name) == -1) PrintFormat("%s: Download Failed. Error: %i", __FUNCTION__, GetLastError());
   }
   else PrintFormat("%s: File %s found", __FUNCTION__, file_path);
   
   
   string result[];
   string sep = ",";
   string sep_char = StringGetCharacter(sep, 0);
   
   int line = 0;
   
   FILE_HANDLE = FileOpen(file_path, FILE_CSV | FILE_READ | FILE_ANSI, "\n");
   if (FILE_HANDLE == -1) return -1;
   
   while (!FileIsLineEnding(FILE_HANDLE)){
   
      string file_string = FileReadString(FILE_HANDLE);
      
      int split = (int)StringSplit(file_string, sep_char, result);
      line++;
      if (line == 1) continue;
      // append to news events here
      
      /*
      0 title
      1 country
      2 date
      3 time
      4 impact
      5 forecast
      6 previous
      */
      
      SFFEvent event;
      event.title = result[0];
      event.country = result[1];
      event.time = ParseDates(result[2], result[3]);
      event.impact = result[4];
      event.forecast = result[5];
      event.previous = result[6];
      AppendToNews(event, NEWS_CURRENT);
      //break;
   }
   GetNewsSymbolToday();
   return NumNews();
}

bool CNewsEvents::FileExists(string file_path){
   int handle = FileOpen(file_path, FILE_CSV | FILE_READ | FILE_ANSI, "\n");
   if (handle == -1) return false;
   FileClose(handle);
   FileFlush(handle);
   return true;
}

datetime CNewsEvents::ParseDates(string date, string time){

   string result[];
   ushort u_sep = StringGetCharacter("-", 0);
   int split = StringSplit(date, u_sep, result);
   
   int gmt_offset = (int)MathAbs(TimeGMTOffset());
   int server_offset = (int)(TimeLocal() - TimeCurrent());
   
   int gmt_offset_hours = gmt_offset / PeriodSeconds(PERIOD_H1);
   int server_offset_hours = server_offset / PeriodSeconds(PERIOD_H1);
   int gmt_server_offset_hours = gmt_offset_hours - server_offset_hours - 1;
   
   int gmt_server_offset_seconds = gmt_server_offset_hours * PeriodSeconds(PERIOD_H1);
   
   
   datetime time_string = StringToTime(time);
   MqlDateTime event_date, event_time;
   TimeToStruct(time_string, event_time);
   TimeToStruct(date, event_date);
   
   bool IsPM = StringFind(time, "pm") > -1 ? true : false;
   
   event_time.mon = (int)result[0]; 
   event_time.day = (int)result[1];
   event_time.year = (int)result[2];
   //event_time.hour = !IsPM && event_time.hour == 12 ? 0 : event_time.hour + 12;
   event_time.hour = !IsPM ? event_time.hour == 12 ? 0 : event_time.hour : event_time.hour != 12 ? event_time.hour + 12 : event_time.hour;
   
   
   // GMT DATETIME
   datetime event = StructToTime(event_time);
   
   datetime final_dt = event + gmt_server_offset_seconds;
   //PrintFormat("INPUT: %s %s, OUTPUT: %s", date, time, TimeToString(final_dt));
   //PrintFormat("INPUT: %s, MONTH: %i, DAY: %i, DATESTRING: %s, EVENT: %s, FINAL: %s", date, event_time.mon, event_time.day, date, TimeToString(event), TimeToString(final_dt));
   return final_dt;
}

int CNewsEvents::GetNewsSymbolToday(void){
   // iterate through main dataset and identify symbol and date. 
   // Appends to news today: High impact and holiday. 
   
   ClearArray(NEWS_SYMBOL_TODAY);
   int size = NumNews();
   
   
   
   for (int i = 0; i < size; i++){
       
       if (!SymbolMatch(NEWS_CURRENT[i].country)) continue; 
       
       if (!DateMatch(DateToday(), NEWS_CURRENT[i].time)) continue; 
       //PrintFormat("TITLE: %s, TIME: %s", NEWS_CURRENT[i].title, TimeToString(NEWS_CURRENT[i].time));
       if ((NEWS_CURRENT[i].impact == "High") || (NEWS_CURRENT[i].impact == "Holiday")) AppendToNews(NEWS_CURRENT[i], NEWS_SYMBOL_TODAY); 
   }
   return ArraySize(NEWS_SYMBOL_TODAY);
}

bool CNewsEvents::HighImpactNewsToday(void) {
   if (ArraySize(NEWS_SYMBOL_TODAY) == 0) return false;
   if (InpTradeOnNews) return false;
   return true; 
}

int CNewsEvents::GetHighImpactNewsInEntryWindow(datetime entry_open,datetime entry_close){
   // REFRESH THIS EVERY DAY 
   
   ClearArray(NEWS_IN_TRADING_WINDOW);
   int size = ArraySize(NEWS_SYMBOL_TODAY);
   
   for (int i = 0; i < size; i ++){
      datetime news_time = NEWS_SYMBOL_TODAY[i].time;
      //Print(NEWS_SYMBOL_TODAY[i].title, news_time);
      if (news_time < entry_open) continue; // before
      if (news_time > entry_close) continue; // after 
      AppendToNews(NEWS_SYMBOL_TODAY[i], NEWS_IN_TRADING_WINDOW);
   }
   return ArraySize(NEWS_IN_TRADING_WINDOW);
}

bool CNewsEvents::HighImpactNewsInEntryWindow(void){
   if (InpTradeOnNews) return false; 
   if (ArraySize(NEWS_IN_TRADING_WINDOW) == 0) return false;
   return true;
}

int CNewsEvents::AppendToNews(SFFEvent &event, SFFEvent &news_data[]){
 
   
   int size = ArraySize(news_data);
   ArrayResize(news_data, size + 1);
   news_data[size] = event; 
   
   
   return NumNews();
}

int CNewsEvents::DownloadFromForexFactory(string file_name){
   CFFCalendarDownload *downloader = new CFFCalendarDownload(FXFACTORY_DIRECTORY, 50000);
   bool success = downloader.Download(file_name);
   
   delete downloader;
   if (!success) return -1; 
   return NumNews();
}




datetime CNewsEvents::GetDate(datetime parse_datetime){
   MqlDateTime dt_struct;
   TimeToStruct(parse_datetime, dt_struct);
   
   dt_struct.hour = 0;
   dt_struct.min = 0;
   dt_struct.sec = 0; 
   
   return StructToTime(dt_struct);
}

int CNewsEvents::ClearArray(SFFEvent &data[]){
   ArrayFree(data);
   ArrayResize(data, 0);
   return ArraySize(data);
}

bool CNewsEvents::DateMatch(datetime target,datetime reference){
   if (StringFind(TimeToString(target), TimeToString(reference, TIME_DATE)) == -1) return false;
   return true;
}

bool CNewsEvents::SymbolMatch(string country){
   int match = StringFind(Symbol(), country);
   //PrintFormat("FIND: %s, COUNTRY: %s, RESULT: %i", Symbol(), country, match);
   
   if (StringFind(Symbol(), country) == -1) return false;
   return true;
}

bool CNewsEvents::ArrayIsEmpty(SFFEvent &data[]){
   if (ArraySize(data) == 0) return true; 
   return false;
}

datetime    CNewsEvents::LatestWeeklyCandle()      { return iTime(Symbol(), PERIOD_W1, 0); }
datetime    CNewsEvents::DateToday(void)           { return (GetDate(TimeCurrent())); }
int         CNewsEvents::NumNews(void)             { return ArraySize(NEWS_CURRENT); }
int         CNewsEvents::NumNewsToday(void)        { return ArraySize(NEWS_SYMBOL_TODAY); }
int         CNewsEvents::NumNewsInWindow(void)     { return ArraySize(NEWS_IN_TRADING_WINDOW); }