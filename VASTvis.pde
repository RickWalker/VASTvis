//This software makes use of the following libraries:
//Apache Commons Math http://commons.apache.org/math/
//which is licensed under the Apache Software License, Version 2.0
//http://commons.apache.org/math/license.html

//SQLBuilder http://openhms.sourceforge.net/sqlbuilder/
//which is licensed under the GNU Lesser General Public License, 2.1
//http://openhms.sourceforge.net/sqlbuilder/license.html

//SQLite4Java http://code.google.com/p/sqlite4java/
//licensed under Apache License 2.0

//Ben Fry's Integrator class is from his book "Visualizing Data"

//The remainder of code is written by Llyr ap Cenydd and Rick Walker
//and licensed under the Creative Commons GNU GPL
//http://creativecommons.org/licenses/GPL/2.0/

import processing.pdf.*;
import java.util.concurrent.*;
import com.healthmarketscience.*;
// GUI
import controlP5.*;
import java.util.HashSet;

ControlP5 controlP5;

//to lookup country names

HashMap<String, String> countryMap;

static final int startDate = 14349; //2009-04-16
static final int endDate = 14423; //2009-06-29 --- is it now?
static final int startAge = 0;
static final int endAge = 85;

//to look up city names
HashMap<String, String> cityMap;

Set<String> hospitalColumns;
Set<String> morgueColumns;

Set<String> keySymptoms;

Map <String, List<String>> filters; //can convert everything to string!
Map <String, List<String>> filterForUndo;

Map<String, QueryResultSet> queryCache;

LayoutManager largeSmall;

boolean normalise;

// ********* For SQL access ********* 

//SQLite db; 
// database databaseQuery
//DatabaseQuery databaseQuery;

// ********* GUI objects ********* 

String textValue = "";
Textfield myTextfield;
Textlabel symptomsTextlabel;
Textarea symptomsTopTenList;

//buttons
controlP5.Button button_DeathsOnly;
controlP5.Button button_showQuartiles;
controlP5.Button button_mean;
controlP5.Button button_smoothed;
controlP5.Button button_showPercentages;
controlP5.Button button_syndromeOrAnd;
controlP5.Button button_syndromeNot;
controlP5.Button button_Gender_Both;
controlP5.Button button_Gender_Males;
controlP5.Button button_Gender_Females;
controlP5.Button normaliseCountButton;
controlP5.Button twoOrMoreButton;
// ********* Globals ********* 


//DataPlot plot;// = new DataPlot("blank");    //data plot object
//DatePlot plot2;
List <GenericPlot> plotList;// testPlot, testPlot2;
svgMapInterface theMap;

//filters
static char genderFilter = ' ';
static String searchString = "";
static boolean deathsOnly = false;
static boolean showStats = false;
static boolean showMean = false;
static boolean smoothed = false;
static boolean invertSelection = false;
static boolean showPercentages = false;
static boolean pandemicSymptoms = false;
static boolean syndromeOrAnd = false; //false is Or, true is And
static boolean syndromeNot = false; //NOT the selected symptoms
static boolean atLeastTwo = false;
static boolean categoriseSymptoms = true;

PApplet parentApp;

ExecutorService e;

 HashMap<String, List<String>> symptomFilters;

DateFormat toMilli = new SimpleDateFormat("yyyy-MM-dd");

// ********* Setup (runs once) ********* 

