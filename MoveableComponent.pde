public interface MoveableComponent{
  public void moveTo(int a, int b, int c, int d);
  public float getWidthTarget();
  public int getX();
  public int getY();
  public int getWidth();
  public int getHeight();
  public void draw();
  public GenericPlot getReference();
}
