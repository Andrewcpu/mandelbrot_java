public class Mandelbrot {
    static {
        try {
            // Get the full path to the native library
            String libPath = Mandelbrot.class.getClassLoader()
                    .getResource("libs/mandelbrot.dll").getPath();
            System.load(libPath);
        } catch (Exception e) {
            e.printStackTrace();
            throw new UnsatisfiedLinkError("Failed to load native library.");
        }
    }
    public native void runMandelbrotWithColor(int[] image, int width, int height, int maxIter,
                                     double centerReal, double centerImag, double zoom);


}