void setup() {
  size(screenWidth, screenHeight);
  parentApp = this;
  largeSmall = new LayoutManager(width, height);
  smooth();
  textMode(SHAPE);

  //eventually, get column names from database?
  hospitalColumns = new HashSet<String>();
  morgueColumns = new HashSet<String>();
  
  filters = new HashMap<String, List<String> >();
  filterForUndo  = new HashMap<String, List<String> >();

  //setup country names
  countryMap = new HashMap<String, String>(); //lookup city name from country name 
  cityMap = new HashMap<String, String>(); //lookup country name from city name abbreviation
  
   
  setupSymptomFilters();

  String [][] countries = {
    {
      "Thailand","Nonthaburi"
    }
    , {
      "Saudi_Arabia","Jedda"
    }
    , {
      "Venezuela", "Barcelona"
    }
    , {
      "Iran","Tabriz"
    }
    , {
      "Lebanon", "Beirut"
    }
    , { 
      "Pakistan","Karachi"
    }
    , {
      "Kenya", "Nairobi"
    }
    , {
      "Syria", "Aleppo"
    }
    , {
      "Turkey", "Mersin"
    }
    , {
      "Yemen", "Aden"
    }
    , {
      "Colombia", "Tolima"
    }
  };
  for(int i = 0 ; i < countries.length; i++) {
    countryMap.put(countries[i][0], countries[i][1]);
  }
  
  for(String [] a: countries){
  cityMap.put(a[1], a[0]);
  //println("maps " + a[1] + " to " + a[0]);
  }

  hospitalColumns = new HashSet();
  hospitalColumns.add("DATE");
  hospitalColumns.add("GENDER");
  hospitalColumns.add("PATIENT_ID");
  hospitalColumns.add("AGE");
  hospitalColumns.add("SYNDROME");
  
  keySymptoms = new HashSet<String>();
  keySymptoms.add("Abdominal Pain");
  keySymptoms.add("Back Pain");
  keySymptoms.add("Diarrhoea");
  keySymptoms.add("Fever");
  keySymptoms.add("Bleeding Nose");
  keySymptoms.add("Vomitting");
  keySymptoms.add("Headache");
  keySymptoms.add("Rash");
  keySymptoms.add("Vision Problems");

  morgueColumns = new HashSet();
  morgueColumns.add("DATE_OF_DEATH");
  morgueColumns.add("ID");
  // Setup GUI
  controlP5 = new ControlP5(this);
  int textFieldPosition_x = width/3;
  int textFieldPosition_y = 2*height/3 + 75;
  int offset = textFieldPosition_x;

  myTextfield = controlP5.addTextfield("change_symptoms",textFieldPosition_x, textFieldPosition_y, 250,20);
  myTextfield.setFocus(true);
  myTextfield.setAutoClear(false);
  myTextfield.setColorBackground(200);
  myTextfield.setColorForeground(150);
  myTextfield.setColorValue(200);
  myTextfield.setColorActive(50);
  myTextfield.setColorLabel(0);

  symptomsTextlabel = controlP5.addTextlabel("label","Symptoms : Everything",textFieldPosition_x,textFieldPosition_y + 50);
  symptomsTextlabel.setColorValue(0);

  //add buttons!
  button_DeathsOnly = controlP5.addButton("button_DeathsOnlyValue",128,offset,textFieldPosition_y + 80,60,19);
  button_DeathsOnly.setColorBackground(100);
  button_DeathsOnly.setLabel("Deaths only");
  offset += 70;

  button_showQuartiles = controlP5.addButton("button_showQuartilesValue",128,offset,textFieldPosition_y + 80,75,19);
  button_showQuartiles.setColorBackground(100);
  button_showQuartiles.setLabel("Show quartiles"); 
  
  offset += 85;
  
  normaliseCountButton = controlP5.addButton("normaliseCountButton",0,offset, textFieldPosition_y + 80,85,19);
  normaliseCountButton.setColorBackground(100);
  normaliseCountButton.setLabel("Normalise results");  
  
  offset = textFieldPosition_x; 

  button_Gender_Males = controlP5.addButton("button_Gender_MaleValue",1,offset,textFieldPosition_y + 105,32,19);
  button_Gender_Males.setColorBackground(100);
  button_Gender_Males.setLabel("Males");  
  offset += 40;

  button_Gender_Females = controlP5.addButton("button_Gender_FemaleValue",2,offset,textFieldPosition_y + 105,44,19);
  button_Gender_Females.setColorBackground(#5679C1);
  button_Gender_Females.setLabel("Females");  
  offset += 52;

  button_Gender_Both = controlP5.addButton("button_Gender_BothValue",0,offset, textFieldPosition_y + 105,27,19);
  button_Gender_Both.setColorBackground(100);
  button_Gender_Both.setLabel("Both");
  offset +=37;  
  
  twoOrMoreButton = controlP5.addButton("button_twoOrMoreValue",0,offset, textFieldPosition_y +105,50, 19);
  twoOrMoreButton.setColorBackground(100);
  twoOrMoreButton.setLabel("Two plus");  
  offset +=60;
  
  button_syndromeOrAnd = controlP5.addButton("button_syndromeOrAndValue",0, offset, textFieldPosition_y + 105,22,19);
  button_syndromeOrAnd.setColorBackground(100);
  button_syndromeOrAnd.setLabel("And");
  offset += 68;
  
  offset = textFieldPosition_x;
  
  button_mean = controlP5.addButton("button_meanValue",0, offset, textFieldPosition_y + 130,58,19);
  button_mean.setColorBackground(100);
  button_mean.setLabel("Show Mean");
  offset += 68;
  
  button_smoothed = controlP5.addButton("button_smoothedValue",0, offset, textFieldPosition_y + 130,48,19);
  button_smoothed.setColorBackground(100);
  button_smoothed.setLabel("Smoothed");
  offset += 58;
  
  button_showPercentages = controlP5.addButton("button_showPercentagesValue",0, offset, textFieldPosition_y + 130,62,19);
  button_showPercentages.setColorBackground(100);
  button_showPercentages.setLabel("Percentages");
  offset += 72;
  
  button_syndromeNot = controlP5.addButton("button_syndromeNotValue",0, offset, textFieldPosition_y + 130,22,19);
  button_syndromeNot.setColorBackground(100);
  button_syndromeNot.setLabel("Not");
  offset += 68;
  
  // Create an SQL connection, run databaseQuery 
  //db = new SQLite( this, "VAST-challenge");//pandemic.sqlite" );  // open database file
  //databaseQuery = new DatabaseQuery();  //pass database connection to query object when creating

  theMap = new svgMapInterface(this, width/7, height/7, int(1.5/5.0 * width), height/4);
  largeSmall.addMap(theMap);

  plotList = new ArrayList<GenericPlot>();
  largeSmall.addComponent(new GenericPlotNumber(this, "DATE", "COUNT(1)", "Date of admission", "Number of\npatients"));
  largeSmall.addComponent(new GenericPlotNumber(this, "AGE", "COUNT(1)", "Age", "Number of\npatients"));
  largeSmall.addComponent(new GenericPlotNumber(this, "DATE", "COUNT(1)", "Date of admission", "Cumulative\nnumber of\npatients"));
  largeSmall.addComponent(new GenericPlotNumber(this, "julianday(DATE_OF_DEATH)-julianday(DATE)", "COUNT(1)", "Days to death", "Number of\npatients"));

  //largeSmall.addComponent(new GenericPlotNumber(this, "DATE", "AVG(julianday(DATE_OF_DEATH)-julianday(DATE))", "Date of Admission", "Time to death\n(days)"));
  largeSmall.addComponent(new GenericPlotNumber(this, "DATE", "COUNT(1)", "Date of admission", "Percentage\n that die"));
  //largeSmall.addComponent(new GenericPlotNumber(this, "AGE", "COUNT(1)", "Age", "Percentage\n that die"));
  largeSmall.addComponent(new GenericPlotString(this, "SYMPTOM", "COUNT(1)", "Syndrome", "Number of\npatients"));


  largeSmall.addComponent(new GenericPlotStats(this, "STATS", "", "", ""));

  symptomsTopTenList = controlP5.addTextarea("label","", int(width/1.3), textFieldPosition_y, 200 ,120 );
  symptomsTopTenList.setColorValue(0);
  
  queryCache = new HashMap<String, QueryResultSet>();
  e = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());

  updateGenderFilter(' ');
  frameRate(30);

  //textMode(SCREEN);
}

