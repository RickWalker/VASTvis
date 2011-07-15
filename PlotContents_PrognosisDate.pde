class PlotContents_PrognosisDate extends PlotContents_Prognosis {

    String prev_deathQuery = "";
    String prev_admissionsQuery = "";
    
    TreeMap<Integer, Integer> invValues;
    TreeMap<Integer, Integer> tempValues;
    DateFormat toShow = new SimpleDateFormat("dd MMM yyyy");
  
  PlotContents_PrognosisDate(String a) {
    super(a);
    
  }
  
  String convertValueToDatabaseFormat(float v) {
    //converts plot value into the format it came out of the database in
    long multiplierToLong = 86400000;
    Date actualDate = new Date((long) (Math.round(v+1) * multiplierToLong)); //+1 because of stupid date rounding errors - fix with Joda eventually
    return toMilli.format(actualDate);
  }
  
  float convertValueFromDatabaseFormat(String s){
    long multiplierToLong = 86400000;
    Date keyDate = new Date();
    try {
      keyDate = toMilli.parse(s);
    }
    catch (ParseException e) {
      println("Can't parse date " + s);
    }
    
    return keyDate.getTime()/multiplierToLong;
  }
  
  String convertForDisplay(float value){
    long multiplierToLong = 86400000;
    Date actualDate = new Date(int(value+1) * multiplierToLong);
    return toShow.format(actualDate);
  }
 
  
}
