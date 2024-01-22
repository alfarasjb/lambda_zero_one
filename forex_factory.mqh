

#include <B63/FFCalendarDownload.mqh>
#include "definition.mqh"



class CNewsEvents{

   protected:
   private:
   public:
      
      SFFEvent    NEWS_CURRENT[], NEWS_TODAY[], NEWS_SYMBOL_TODAY[];
      int         FILE_HANDLE;
      
      CNewsEvents();
      ~CNewsEvents();
      
      
      int         FetchData();
      int         AppendToNews(SFFEvent &event, SFFEvent &news_data[]);
      int         DownloadFromForexFactory(string file_name);
      int         GetNewsSymbolToday();
      
      datetime    DateToday();
      datetime    LatestWeeklyCandle();
      datetime    GetDate(datetime parse_datetime);
      
      int         ClearArray(SFFEvent &data[]);
      bool        DateMatch(datetime target, datetime reference);
      bool        SymbolMatch(string country);
      bool        ArrayIsEmpty(SFFEvent &data[]);
      bool        FileExists(string file_path);
      bool        HighImpactNewsToday();
      int         NumNews();
      int         NumNewsToday();
      int         ClearHandle();
};


CNewsEvents::CNewsEvents(void){
}

CNewsEvents::~CNewsEvents(void){
   ClearHandle();
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
      
      SFFEvent event;
      event.title = result[0];
      event.country = result[1];
      event.time = StringToTime(result[2]);
      event.impact = result[3];
      event.forecast = result[4];
      event.previous = result[5];
      AppendToNews(event, NEWS_CURRENT);
            
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

int CNewsEvents::GetNewsSymbolToday(void){
   // iterate through main dataset and identify symbol and date. 
   
   
   ClearArray(NEWS_SYMBOL_TODAY);
   int size = NumNews();
   
   
   for (int i = 0; i < size; i++){
       if (!SymbolMatch(NEWS_CURRENT[i].country)) continue; 
       if (!DateMatch(DateToday(), NEWS_CURRENT[i].time)) continue; 
       if ((NEWS_CURRENT[i].impact != "High") || (NEWS_CURRENT[i].impact != "Holiday")) continue;
       AppendToNews(NEWS_CURRENT[i], NEWS_SYMBOL_TODAY); 
   }
   return ArraySize(NEWS_SYMBOL_TODAY);
}

bool CNewsEvents::HighImpactNewsToday(void) {
   if (ArraySize(NEWS_SYMBOL_TODAY) == 0 && GetNewsSymbolToday() == 0) return false;
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