// ********* Draw ********* 

void draw() {
  background(224);

  for(GenericPlot a: plotList) a.draw();
  theMap.draw();
  
  controlP5.draw();
}

// ********* Events ********* 

void mousePressed() {
  for(GenericPlot a: plotList)
    if(a.mouseOver()) {
      if (mouseEvent.getClickCount()==2){ 
        largeSmall.doubleClick(a);
      }
      else{
        a.mousePressed();
      }
    };

  if(theMap.mouseOver()) {
    if(mouseEvent.getClickCount() == 2){
      largeSmall.doubleClick(theMap);
    }else{     
      theMap.mousePressed();
    }
  }
}

void mouseMoved() {
  for(GenericPlot a: plotList)
  if(a.mouseOver()) a.mouseMoved();
}

void mouseReleased() {
  
  for(GenericPlot a: plotList)
    if(a.mouseOver()) {
      a.mouseReleased();
      refreshFilters();
    }
  loop();
}

void mouseDragged(){
   for(GenericPlot a: plotList)
    if(a.mouseOver())
      a.mouseDragged();
}

void keyPressed(){
  if(key == 'r'){
    beginRecord(PDF, "output.pdf");
    background(224);
    //println("Moving " + largeSmall.large.x + ", " +  largeSmall.large.y);
    //translate(-largeSmall.large.x, -largeSmall.large.y);
    //translate(-500, -500);
    //MoveableComponent a;
    //if((a = largeSmall.getLargeComponent()) != null)
    //  a.draw();
    draw();
    endRecord();
  }else if (key == 'z'){
    println("Undo");
    Map <String, List<String>> tempMap = new HashMap<String, List<String>>();
    tempMap.putAll(filters);
    println("temp filter store is " + tempMap.toString());
    filters.clear();
    filters.putAll(filterForUndo);
    filterForUndo.clear();
    filterForUndo.putAll(tempMap);
    println("After undo, filters is " + filters.toString());
    println("And undo is " + filterForUndo.toString());
    for(GenericPlot a: plotList) a.refresh();
  }else if (key == 'i'){
    //invert selection on syndrome plot
    invertSelection = true;
    for(GenericPlot a: plotList) a.refresh();
  }else if (key == 'p'){
    pandemicSymptoms = !pandemicSymptoms;
    for(GenericPlot a: plotList) a.refresh();
    refreshFilters();
    for(GenericPlot a: plotList) a.refresh();
  }else if (key == 'c'){
   theMap.setAllRequiredCountries();
  }else if (key == 'b'){
    theMap.selectedCountries.clear();
    updateCountry(theMap.selectedCountries);
  }else if (key == 'm'){
    largeSmall.hideAllButLarge();
  }else if (key == 'n'){
    largeSmall.restoreAll();
  }
}
  


