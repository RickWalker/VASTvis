import java.util.TreeMap;
import java.util.Map.Entry;


abstract class PlotContents {

  String city;
  Map values;
  String previousQuery;
  color col;
  //DescriptiveStatistics plotStats;
  float mean, median, q1, q3, sd, skewness, kurtosis;
  float tenthpercentile, ninetiethpercentile;
  float whiskerTop, whiskerBottom; //largest and smallest points within 3/2 of (q3-q1) of q1 and q3
  int totalValues;
  Integrator upToDate;  
  boolean dataChanged;
  boolean needsUpdate;
  
  QueryThread myQuery;

  int xmin, xmax, ymin, ymax;

  PlotContents(String city) {
    this.city = city;
    dataChanged = false;
    needsUpdate = false;
    //values = new TreeMap<Object, Object>();
    previousQuery = "";
    upToDate = new Integrator(20, 0.5, 0.1);
    upToDate.target(255);

    xmin = ymin = Integer.MAX_VALUE;
    xmax = ymax = Integer.MIN_VALUE;
    //plotStats = new DescriptiveStatistics();
    //update(); //populate TreeMap with necessary data
  }

  
  void dispose(){
    if(myQuery != null){
      myQuery.cancel();
    }
  }

  void updateStats() {
  /*  mean = (float) plotStats.getMean();
    median = (float)plotStats.apply(new Median());
    q1 = (float)plotStats.getPercentile(25);
    q3 = (float)plotStats.getPercentile(75);
    sd = (float)plotStats.getStandardDeviation();
    skewness = (float)plotStats.getSkewness();
    kurtosis = (float)plotStats.getKurtosis();
    //harder: work out whisker top and bottom!
    tenthpercentile = (float) plotStats.getPercentile(10);
    ninetiethpercentile = (float) plotStats.getPercentile(90);*/
    //done in thread now
  }

  float get(Number k) { //change: gives the right type back?
    //either return the value, or -1 for not found
    if(values.containsKey(k)) {
      //int a = ((Number) values.get(k)).intValue();
      float a = ((Number) values.get(k)).floatValue();
      //if(normalise) return map(a, ymin, ymax, 0, 1);
      //else return a;
      return a;
    }
    else {
      return -1;
    }
  }

  float normalise(float value) {
    return map(value, ymin, ymax, 0, 1.0);
  }
  
  String convertForDisplay(Number a){
    //default is just string, over-ride for date
    return ""+nf(a.floatValue(), 1,2);
  }

  String getString(Number k) {
    //either return the value, or -1 for not found
    if(values.containsKey(k)) {
      String a = (String)values.get(k);
      //if(normalise) return map(a, ymin, ymax, 0, 1);
      //else return a;
      return a;
    }
    else {
      return "blank";
    }
  }

  void update(String query, String xv, String yv) {
    totalValues = 0;
    //updateStats();
  }

  int getMaxX() {
    return xmax;
  }

  int getMinX() {
    return xmin;
  }

  int getMaxY() {
    return ymax;
  }

  int getMinY() {
    return ymin;
  }

  String convertForDisplay(float a) {
    return ""+nf(a,1,2);
  }

  abstract String convertValueToDatabaseFormat(float v);

  abstract float convertValueFromDatabaseFormat(String s);

  abstract void draw(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2);
  
  void getDataFromThread(){//String query, String xv, String yv){
    //perform query
    QueryResultSet temp = myQuery.getAllResults();
    values = temp.data;
    //plotStats = temp.plotStats;
    //min/max
    xmin = int(temp.xmin);
    xmax = int(temp.xmax);
    ymin = int(temp.ymin);
    ymax = int(temp.ymax);
    
    //stats  
    mean = temp.mean;
    median = temp.median;
    q1 = temp.q1;
    q3 = temp.q3;
    sd = temp.sd;
    skewness = temp.skewness;
    kurtosis = temp.kurtosis;
    //harder: work out whisker top and bottom!
    tenthpercentile = temp.tenthpercentile;
    ninetiethpercentile = temp.ninetiethpercentile;

    totalValues = temp.matchCount;
    ymin = 0;
    //add to cache!
    queryCache.put(temp.query, temp);
  }
  
  void getDataFromCache(String q){
    println("Cache hit for " + q);
    //look up query
    QueryResultSet temp = queryCache.get(q);
    values = temp.data;
    //plotStats = temp.plotStats;
    //min/max
    xmin = int(temp.xmin);
    xmax = int(temp.xmax);
    ymin = int(temp.ymin);
    ymax = int(temp.ymax);
    
    //stats  
    mean = temp.mean;
    median = temp.median;
    q1 = temp.q1;
    q3 = temp.q3;
    sd = temp.sd;
    skewness = temp.skewness;
    kurtosis = temp.kurtosis;
    //harder: work out whisker top and bottom!
    tenthpercentile = temp.tenthpercentile;
    ninetiethpercentile = temp.ninetiethpercentile;

    totalValues = temp.matchCount;
    ymin = 0;   
  }
  
