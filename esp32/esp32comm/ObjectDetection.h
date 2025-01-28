#ifndef OBJECT_DETECTION_H
#define OBJECT_DETECTION_H

#include <tensorflow/lite/micro/micro_interpreter.h>
#include <tensorflow/lite/micro/micro_mutable_op_resolver.h>
#include <tensorflow/lite/micro/tflite_bridge/micro_error_reporter.h>

namespace ObjectDetection 
{
    // Declare class members (without initialization)
    static tflite::ErrorReporter* errorReporter;
    static const tflite::Model* ObjectDetectionModel;
    static tflite::MicroInterpreter* Interpreter;
    static TfLiteTensor* detected_input;
    static TfLiteTensor* detected_output;

    // Declare other variables and constants (without initialization)
    constexpr int kTensorArenaSize = 80 * 1024; 
    static uint8_t tensor_arena[kTensorArenaSize]; 
    static bool initialized = false;
    constexpr int kPersonIndex = 1; 
    // static int image_width = 96;
    // static int image_height = 96;

    // static int new_width;
    // static int new_height;

    // Declare class functions
    bool initializeModel();
    bool detectPerson(const uint8_t* image_data, int image_size); 

    // Declare static members (without initialization)
    static tflite::MicroMutableOpResolver<5> micro_op_resolver;
    static tflite::MicroErrorReporter micro_error_reporter;
    static tflite::MicroInterpreter* static_interpreter; 

} // namespace ObjectDetection

#endif // OBJECT_DETECTION_H