void updateCountry(Set selectedCountries) {

  //update countries in plot and redraw if necessary
    refreshFilters();
    Date start = new Date();
    for(GenericPlot a: plotList) a.updateContents(selectedCountries);
    Date end = new Date();
  
  println("Whole update time was " + (end.getTime() - start.getTime()) + "ms");
}

void removeFilter(String s){
  for(GenericPlot a: plotList){
    if(a.xAxis_variable.equals(s)){
      a.minValue = a.maxValue = -1;// flag it as not-active, but don't remove it or it breaks undo
    }
  }
  println("Removing filter " + s);
  //filterForUndo.putAll(filters);
  //filters.remove(s);*/
}

void refreshFilters(){
  //update the filter list!
  //filters.clear();
  //List<String> tempList;

/*println("Start of refresh filters\n**********************\n");
for(String a: filters.keySet()){
  println(filters.get(a).toString());
}
println("******************************\n");*/
  
  
  Map<String, List<String>> newFilters = new HashMap<String, List<String>>();
  
  for(GenericPlot a: plotList){
    Map <String, List<String>> filterToAdd = a.getFilter();
    if(! filterToAdd.isEmpty()){
      newFilters.putAll(filterToAdd);
      //println(filterToAdd);
    }
  }
  
  //now compare newFilters to filters
  for(String a: newFilters.keySet()){
    println("New\n" + newFilters.get(a));
    println("Old\n" + filters.get(a));
    if(null==filters.get(a) ){//&& !a.equals("SYNDROME")){
      //println("Added filter " + newFilters.get(a).toString());
      filterForUndo.clear();
      filterForUndo.putAll(filters);
      //filterForUndo.put(a, ilters.get(a));
    }else{
      //check for same contents
      if(!filters.get(a).equals(newFilters.get(a))  && !a.equals("SYNDROME")){
        filterForUndo.clear();
        filterForUndo.putAll(filters);
        //println("Filter changed from " + filters.get(a) + " to " + newFilters.get(a));
      }
    }
  }
  //println("\nChecking for removal");
  for(String b: filters.keySet()){
    if(null==newFilters.get(b)  && !b.equals("SYNDROME")){
      //println("Removed filter " + filters.get(b).toString());
      filterForUndo.clear();
      filterForUndo.putAll(filters);//(b, filters.get(b));
    }
  }
  
  filters.clear();
  filters.putAll(newFilters);
  
  //println("\nFinal filters is \n" + filters.toString() + "\n");
  
  //println("\nFinal undo filters is \n" + filterForUndo.toString() + "\n");
  
  //now refresh all plots!
  Date start = new Date();
  for(GenericPlot a: plotList) a.refresh();
  Date end = new Date();
  //println("Refresh update time was " + (end.getTime() - start.getTime()) + "ms");
}