  void drawStats(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2){
    strokeWeight(2);
    //stroke(col);
    stroke(red(col), green(col), blue(col), 100);
    fill(red(col), green(col), blue(col), 100);
    textSize((plotX2-plotX1)/80);
    //lines for stats with labels!
    textAlign(LEFT);
    text(convertForDisplay(median), map( median, xmin, xmax, plotX1, plotX2), (plotY1 + plotY2)/2);
    line(map( median, xmin, xmax, plotX1, plotX2), plotY1, map(median, xmin, xmax, plotX1, plotX2),plotY2); 
    text(convertForDisplay(q1),map( q1, xmin, xmax, plotX1, plotX2), (plotY1 + plotY2)/2);
    line(map( q1, xmin, xmax, plotX1, plotX2), plotY1, map(q1, xmin, xmax, plotX1, plotX2),plotY2);
    text(convertForDisplay(q3),map( q3, xmin, xmax, plotX1, plotX2), (plotY1 + plotY2)/2);
    line(map( q3, xmin, xmax, plotX1, plotX2), plotY1, map(q3, xmin, xmax, plotX1, plotX2),plotY2); 
    
    //line(map( tenthpercentile, xmin, xmax, plotX1, plotX2), plotY1, map(tenthpercentile, xmin, xmax, plotX1, plotX2),plotY2);
    
    //line(map( ninetiethpercentile, xmin, xmax, plotX1, plotX2), plotY1, map(ninetiethpercentile, xmin, xmax, plotX1, plotX2),plotY2);
    
    //draws a normal distribution
    float mysd = sd;
    float mymean = mean;
    
    float firstbit = 1.0/(mysd * sqrt(2*PI));
    float twosd2 = 2* mysd*mysd;
    float peakvalue = firstbit * exp(0);
    if(!normalise) peakvalue *= 1.1;
    //println("SD is " + mysd);
      
    noFill();
     //stroke(red(col), green(col), blue(col), 100);
     float y, tx=0, ty=0;
    beginShape();     
    for(float x = xmin; x<= xmax; x+=0.25){
      y = firstbit * exp(-((x-mymean)*(x-mymean))/twosd2);
      ty = map(y, 0, peakvalue , plotY2, plotY1);
      tx = map(x, xmin, xmax, plotX1, plotX2);
      curveVertex(tx,ty);
    }
    curveVertex(tx,ty);
    endShape();
  }
  
  void drawMean(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2){
    strokeWeight(2);
    //stroke(col);
    stroke(red(col), green(col), blue(col), 100);
    fill(red(col), green(col), blue(col), 100);
    textSize((plotX2-plotX1)/80);
    //lines for stats with labels!
    textAlign(LEFT);
    //mean
    text(convertForDisplay(mean), map( mean, xmin, xmax, plotX1, plotX2), (plotY1 + plotY2)/2);
    line(map( mean, xmin, xmax, plotX1, plotX2), plotY1, map(mean, xmin, xmax, plotX1, plotX2),plotY2); 
    //sd one side
    text(convertForDisplay(mean+sd),map(mean+sd, xmin, xmax, plotX1, plotX2), (plotY1 + plotY2)/2);
    line(map( mean+sd, xmin, xmax, plotX1, plotX2), plotY1, map(mean+sd, xmin, xmax, plotX1, plotX2),plotY2);
    //sd other
    text(convertForDisplay(mean-sd), map( mean-sd, xmin, xmax, plotX1, plotX2), (plotY1 + plotY2)/2);
    line(map( mean-sd, xmin, xmax, plotX1, plotX2), plotY1, map(mean-sd, xmin, xmax, plotX1, plotX2),plotY2); 
  }

  abstract void drawDataHighlight(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2);
  
    
  String addQuotes(String s) {
    String toReturn = s;
    if(!s.startsWith("\"")) {
      toReturn = "\"" + toReturn;
    }
    if(!s.endsWith("\"")) {
      toReturn = toReturn + "\"";
    }
    return toReturn;
  }
  
  List<List<String>> splitSyndromeFilter(List<String> toSplit){
    List<List<String>> toReturn = new ArrayList<List<String>>();
    List<String> tempList = new ArrayList<String>();
    for(String a: toSplit){
      if(!a.equals("NEXT")){
        tempList.add(a);
      }else{
        toReturn.add(tempList);
        tempList = new ArrayList<String>();
      }
    }
    //println(toReturn.toString());
    return toReturn;
  } 

