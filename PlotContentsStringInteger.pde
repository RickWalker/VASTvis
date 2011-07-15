class PlotContentsStringInteger extends PlotContents {


  //TreeMap<String, Integer> categorisedSymptoms;
  String topTenString = "";  
  int categoriesFound = 0;
  int grandTotal; //grand total amount of symptoms categorised

  PlotContentsStringInteger(String a) {
    super(a);
    values = new TreeMap<String, Integer>();

    //categorisedSymptoms = new TreeMap<String, Integer>();
    // Get list of tokens and symptom filters
    //Set set = symptomFilters.entrySet();

    //Iterator it = set.iterator();

    // Go through symptom filters, create categories in categoried symptoms hash map
    //while(it.hasNext()) {
    //  Map.Entry me = (Map.Entry)it.next();
    //  categorisedSymptoms.put((String)me.getKey(), 0);
   // }
  }
  
  String convertValueToDatabaseFormat(float v){
    return ""; //no filtering on this yet!
  }
  
  float convertValueFromDatabaseFormat(String s){
    return 0;
  }


  void update(String query, String xv, String yv) {
    //determines query string and populates the TreeMap as needed


    int temp_ymax = 0;
    if(!query.equals(previousQuery)) {

      if(queryCache.containsKey(query)){
        getDataFromCache(query);
      }else{
        if(myQuery != null){
          //already querying
          myQuery.cancel();
          }
        myQuery = new QueryThread(parentApp, query, xv, yv);
        needsUpdate = true;
        upToDate.target(20);
      }
      
      previousQuery = query;
    }
    else {
      //println("Using cached String Integer results for " + query);
    }

    if(categoriseSymptoms)
    {
      updateCategorisedMinMax();
    }
    else {
      //update min/max for uncategorised plot
      updateMinMax();
    }

  }

  void draw(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2) {
    //do nothing! Must get drawn elsewhere
  }

  void drawDataHighlight(int xmin, int xmax, int ymin, int ymax,  float plotX1, float plotY1,  float plotX2, float plotY2) {
    //must get drawn elsewhere
  }

  void updateCategorisedMinMax() {
    //assumes symptoms are already categorised
    xmin = 0;
    xmax = values.size();//categorisedSymptoms.keySet().size();//findNumberOfNonZeroCategories();
    ymin = 0;
    ymax = 0;

    String [] a = (String []) values.keySet().toArray(new String [values.keySet().size()]);
    int toCheck;
    for (int i = 0 ; i < a.length; i++) {
      toCheck = (Integer)values.get(a[i]);
      ymin = min (ymin, toCheck);
      ymax = max (ymax, toCheck); //this only works for categorised
    }
     
    if(values.isEmpty()){
        xmin = ymin = Integer.MAX_VALUE;
        xmax = ymax = Integer.MIN_VALUE;
    }else if(showPercentages){
      println("Actual ymax = " + ymax + " and totalValues is " + totalValues);
      ymax = ceil(ymax/float(totalValues) * 100);
      println("YMAX is " + ymax);
      ymin = 0;
    }
  }

  void updateMinMax() {
    xmin = 0;
    xmax = 11; 
    ymin = 0;
    ymax = 0;
    String [] a = (String []) values.keySet().toArray(new String [values.keySet().size()]);
    //now just get the highest in this array!
    int toCheck;
    for (int i = 0 ; i < a.length; i++) {
      toCheck = (Integer) values.get(a[i]);
      ymin = min (ymin, toCheck);
      ymax = max (ymax, toCheck); //this only works for non-categorised
    }
    
    if(values.isEmpty()){
        xmin = ymin = Integer.MAX_VALUE;
        xmax = ymax = Integer.MIN_VALUE;
    }else if(showPercentages){
      ymax = 100;
      ymin = 0;
    }
  }

  TreeSet getSortedSet(TreeMap toSort){
  
      //This lovely piece of code will sort the treemap by value rather than key
      TreeSet set = new TreeSet(new Comparator() {
        public int compare(Object obj, Object obj1) {
          return ((Comparable) ((Map.Entry) obj1).getValue()).compareTo(((Map.Entry) obj).getValue());
        }
      }
      );

      //Plot the categorised data!
      set.addAll(toSort.entrySet());
      return set;
  }

  int findNumberOfNonZeroCategories()
  {
    int count = 0;
    Set set = values.entrySet();
    Iterator i = set.iterator();

    while(i.hasNext()) {       
      Map.Entry me = (Map.Entry)i.next();

      if((Integer)me.getValue() > 0)
        count++;
    }  

    return count+1;
  }
  
  void updateStats(){
    //do nothing for now
  }
  
  
  
}

