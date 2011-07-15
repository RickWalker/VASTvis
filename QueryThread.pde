import com.almworks.sqlite4java.*;

import java.sql.ResultSet;
import java.sql.SQLException;

class QueryThread implements Runnable{
  
  PApplet parent;
  private boolean running;
  Thread runner;
  private boolean available;
  private String query;
  //private Map results;
  //DescriptiveStatistics plotStats;
  QueryResultSet allResults;
  private String v1, v2;
  private int matchCount, rowCount;
  SQLiteConnection connection;
  SQLiteStatement stmt;
  //SQLite db;
  
  public QueryThread(PApplet p, String q, String v1, String v2){
    parent = p;
    query = q;
    this.v1 = v1;
    this.v2 = v2;
    connection = null;
    allResults = new QueryResultSet();
    
    //runner = new Thread(this);
    //runner.start();
    available = false;
    running = true;
    e.execute(this);

  }
  
  public void run(){
    //do the query!
    runQuery();
    available = true;
    println("Available data");
  }
  
  public void dispose(){
    stop();
    System.out.println("calling dispose");
  }
  
  public void stop(){
    runner = null;
  }
  
  public boolean available(){
    return available;
  }
  
  public void cancel(){
    if(stmt != null){
      stmt.cancel();
      println("Cancelling thread!");
    }else{
      running = false;
      //hasn't started yet, so don't ever run it!
    }
  }
  
  private void runQuery(){
    if(running){
      //last cache check!
      if(queryCache.containsKey(query)){
        println("Thread check says query already in cache: " + query);
        allResults = queryCache.get(query);
      }else{
        //actually run the thread
          
        try{
          println("Running query: " + query);
          connection = new SQLiteConnection(new File(parentApp.sketchPath("VAST-challenge")));
          connection.open(false);
          stmt = connection.prepare(query);
          
           //now work out how to handle results!
          if(v1.startsWith("DATE")) {
            if(v2.startsWith("COUNT")){
              generateResultsDate(stmt);
             }else{
              generateResultsDateFloat(stmt);
            }
          }
          else if(v1.startsWith("SYMPTOM")) {
            generateResultsSymptom(stmt);
          }
          else {
            generateResultsNormal(stmt);
          }
          //println("Finished with resultset now");
          allResults.query = query;
          allResults.updateStats();
        }catch(SQLiteInterruptedException e){
          println("Interrupted query " + query);
        }catch(SQLiteException e){
          println(e.getMessage());
        } finally {
          stmt.dispose();
          connection.dispose();
        }
      }
    }else{
     println("Not running task " + query + " because it's outdated"); 
    }  
  }
  
  
  private void generateResultsNormal(SQLiteStatement s) throws SQLiteException{
    //TreeMap toReturn = new TreeMap<Integer, Integer>();
    allResults.data = new HashMap<Integer, Integer>(int((endAge - startAge) * 1.5), 0.9);
    matchCount = rowCount = 0;
    int a =0, c=0;
    int count = 0;
    
    float xmin, xmax, ymin, ymax;
    
    ymax = xmax = Float.MIN_VALUE;
    ymin = xmin = Float.MAX_VALUE;
    while (s.step()) {
      //println(count++);
      
      a = s.columnInt(0);
      c = s.columnInt(1);
      allResults.data.put(a,c);
      xmin = min(a, xmin);
      ymin = min(c, ymin);
      xmax = max(a, xmax);
      ymax = max(c, ymax);
      
      if(v2.startsWith("COUNT")) {
        matchCount +=c;
        for(int j = 0; j< c; j++){
            allResults.plotStats.addValue(a);           
        }
      }
      else {
        matchCount ++;
        allResults.plotStats.addValue(c);
      }
      rowCount++;
    }
    if(v1.equals("AGE")){
      xmin = startAge;
      xmax = endAge;
    }
    
    allResults.matchCount = matchCount;
    allResults.rowCount = rowCount;
    allResults.xmax = xmax;
    allResults.xmin = xmin;
    allResults.ymax = ymax;
    allResults.ymin = ymin;
  }