  String generateQuery(String country, String xAxis_variable, String yAxis_variable) {
    SelectQuery builder = new SelectQuery();
    String quotedCountry = addQuotes(country);
    builder = builder
      .addCustomColumns(new CustomSql( xAxis_variable))
      .addCustomColumns(new CustomSql(yAxis_variable));
      boolean needJoin = deathsOnly;
      String mainTable = quotedCountry;
      
      //work out all tables needed for this query: first, the main table:

      //check for deaths variables      
      //work out joins properly! check x and y for joined variables
      //should also check filters maybe?
      for(String a: morgueColumns){
        if(xAxis_variable.contains(a) || yAxis_variable.contains(a)){
          needJoin = true;
          mainTable = addQuotes(country+"-deaths");
          break;
        }
      }
      
      if(xAxis_variable.equals("SYMPTOM")){
        mainTable = addQuotes(country+"_symptoms");
      }
      
      //now work out joins required
      Set<String> joins = new HashSet<String>();
      for(String a: filters.keySet()){
        for(String b: morgueColumns){
          if(a.contains(b)){
            joins.add(addQuotes(country+"-deaths"));
          }
        }
        for(String b: hospitalColumns){
           //println("xaxis is " + xAxis_variable + " and b is " +b);
            //println("Contains is " + xAxis_variable.contains(b));
          if(a.contains(b)){
            //println("xaxis is " + xAxis_variable + " and b is " +b);
            //println("Contains is " + xAxis_variable.contains(b));
            joins.add(addQuotes(country));
          }
        }
        if(a.equals("SYMPTOM")){
          joins.add(addQuotes(country+"_symptoms"));
        }
      }
      
      //2nd pass for axis variables!
     for(String b: hospitalColumns){
      if(xAxis_variable.contains(b)){
        joins.add(addQuotes(country));
      }
     }
     
     for(String b: morgueColumns){
        if(xAxis_variable.contains(b)){
          joins.add(addQuotes(country+"-deaths"));
       }
     }
     
     
      
      if(deathsOnly){
        joins.add(addQuotes(country+"-deaths"));
      }
      
      joins.remove(mainTable);
      
      //println("Filters set is " + filters.keySet().toString());
      //println("Hospitals columns are " + hospitalColumns.toString());
      //println("Tables to join list is " + joins.toString());
  
  //ALWAYS DO A JOIN FOR FILTERS: maybe optimise later, needs a pass to check for filters that may require a join
   if (joins.isEmpty()){//hospitalColumns.contains(xAxis_variable) && !deathsOnly) {
      //println("Don't need a join!");
      builder = builder
        .addCustomFromTable(mainTable);
    }
    else {
      for(String a: joins){
        //if(!mainTable.equals(a)){
          builder = builder.addCustomJoin(SelectQuery.JoinType.INNER, 
          new CustomSql(mainTable), new CustomSql(a),
          BinaryCondition.equalTo(new CustomSql(mainTable+".PATIENT_ID"), new CustomSql(a+".PATIENT_ID")));
        //}
      }    
    }
  
    //add other conditions
    if(genderFilter != ' ') {
      builder = builder.addCondition(BinaryCondition.equalTo(new CustomSql(quotedCountry + ".GENDER"), new CustomSql(addQuotes(""+genderFilter))));
    }
  
    //eventually in a loop for this
    if(!trim(searchString).equals("") ) {
      String [] tokens = splitTokens(searchString, " ,");
      for(int i = 0 ; i< tokens.length; i++) {
        builder = builder.addCondition(BinaryCondition.like(new CustomSql(quotedCountry + ".SYNDROME"), new CustomSql(addQuotes("%"+tokens[i]+"%"))));
      }
    }
  
    //add filters from other classes!
    for(String a: filters.keySet()){
      //loop and add filters!
      List <String> toFilter = filters.get(a);
      String countryToUse;
      if(morgueColumns.contains(a))
        countryToUse = addQuotes(country+"-deaths");
      else countryToUse = quotedCountry;
      
      if(!a.equals(xAxis_variable)){
        if (a.startsWith("SYMPTOM")){
          
          if(atLeastTwo){
            List<List<String>> splitList = splitSyndromeFilter(toFilter);
            //generate array of ComboConditions, one for each symptom by OR'ing all its options
            List<ComboCondition> allSymptoms = new ArrayList<ComboCondition>();
            ComboCondition oneSyndrome;
            for(List<String> oneList: splitList){
              oneSyndrome = new ComboCondition(ComboCondition.Op.OR);
              //OR each one within the list, AND the result
              for(String b: oneList){
                oneSyndrome = oneSyndrome.addCondition(BinaryCondition.like(new CustomSql(quotedCountry + ".SYNDROME"), new CustomSql(addQuotes("%"+b.toUpperCase()+"%"))));
              }
              allSymptoms.add(oneSyndrome);
            }
            ComboCondition longOr = new ComboCondition(ComboCondition.Op.OR);
            ComboCondition eachAnd = new ComboCondition(ComboCondition.Op.AND);
            //now that we have one array, do all combinations!
            for(int i = 0; i<allSymptoms.size(); i++){
              for(int j = i+1; j<allSymptoms.size(); j++){
                eachAnd = eachAnd.addCondition(allSymptoms.get(i));
                eachAnd = eachAnd.addCondition(allSymptoms.get(j));
                //println(allSymptoms.get(i)+ " and " +allSymptoms.get(j));
                longOr = longOr.addCondition(eachAnd);
                eachAnd = new ComboCondition(ComboCondition.Op.AND);
              }
            }
            println(longOr);
            builder.addCondition(longOr);
          }else if(syndromeOrAnd){
            ComboCondition filterOr = new ComboCondition(ComboCondition.Op.OR);
            ComboCondition nextAnd = new ComboCondition(ComboCondition.Op.AND);
            for(int i = 0; i<toFilter.size(); i++){
              //if(!toFilter.get(i).equals("NEXT")){             
                  filterOr = filterOr.addCondition(BinaryCondition.equalTo(new CustomSql(country+"_symptoms" + ".SYMPTOM"), new CustomSql(addQuotes(toFilter.get(i)))));
              //}else{
                if(syndromeNot){
                   nextAnd = nextAnd.addCondition(new NotCondition(filterOr));
                }else{
                   nextAnd = nextAnd.addCondition(filterOr);
                }
                filterOr = new ComboCondition(ComboCondition.Op.OR); 
              //}
            }
            builder.addCondition(nextAnd);
          }else{
            
            ComboCondition filterOr;                 
            filterOr = new ComboCondition(ComboCondition.Op.OR);//OR
            
            //special syndrome case!
            for(String wordToFilter: toFilter){
                  filterOr = filterOr.addCondition(BinaryCondition.equalTo(new CustomSql(country+"_symptoms"+".SYMPTOM"), new CustomSql(addQuotes(wordToFilter))));
            }
           if(syndromeNot){
              builder.addCondition(new NotCondition(filterOr));
            }else{
              builder.addCondition(filterOr);
            }           
          }
         
          
        }else if(a.startsWith("julianday")){
          //special form for julian days bit!
          String tempA = a.replaceAll("DATE\\)", countryToUse + ".DATE)").replaceAll("DATE_OF_DEATH\\)",addQuotes(country+"-deaths") + ".DATE_OF_DEATH\\)" );// replace appropriate bits
          //println(a.replaceAll("DATE\\)", countryToUse + ".DATE)").replaceAll("DATE_OF_DEATH\\)",addQuotes(country+"-deaths") + ".DATE_OF_DEATH\\)" ));
          builder = builder.addCondition(BinaryCondition.lessThan(new CustomSql(tempA), new CustomSql(""+Math.round(float(toFilter.get(0)))), true));
          builder = builder.addCondition(BinaryCondition.greaterThan(new CustomSql(tempA), new CustomSql(""+ Math.round(float(toFilter.get(1)))), true));
        }else if(a.startsWith("AGE")){
          builder = builder.addCondition(BinaryCondition.lessThan(new CustomSql(countryToUse + "." + a), new CustomSql(addQuotes(""+ Math.round(float(toFilter.get(0))))), true));
          builder = builder.addCondition(BinaryCondition.greaterThan(new CustomSql(countryToUse + "." + a), new CustomSql(addQuotes(""+ Math.round(float(toFilter.get(1))))), true));        
        }else{
          //println("Filters min max size is " + toFilter.size());
          //println("Adding filter " + a + ": " + toFilter.get(0) + ", " + toFilter.get(1));
          builder = builder.addCondition(BinaryCondition.lessThan(new CustomSql(countryToUse + "." + a), new CustomSql(addQuotes(""+ toFilter.get(0))), true));
          builder = builder.addCondition(BinaryCondition.greaterThan(new CustomSql(countryToUse + "." + a), new CustomSql(addQuotes(""+ toFilter.get(1))), true));
        }
      }
      
    }
  
  
    builder = builder.addCustomGroupings( xAxis_variable);
    builder = builder.addCustomOrderings( xAxis_variable);
    String selectQuery = builder.toString();
    //println("SQL builder query is " + selectQuery);
    return selectQuery;
  }
}




