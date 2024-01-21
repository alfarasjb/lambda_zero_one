

#include <B63/FFCalendarDownload.mqh>
#include "definition.mqh"



class CNewsEvents{

   protected:
   private:
   public:
      
      SFFEvent    NEWS_CURRENT[], NEWS_TODAY[], NEWS_SYMBOL_TODAY[];
      
      
      CNewsEvents();
      ~CNewsEvents() {};
      
      
      int      FetchData();
      int      FetchNewsToday();
      bool     HighImpactNewsToday();
      int      NumNews();
      void     PrintNews();
      datetime DateToday();
      void     NextWeek();
      datetime LatestWeeklyCandle();
      
      int      AppendToNews(SFFEvent &event, SFFEvent &news_data[]);
      int      DownloadFromForexFactory(string file_name);
      bool     FileExists(string file_path);
      datetime GetDate(datetime parse_datetime);
      int      GetNewsSymbolToday();
      int      ClearArray(SFFEvent &data[]);
      bool     DateMatch(datetime target, datetime reference);
      bool     SymbolMatch(string country);
      bool     ArrayIsEmpty(SFFEvent &data[]);
};


CNewsEvents::CNewsEvents(void){
}


int CNewsEvents::FetchData(void){
   ClearArray(NEWS_CURRENT);
   

   datetime latest = LatestWeeklyCandle(); 
   int delta = (int)(TimeCurrent() - latest); 
   int weekly_delta = PeriodSeconds(PERIOD_W1);
   
   datetime file_date = delta > weekly_delta ? latest + weekly_delta : latest;
   //datetime file_date = latest;
   
   string file_name = StringFormat("%s.csv", TimeToString(file_date, TIME_DATE));
   string file_path = StringFormat("%s\\%s", FXFACTORY_DIRECTORY, file_name);
   // attempt to open file, if file does not exist, download from fxfactory
   
   
   if (!FileExists(file_path)) {
      PrintFormat("File %s not found. Downloading from forex factory.", file_path);
      DownloadFromForexFactory(file_name);
   }
   else PrintFormat("File %s found", file_path);
   
   
   string result[];
   string sep = ",";
   string sep_char = StringGetCharacter(sep, 0);
   
   int line = 0;
   
   int handle = FileOpen(file_path, FILE_CSV | FILE_READ | FILE_ANSI, "\n");
   if (handle == -1) return -1;
   
   while (!FileIsLineEnding(handle)){
      //if (line == 0) continue; 
      string file_string = FileReadString(handle);
      
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
   
   
   // check for array size if array ssize of news today is not empty, check the first date if same with today. 
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
   
   //ArrayResize(NEWS_CURRENT, downloader.Count);
   
   //for (int i = 0; i < downloader.Count; i++) NEWS_CURRENT[i] = downloader.Events[i];
   
   return NumNews();
}

int CNewsEvents::NumNews(void) { return ArraySize(NEWS_CURRENT); }

void CNewsEvents::PrintNews(void){
   int num_news = NumNews();
   
   for (int i = 0; i < num_news; i ++){
      string title = NEWS_CURRENT[i].title;
      string impact = NEWS_CURRENT[i].impact;
      datetime date = NEWS_CURRENT[i].time;
      PrintFormat("Title: %s", title);
      PrintFormat("Impact: %s", impact);
      PrintFormat("Date: %s", TimeToString(date));
      PrintFormat("Today; %s", TimeToString(DateToday()));
      break;
   }
   
}


datetime CNewsEvents::DateToday(void){ return (GetDate(TimeCurrent())); }

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

datetime CNewsEvents::LatestWeeklyCandle() { return iTime(Symbol(), PERIOD_W1, 0); }