  //TreeMap performDateQuery(String fromPlot, String v1, String v2) {
  private void generateResultsDate(SQLiteStatement db) throws SQLiteException{
    allResults.data  = new HashMap<Integer, Integer>(int((endDate-startDate)*1.5), 0.9);
    //println("Saving space for " + int((endDate-startDate)*1.5));
    //TreeMap toReturn = new TreeMap<Integer, Integer>();
    matchCount = rowCount = 0;
    long divisorToInt = 86400000;
    String a;
    int c;
    float xmin, xmax, ymin, ymax;
    int final_a;
        
    ymax = xmax = Float.MIN_VALUE;
    ymin = xmin = Float.MAX_VALUE;
    
    Date keyDate = new Date();
    while (db.step()) {
      a = db.columnString(0);
      c = db.columnInt(1);
      

      //format to date, and put time in days since 1971 into treemap
      try {
        keyDate = toMilli.parse(a);
      }
      catch (ParseException e) {
        println("Can't parse date " + a);
      }
      //println("Date is " + keyDate);
      //println("Date put in is "+ (int) (keyDate.getTime()/divisorToInt) + " which is " + (long) ((int) (keyDate.getTime()/divisorToInt)*divisorToInt) + " vs " + keyDate.getTime() + " which is "+ new Date((long) ((keyDate.getTime()/divisorToInt)*divisorToInt)) );
      final_a = (int) ((keyDate.getTime()/divisorToInt));
      allResults.data.put(final_a, c);
      
      xmin = min(final_a, xmin);
      ymin = min(c, ymin);
      xmax = max(final_a, xmax);
      ymax = max(c, ymax);

      if(v2.startsWith("COUNT")) {
        matchCount +=c;
        for(int j = 0; j< c; j++){
            allResults.plotStats.addValue(final_a);           
        }
      }
      else {
        matchCount ++;
        allResults.plotStats.addValue(c);
      }
      rowCount++;
    }
    
        
    allResults.matchCount = matchCount;
    allResults.rowCount = rowCount;
    allResults.xmax = xmax;
    allResults.xmin = xmin;
    allResults.ymax = ymax;
    allResults.ymin = ymin;
  }

  private void generateResultsSymptom(SQLiteStatement db) throws SQLiteException{

    allResults.data = new HashMap<String, Integer>(70, 0.99);
    //TreeMap toReturn = new TreeMap<String, Integer>();
    matchCount = rowCount = 0;
    int millisecondsInDay = 86400000;
    while (db.step()) {
      String a = db.columnString(0);
      int c = db.columnInt(1);

      allResults.data.put(a, c);

      if(v2.startsWith("COUNT")) {
        matchCount +=c;
      }
      else {
        matchCount ++;
      }
      rowCount++;
    }
    
    //totally gonna cheat here to make sure all symptoms show up
    for(String a: symptomFilters.keySet()){
      if(!allResults.data.containsKey(a)){
        allResults.data.put(a, 0);
      }
    }
    //db.close();
  }
  
  private void generateResultsDateFloat(SQLiteStatement db)throws SQLiteException{
  
    allResults.data = new HashMap<Integer, Float>(int((endDate-startDate)*1.5), 0.9);
    matchCount = rowCount = 0;
    long divisorToInt = 86400000;
 
    Date keyDate = new Date();
    String a;
    float c;
    while (db.step()) {
      a = db.columnString(0);//getString(v1);
      c = (float) db.columnDouble(1);
      //format to date, and put time in days since 1971 into treemap
      try {
        keyDate = toMilli.parse(a);
      }
      catch (ParseException e) {
        println("Can't parse date " + a);
      }
      //println("Date is " + keyDate);
      //println("Date put in is "+ (int) (keyDate.getTime()/divisorToInt) + " which is " + (long) ((int) (keyDate.getTime()/divisorToInt)*divisorToInt) + " vs " + keyDate.getTime() + " which is "+ new Date((long) ((keyDate.getTime()/divisorToInt)*divisorToInt)) );
      allResults.data.put((int) ((keyDate.getTime()/divisorToInt)), c);

      if(v2.startsWith("COUNT")) {
        matchCount +=c;
      }
      else {
        matchCount ++;
      }
      rowCount++;
    }
    
  }
  
  
  private synchronized Map getResults(){
    return allResults.data;
  }
  
  private synchronized QueryResultSet getAllResults(){
    return allResults;
  }
}
