
#include "definition.mqh"


/*
   Use for backtesting only. 
*/


class CLoader{
   protected:
   private:
   public: 
      datetime    BACKTEST_START_DATE, date_entry, DATES[];
      int         NUM_LOADED_HISTORY;
      
      CLoader();
      int         LoadFromFile();
      datetime    StringToDate(string date_string);
      int         AppendToDates(datetime date_to_append);
      int         NumDates();
      
      int         Dequeue();
      bool        IsNewsDate();
      datetime    ConvertToDate(datetime date);
      
};


CLoader::CLoader(){
   BACKTEST_START_DATE = StringToTime(InpBacktestStart);
   
}

int CLoader::LoadFromFile(void){
   string path = "lambda_zero_one\\audusd_news_dates.csv";
   int handle = FileOpen(path, FILE_READ | FILE_CSV | FILE_COMMON | FILE_ANSI, "\n");
   
   string result[];
   string sep = ",";
   string sep_char = StringGetCharacter(sep, 0);
   
   int loaded = 0;
   Print("START: ", BACKTEST_START_DATE);
   
   if (handle == -1) Print("LOAD FAILED");
   while(!FileIsLineEnding(handle)) {
      string file_string = FileReadString(handle);
      
      int split = (int)StringSplit(file_string, sep_char, result);
      
      string date_string = result[0];
      
      datetime converted = StringToDate(date_string);
      if (converted < BACKTEST_START_DATE) continue; 
      AppendToDates(converted);
      loaded++;
   }
   
   FileClose(handle);
   FileFlush(handle);
   
   PrintFormat("Processed from file: %i, Added To Dates: %i", loaded, NumDates());
   PrintFormat("START: %s END: %s", TimeToString(DATES[0]), TimeToString(DATES[NumDates() - 1]));
   NUM_LOADED_HISTORY = loaded;
   return loaded;
}

datetime CLoader::StringToDate(string date_string){
   string components[];
   int date_split = (int)StringSplit(date_string, StringGetCharacter("/", 0), components);
   
   MqlDateTime converted; 
   converted.year = (int)components[2];
   converted.mon = (int)components[0];
   converted.day = (int)components[1];
   converted.hour = 0;
   converted.min = 0;
   converted.sec = 0;
   
   return StructToTime(converted);
}

int CLoader::AppendToDates(datetime date_to_append){
   int size = NumDates();
   ArrayResize(DATES, size + 1);
   
   DATES[size] = date_to_append;
   
   return NumDates();
}

int CLoader::NumDates(void) {return ArraySize(DATES); }

int CLoader::Dequeue(void){
   datetime temp[];
   
   ArrayCopy(temp,DATES,0, 1);
   ArrayFree(DATES);
   ArrayCopy(DATES, temp);
   
   return NumDates();
}

bool CLoader::IsNewsDate(void){
   if (InpTradeOnNews) return false;
   if (NumDates() == 0) return false;
   datetime today = ConvertToDate(TimeCurrent());
   datetime next_entry = DATES[0];
   if (today == next_entry) return true;
   if (today < next_entry) return false;
   if (today > next_entry) {
      if (Dequeue() == 1) return false;
      IsNewsDate();
   }
   return false;   
}

datetime CLoader::ConvertToDate(datetime date){
   MqlDateTime converted; 
   TimeToStruct(date, converted);
   
   converted.hour = 0;
   converted.min = 0;
   converted.sec = 0;
   
   return StructToTime(converted);
}