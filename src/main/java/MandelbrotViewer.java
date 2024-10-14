import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.awt.image.BufferedImage;

public class MandelbrotViewer extends JPanel implements MouseListener, MouseMotionListener, MouseWheelListener {
    private int[] pixels;  // Stores the Mandelbrot image pixel data
    private BufferedImage image;
    private int width, height;
    private double centerReal = -0.75, centerImag = 0.0;  // Default center
    private double zoom = 1.0;  // Default zoom level
    private int maxIter = 1000;  // Default max iterations

    private int lastX, lastY;  // For tracking mouse drag
    private boolean dragging = false;
    private Mandelbrot mandelbrot;

    public MandelbrotViewer(int width, int height) {
        this.width = width;
        this.height = height;
        this.pixels = new int[width * height];
        this.image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
        this.mandelbrot = new Mandelbrot();
        addMouseListener(this);
        addMouseMotionListener(this);
        addMouseWheelListener(this);
        this.setDoubleBuffered(false);

        renderMandelbrot();  // Initial render
    }

    // Renders the Mandelbrot set using CUDA and updates the image
    private void renderMandelbrot() {
        mandelbrot.runMandelbrotWithColor(pixels, width, height, maxIter, centerReal, centerImag, zoom);
        image.setRGB(0, 0, width, height, pixels, 0, width);
        repaint();
    }


    // Handles panning logic
    @Override
    public void mousePressed(MouseEvent e) {
        lastX = e.getX();
        lastY = e.getY();
        dragging = true;
    }

    @Override
    public void mouseReleased(MouseEvent e) {
        dragging = false;
    }

    @Override
    public void mouseDragged(MouseEvent e) {
        if (dragging) {
            int deltaX = e.getX() - lastX;
            int deltaY = e.getY() - lastY;

            // Calculate aspect ratio
            double aspectRatio = (double) width / height;

            // Scale the movements correctly based on zoom and aspect ratio
            centerReal -= deltaX * (3.5 / zoom) / width;
            centerImag -= deltaY * (2.0 / zoom) / height / aspectRatio;

            lastX = e.getX();
            lastY = e.getY();
            renderMandelbrot();
        }
    }


    // Handles zooming with mouse wheel
    @Override
    public void mouseWheelMoved(MouseWheelEvent e) {
        int notches = e.getWheelRotation();
        if (notches < 0) {
            zoom *= 1.1f;  // Zoom in
        } else {
            zoom /= 1.1f;  // Zoom out
        }
        renderMandelbrot();
    }

    @Override
    public void paint(Graphics g) {
        g.drawImage(image, 0, 0, null);
    }

    // Unused event handlers
    @Override
    public void mouseMoved(MouseEvent e) {
    }

    @Override
    public void mouseClicked(MouseEvent e) {
    }

    @Override
    public void mouseEntered(MouseEvent e) {
    }

    @Override
    public void mouseExited(MouseEvent e) {
    }

    // Main method to create the JFrame and display the Mandelbrot viewer
    public static void main(String[] args) {
        JFrame frame = new JFrame("Mandelbrot Viewer");
        MandelbrotViewer viewer = new MandelbrotViewer(800, 600);
        frame.add(viewer);
        frame.setSize(800, 600);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setVisible(true);
    }
}

