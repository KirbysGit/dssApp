// -----------------------------------------------------------------
//                  ObjectDetection.cpp(Gadget)
//
//
// Description: Central point where the code runs on our
//              esp32-cam nodes.
//
// Name:         Date:           Description:
// -----------   ---------       ----------------
// Jaxon Topel   10/7/2024       Initial Creation
// Jaxon Topel   12/20/2024      IP Algorithm Debugging
//
// Note(1): ChatGPT aided in the development of this code.
// Note(2): Do not run this code directly, this will be called from
// main.ino(Gadget)
// -----------------------------------------------------------------

// TensorFlow Lite Includes
#include "person_detect_model_data.h"
#include <esp_heap_caps.h>
#include <ObjectDetection.h>
#include <algorithm>

namespace ObjectDetection 
{
  // Function to initialize our model.
  bool initializeModel() 
  {
    // If model's already been initialized.
    if (initialized)
        return true;

    // Error reporter    
    ObjectDetection::errorReporter = &ObjectDetection::micro_error_reporter;

    // Model
    ObjectDetection::ObjectDetectionModel = tflite::GetModel(g_person_detect_model_data);

    // Ensure we got our model correctly.
    if (ObjectDetection::ObjectDetectionModel->version() != TFLITE_SCHEMA_VERSION) 
    {
        TF_LITE_REPORT_ERROR(errorReporter,
            "Model schema version %d not supported. Expected %d.",
            ObjectDetection::ObjectDetectionModel->version(), TFLITE_SCHEMA_VERSION);
        return false;
    }

    // Create and allocate the Interpreter
    ObjectDetection::static_interpreter = new tflite::MicroInterpreter(ObjectDetection::ObjectDetectionModel, ObjectDetection::micro_op_resolver, 
                                                                      ObjectDetection::tensor_arena, ObjectDetection::kTensorArenaSize, nullptr);
    
    // Ensure micro interpreter is created correctly.
    if (!ObjectDetection::static_interpreter) 
    {
        TF_LITE_REPORT_ERROR(ObjectDetection::errorReporter, "Failed to create MicroInterpreter.");
        return false;
    }

    // Ensure tensors allocated correctly.
    if (ObjectDetection::static_interpreter->AllocateTensors() != kTfLiteOk) 
    {
        TF_LITE_REPORT_ERROR(ObjectDetection::errorReporter, "Tensor allocation failed.");
        return false;
    }

    // Model TensorFlow Lite micro setup.
    ObjectDetection::micro_op_resolver.AddAveragePool2D();
    ObjectDetection::micro_op_resolver.AddConv2D();
    ObjectDetection::micro_op_resolver.AddDepthwiseConv2D();
    ObjectDetection::micro_op_resolver.AddReshape();
    ObjectDetection::micro_op_resolver.AddSoftmax();

    // Use nullptr instead of error_reporter.
    ObjectDetection::Interpreter = ObjectDetection::static_interpreter;

    // Ensure interpreters tensors allocated correctly.
    if (ObjectDetection::Interpreter->AllocateTensors() != kTfLiteOk) 
    {
        TF_LITE_REPORT_ERROR(ObjectDetection::errorReporter, "Tensor allocation failed.");
        return false;
    }

    // Assign input and output tensors.
    ObjectDetection::detected_input = ObjectDetection::Interpreter->input(0);
    ObjectDetection::detected_output = ObjectDetection::Interpreter->output(0);

    // Set flag for initializing model.
    ObjectDetection::initialized = true;
    return true;
  }


  // Function to run object detection
  bool detectPerson(const uint8_t* image_data, int image_size) 
  {
      // Initialize model.
      if(ObjectDetection::initialized == false)
      {
          initializeModel();
      }

      // Copy image data to input tensor
      if (image_data && ObjectDetection::detected_input) 
      {
          memcpy(ObjectDetection::detected_input->data.uint8, image_data, image_size);
      }
      else
      {
          TF_LITE_REPORT_ERROR(ObjectDetection::errorReporter, "Invalid image data or input tensor.");
          return false;
      }

      // Run inference.
      if (ObjectDetection::Interpreter->Invoke() != kTfLiteOk)
      {
          TF_LITE_REPORT_ERROR(ObjectDetection::errorReporter, "Inference failed.");
          return false;
      }

      // Extract inference results
      float person_score = (ObjectDetection::detected_output->data.uint8[ObjectDetection::kPersonIndex]
      - ObjectDetection::detected_output->params.zero_point) * ObjectDetection::detected_output->params.scale;
      
      return person_score > 0.5f; // Return true if person detected
  }
}
// -----------------------------------------------------------------
//                  ObjectDetection.ino(Gadget)
// -----------------------------------------------------------------