#include <iostream>
#include <vector>

using namespace std;

// Function to add padding to a 2D matrix
vector<vector<float>> addPadding(const vector<vector<float>>& matrix, int padding) {
    int mRows = matrix.size();
    int mCols = matrix[0].size();
    int paddedRows = mRows + 2 * padding;
    int paddedCols = mCols + 2 * padding;

    vector<vector<float>> paddedMatrix(paddedRows, vector<float>(paddedCols, 0));

    // Copy the original matrix into the center of the padded matrix
    for (int i = 0; i < mRows; ++i) {
        for (int j = 0; j < mCols; ++j) {
            paddedMatrix[i + padding][j + padding] = matrix[i][j];
        }
    }

    for (int i = 0; i < paddedRows; i++) {
        for (int j = 0; j < paddedCols; j++) {
            cout << paddedMatrix[i][j] << '\t';
        }
        cout << '\n';
    }
    cout << "\n\n";

    return paddedMatrix;
}

// Function to perform 2D convolution with stride and padding
vector<vector<float>> convolve2D(const vector<vector<float>>& matrix, const vector<vector<float>>& kernel, int stride, int padding) {
    int kRows = kernel.size();
    int kCols = kernel[0].size();

    // Add padding to the matrix
    vector<vector<float>> paddedMatrix = addPadding(matrix, padding);

    int pRows = paddedMatrix.size();
    int pCols = paddedMatrix[0].size();

    // Calculate output dimensions
    int outRows = (pRows - kRows) / stride + 1;
    int outCols = (pCols - kCols) / stride + 1;

    // Initialize output matrix with zeros
    vector<vector<float>> output(outRows, vector<float>(outCols, 0));

    // Perform convolution with stride
    for (int i = 0; i < outRows; ++i) {
        for (int j = 0; j < outCols; ++j) {
            float sum = 0;
            for (int ki = 0; ki < kRows; ++ki) {
                for (int kj = 0; kj < kCols; ++kj) {
                    int row = i * stride + ki;
                    int col = j * stride + kj;
                    sum += paddedMatrix[row][col] * kernel[ki][kj];

                    cout << paddedMatrix[row][col] << " \t" << kernel[ki][kj] << "\t" << sum << "\n";
                }
            }
            output[i][j] = sum;
        }
    }

    return output;
}
void printMat(vector<vector<float>> vec) {

}

int main() {
    // vector<vector<float>> image = {   { 1.2,  1.5,    2.1,    0.0,    0.0 },
    //                                         { 0.0,  1.0,    1.0,    1.0,    0.0 },
    //                                         { 0.0,  0.0,    1.0,    1.0,    1.0 },
    //                                         { 0.0,  0.0,    1.0,    1.0,    0.0 },
    //                                         { 0.0,  1.0,    1.0,    0.0,    0.0 }   };

    // vector<vector<float>> kernel = { { 1.0, 0.0, 1.0 }, 
    //                                  { 0.0, 1.0, 0.0 }, 
    //                                  { 1.0, 0.0, 1.0 } };      
    vector<vector<float>> image = { {-1.0,     1.0,     -2.0,     3.0,     -0.4},
                                    { 1.0,     2.0,      3.0,     4.0,      1.0},
                                    { 1.0,     1.2,      1.3,     1.6,     10.0},
                                    { 2.3,     4.5,     -5.0,    -6.0,      2.0},
                                    { 3.0,     4.0,      5.0,     6.0,      7.0} };

    vector<vector<float>> kernel = { { -3.0,    -4.0},
                                     {  4.5,     6.0} };

    int stride = 2;
    int padding = 3;

    vector<vector<float>> output = convolve2D(image, kernel, stride, padding);

    int outputSize = ((image.size() + 2*padding - kernel.size()) / stride) + 1;

    for (int i = 0; i < outputSize; i++) {
        for (int j = 0; j < outputSize; j++) {
            cout << output[i][j] << '\t';
        }
        cout << '\n';
    }

    return 0;
}