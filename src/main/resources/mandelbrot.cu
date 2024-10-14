#include <jni.h>
#include <cuda_runtime.h>
#include <math.h>
__global__ void mandelbrot(int *image, int width, int height, int max_iter,
                           double center_real, double center_imag, double zoom) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) return;

    double aspect_ratio = (double)width / height;

    double real = ((x - width / 2.0) / (width * zoom)) * aspect_ratio + center_real;
    double imag = ((y - height / 2.0) / (height * zoom)) + center_imag;

    double zx = 0.0, zy = 0.0;
    int iteration = 0;

    while (zx * zx + zy * zy <= 4.0 && iteration < max_iter) {
        double temp = zx * zx - zy * zy + real;
        zy = 2.0 * zx * zy + imag;
        zx = temp;
        iteration++;
    }

    image[y * width + x] = iteration;
}

__global__ void mandelbrotWithColor(int *image, int width, int height, int max_iter,
                                    double center_real, double center_imag, double zoom) {
    int x = blockIdx.x * blockDim.x + threadIdx.x;
    int y = blockIdx.y * blockDim.y + threadIdx.y;

    if (x >= width || y >= height) return;

    double aspect_ratio = (double)width / height;

    double real = ((x - width / 2.0) / (width * zoom)) * aspect_ratio + center_real;
    double imag = ((y - height / 2.0) / (height * zoom)) + center_imag;

    double zx = 0.0, zy = 0.0;
    int iteration = 0;
    while (zx * zx + zy * zy <= 4.0 && iteration < max_iter) {
        double temp = zx * zx - zy * zy + real;
        zy = 2.0 * zx * zy + imag;
        zx = temp;
        iteration++;
    }

    float hue = (float)(iteration % 256) / 255.0f;
    float saturation = 1.0f;
    float brightness = (iteration < max_iter) ? 1.0f : 0.0f;

    int i = (int)(hue * 6.0f);
    float f = (hue * 6.0f) - i;
    float p = brightness * (1.0f - saturation);
    float q = brightness * (1.0f - f * saturation);
    float t = brightness * (1.0f - (1.0f - f) * saturation);

    float r, g, b;
    switch (i % 6) {
        case 0: r = brightness; g = t; b = p; break;
        case 1: r = q; g = brightness; b = p; break;
        case 2: r = p; g = brightness; b = t; break;
        case 3: r = p; g = q; b = brightness; break;
        case 4: r = t; g = p; b = brightness; break;
        case 5: r = brightness; g = p; b = q; break;
    }

    int color = ((int)(r * 255) << 16) | ((int)(g * 255) << 8) | (int)(b * 255);

    image[y * width + x] = color;
}


extern "C" {
    JNIEXPORT void JNICALL Java_Mandelbrot_runMandelbrot(JNIEnv *env, jobject obj,
                                                     jintArray image, jint width,
                                                     jint height, jint maxIter,
                                                     jdouble centerReal, jdouble centerImag,
                                                     jdouble zoom) {
        jint *cImage = env->GetIntArrayElements(image, NULL);

        int *d_image;
        size_t size = width * height * sizeof(int);
        cudaMalloc(&d_image, size);

        dim3 blockDim(32, 8); // Total threads per block = 256
        dim3 gridDim((width + blockDim.x - 1) / blockDim.x,
                     (height + blockDim.y - 1) / blockDim.y);


        mandelbrot<<<gridDim, blockDim>>>(d_image, width, height, maxIter, centerReal, centerImag, zoom);

        cudaMemcpy(cImage, d_image, size, cudaMemcpyDeviceToHost);

        cudaFree(d_image);
        env->ReleaseIntArrayElements(image, cImage, 0);
    }
    JNIEXPORT void JNICALL Java_Mandelbrot_runMandelbrotWithColor(JNIEnv *env, jobject obj,
                                                                  jintArray image, jint width,
                                                                  jint height, jint maxIter,
                                                                  jdouble centerReal, jdouble centerImag,
                                                                  jdouble zoom) {
        jint *cImage = env->GetIntArrayElements(image, NULL);

        int *d_image;
        size_t size = width * height * sizeof(int);
        cudaMalloc(&d_image, size);

        dim3 blockDim(32, 8); // Total threads per block = 256
        dim3 gridDim((width + blockDim.x - 1) / blockDim.x,
                     (height + blockDim.y - 1) / blockDim.y);

        mandelbrotWithColor<<<gridDim, blockDim>>>(d_image, width, height, maxIter,
                                                   centerReal, centerImag, zoom);

        cudaMemcpy(cImage, d_image, size, cudaMemcpyDeviceToHost);

        cudaFree(d_image);
        env->ReleaseIntArrayElements(image, cImage, 0);
    }
}