// ********* Change_symptoms runs every time new input is entered ********* 

public void change_symptoms(String theText) {

  searchString = theText;  // save input text

    // update text label
    for(GenericPlot a: plotList) a.refresh();
  //symptomsTextlabel.setValue("Symptoms : " + theText + "        Results : " + databaseQuery.getMatchCount() + " / " + databaseQuery.getRowCount());
  //symptomsTextlabel.update();
}



// ********* Button Events ********* 


public void button_twoOrMoreValue(int theValue) {
  //databaseQuery.b_deathsOnly = !databaseQuery.b_deathsOnly;
  //categoriseSymptoms = !categoriseSymptoms;
  
  atLeastTwo = !atLeastTwo;

  if(atLeastTwo) {
    twoOrMoreButton.setColorBackground(#5679C1);
  }
  else {
    twoOrMoreButton.setColorBackground(100);
  }

  for(GenericPlot a: plotList) a.refresh();
}

public void button_DeathsOnlyValue(int theValue) {
  //databaseQuery.b_deathsOnly = !databaseQuery.b_deathsOnly;
  deathsOnly = !deathsOnly;

  if(deathsOnly) {
    button_DeathsOnly.setColorBackground(#5679C1);
  }
  else {
    button_DeathsOnly.setColorBackground(100);
  }

  for(GenericPlot a: plotList) a.refresh();
  //change_symptoms(searchString);  //call this so that the results text is updated
}

public void normaliseCountButton(int v){
  normalise = ! normalise;
  
  if(normalise) {
    normaliseCountButton.setColorBackground(#5679C1);
  }
  else {
   normaliseCountButton.setColorBackground(100);
  }
   for(GenericPlot a: plotList) a.refresh();
}

void updateGenderFilter(char choice)
{
  genderFilter = choice;
  if(choice == ' ')
  {
    button_Gender_Both.setColorBackground(#5679C1);
    button_Gender_Males.setColorBackground(100);
    button_Gender_Females.setColorBackground(100);
  }
  else if(choice == 'M') {
    button_Gender_Both.setColorBackground(100);
    button_Gender_Males.setColorBackground(#5679C1);
    button_Gender_Females.setColorBackground(100);
  }  
  else if(choice == 'F') {
    button_Gender_Both.setColorBackground(100);
    button_Gender_Males.setColorBackground(100);
    button_Gender_Females.setColorBackground(#5679C1);
  }   
  for(GenericPlot a: plotList) a.refresh();
}

public void button_showQuartilesValue(int theValue) {

  showStats = !showStats;
  
  if(showStats) {
    button_showQuartiles.setColorBackground(#5679C1);
  }
  else {
   button_showQuartiles.setColorBackground(100);
  }
}

public void button_meanValue(int theValue) {

  showMean = !showMean;
  
  if(showMean) {
    button_mean.setColorBackground(#5679C1);
  }
  else {
   button_mean.setColorBackground(100);
  }
}

public void button_smoothedValue(int theValue) {

  smoothed = !smoothed;
  
  if(smoothed) {
    button_smoothed.setColorBackground(#5679C1);
  }
  else {
   button_smoothed.setColorBackground(100);
  }
}

public void button_syndromeOrAndValue(int theValue) {

  syndromeOrAnd = !  syndromeOrAnd;
  
  if(  syndromeOrAnd) {
    button_syndromeOrAnd.setColorBackground(#5679C1);
  }
  else {
   button_syndromeOrAnd.setColorBackground(100);
  }
  for(GenericPlot a: plotList) a.refresh();
}

public void button_syndromeNotValue(int theValue) {

  syndromeNot = !syndromeNot;
  
  if(syndromeNot) {
    button_syndromeNot.setColorBackground(#5679C1);
  }
  else {
   button_syndromeNot.setColorBackground(100);
  }
  for(GenericPlot a: plotList) a.refresh();
}

public void button_showPercentagesValue(int theValue){
  showPercentages = !showPercentages;
  if(showPercentages) {
    button_showPercentages.setColorBackground(#5679C1);
  }
  else {
   button_showPercentages.setColorBackground(100);
  }
  for(GenericPlot a: plotList) a.refresh();
}


public void button_Gender_BothValue(int theValue) {
  updateGenderFilter(' ');
}

public void button_Gender_MaleValue(int theValue) {
  updateGenderFilter('M');
}

public void button_Gender_FemaleValue(int theValue) {
  updateGenderFilter('F');
}

void setupSymptomFilters(){
   symptomFilters = new HashMap<String, List<String>>();
  symptomFilters.put("Bleeding Nose", Arrays.asList("Bleeding Nose", "Nose Bleed", "NoseBleed", "Bloody Nose", "Nose"));
    symptomFilters.put("Nausea", Arrays.asList("Nausea"));
    symptomFilters.put("Vomitting", Arrays.asList("Vomit", "Vomting"));
    symptomFilters.put("Vomitting Blood", Arrays.asList("Vomit Blood", "Vomitting Blood", "Vomiting Blood", "Blood in Vomit"));
    symptomFilters.put("Diarrhoea", Arrays.asList("Diarr"));
    symptomFilters.put("Bloodwork", Arrays.asList("Abnormal Labs"));  // is this even right?
    symptomFilters.put("Head Swelling", Arrays.asList("Head-Face-Neck Swelling", "Head Swelling", "Face Swollen", "Head Swollen", "facial swelling"));
    symptomFilters.put("Back Pain", Arrays.asList("Back Pain", "lumbago", "lumbar", "Back p", "Back inj", "Back strain" ));//Back Pain", "Back Hurts", "Back Strain"));
    symptomFilters.put("Neck Pain", Arrays.asList("Neck"));
    symptomFilters.put("Stomach Pain", Arrays.asList("Stomach"));
    symptomFilters.put("Vision Problems", Arrays.asList("Vision", "Conjunctiv", "pink eye", "Visual", "eye pain", "eye problem", "eye redness", "eye swelling"));
    symptomFilters.put("Hearing Problems", Arrays.asList("Hearing"));
    symptomFilters.put("Abdominal Pain", Arrays.asList("Abd", "Ab pain"));
    symptomFilters.put("Back Spasms", Arrays.asList("Back Spasm"));
    symptomFilters.put("Headache", Arrays.asList("Headache", "Head Ache", "migrain", "migrane"));
    symptomFilters.put("Rash", Arrays.asList("Rash"));
    symptomFilters.put("Tremors", Arrays.asList("Tremor"));
    symptomFilters.put("Coughing", Arrays.asList("Cough"));
    symptomFilters.put("Leg Problems", Arrays.asList("Leg"));
    symptomFilters.put("Proteinuria", Arrays.asList("Proteinuria"));
    symptomFilters.put("Encephalitis", Arrays.asList("Encephalitis"));
    symptomFilters.put("Sinus", Arrays.asList("Sinus"));
    symptomFilters.put("Congestion", Arrays.asList("Congest"));
    symptomFilters.put("Cramping", Arrays.asList("Cramp"));
    symptomFilters.put("Coughing Blood", Arrays.asList("Coughing Blood"));
    symptomFilters.put("Dizziness", Arrays.asList("Dizziness", "Dizzy"));
    symptomFilters.put("Lethargy", Arrays.asList("Weak", "Lethargy", "Lethargic", "Fatigue"));
    symptomFilters.put("Temperature", Arrays.asList("Temp"));
    symptomFilters.put("Earache", Arrays.asList("Ear Ache", "Earache", "ear pain", "ear symptoms", "ear infection"));
    symptomFilters.put("Mental", Arrays.asList("Mental", "Confusion", "neuro", "Speech", "Halluc", "Confused", "conciousness", "memory", "diff speaking", "difficulty speaking", "acting"));
    symptomFilters.put("Foot problem", Arrays.asList("Foot"));
    symptomFilters.put("Appetite", Arrays.asList("Appet"));
    symptomFilters.put("Fever", Arrays.asList("Fever"));
    symptomFilters.put("Chest Pain", Arrays.asList("Chest"));
    symptomFilters.put("Animal Bite", Arrays.asList("Bite"));
    symptomFilters.put("Anxiety", Arrays.asList("Anxiety"));
    symptomFilters.put("Asthma", Arrays.asList("Asthma"));
    symptomFilters.put("Swollen Feet", Arrays.asList("Feet Swollen", "Swollen Feet", "Foot Swollen", "Swollen Foot", "Feet Swelling"));
    symptomFilters.put("Blood in Waste", Arrays.asList("Blood in Stool", "Blood in urine", "Bloody stool", "Bloody urine", "passing blood", "Black stools"));
    symptomFilters.put("Breathing problems", Arrays.asList("Breathing", "Bronchitis", "respiration", "Respiratory", "shortness", "Wheez", "shortness"));
    symptomFilters.put("Cardiac Arrest", Arrays.asList("Cardiac"));
    symptomFilters.put("Difficulty Swallowing", Arrays.asList("Swallowing"));
    symptomFilters.put("Flu/Cold Symptoms", Arrays.asList("Cold", "Flu"));
    symptomFilters.put("Urinating problems", Arrays.asList("Diff Urinating", "Difficulty Urinating", "trouble urinating", "unable to urinate", "urinary Difficult", "urinary problems", "cant urinate", "urinating blood"));
    symptomFilters.put("Blood Pressure", Arrays.asList("Blood Pressure", "BP"));
    symptomFilters.put("Extremity Pain wo injury", Arrays.asList("EXT PAIN", "Extremity pain", "Extremity problems"));
    symptomFilters.put("Orifice Bleeding", Arrays.asList("Vaginal Bleeding", "Vag Bleed", "Rectal Bleed", "Rectal Bleeding", "Vag. Bleed", "GI Bleed",
                                                         "Vag. Bleeding", "vaginal Bleed", "Bleeding from rectum", "bleeding from ear", "Ear bleeding", "Bleeding from rectum", "bleeding from penis"));
    symptomFilters.put("Pregnant", Arrays.asList("Pregnant", "Pregnancy"));
    symptomFilters.put("Seizure", Arrays.asList("Siezure", "Seizure"));
    symptomFilters.put("Shaking", Arrays.asList("Shaking", "shakey"));
    symptomFilters.put("Hypertension", Arrays.asList("Hypertension"));
    symptomFilters.put("Hypotension", Arrays.asList("Hypotension"));
    symptomFilters.put("Hyperglycemia", Arrays.asList("Hyperglycemia"));
    symptomFilters.put("Hypoglycemia", Arrays.asList("Hypoglycemia"));
    symptomFilters.put("Not Eating", Arrays.asList("Not eating", "not drinking"));
    symptomFilters.put("Renal failure", Arrays.asList("Renal failure"));
}

