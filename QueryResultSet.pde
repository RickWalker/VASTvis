class QueryResultSet{
  //eventually, use this everywhere instead of two caches!
  Map data;
  String query;
  float xmax, xmin;
  float ymax, ymin;
  int rowCount;
  int matchCount;
  DescriptiveStatistics plotStats;
  String xv, yv;
  float mean, median, q1, q3, sd, skewness, kurtosis;
  float tenthpercentile, ninetiethpercentile;
  
  QueryResultSet(){
    plotStats = new DescriptiveStatistics();
  }
  
  void updateStats(){
    mean = (float) plotStats.getMean();
    median = (float)plotStats.apply(new Median());
    q1 = (float)plotStats.getPercentile(25);
    q3 = (float)plotStats.getPercentile(75);
    sd = (float)plotStats.getStandardDeviation();
    skewness = (float)plotStats.getSkewness();
    kurtosis = (float)plotStats.getKurtosis();
    //harder: work out whisker top and bottom!
    tenthpercentile = (float) plotStats.getPercentile(10);
    ninetiethpercentile = (float) plotStats.getPercentile(90);
  }
}
