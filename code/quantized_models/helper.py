import numpy as np
from sklearn.metrics import accuracy_score
import numpy as np
import tensorflow as tf
from tensorflow import keras
import time
import psutil
from pathlib import Path

def compute_metrics_base(model, x_test, y_test, model_dir):
    """
    Compute the accuracy of the TensorFlow model.

    :param model: TensorFlow model.
    :param x_test: Test dataset features.
    :param y_test: Test dataset labels.
    :return: None
    """
    
    # Get the model's predictions
    predictions = model.predict(x_test)

    # Convert predictions and y_test to label format
    predicted_labels = np.argmax(predictions, axis=1)
    true_labels = np.argmax(y_test, axis=1)
    
    model_size = sum(f.stat().st_size for f in Path(model_dir).rglob('*'))
    print(f'Size of the model: {model_size/1024:.2f} KB')

    # Compute accuracy
    accuracy = accuracy_score(true_labels, predicted_labels)
    print(f'Accuracy on the test set: {accuracy:.2%}')
    
    


def compute_metrics(tflite_quant_model, X_test, y_test, input_type='float32'):
    """
    Compute the accuracy of the TFLite model.

    :param tflite_quant_model: Quantized TFLite model.
    :param X_test: Test dataset features.
    :param y_test: Test dataset labels.
    :param input_type: The type of the input data ('float32' or 'int8').
    :return: None
    """

    interpreter = tf.lite.Interpreter(model_content=tflite_quant_model)
    interpreter.allocate_tensors()
    input_tensor_index = interpreter.get_input_details()[0]['index']
    
    model_size = len(tflite_quant_model)
    print(f"Size of TFLite model: {model_size/1024:.2f} KB")

    predictions = []
    for i in range(len(X_test)):
        if input_type == 'float32':
            input_data = X_test[i:i + 1].astype(np.float32)
        elif input_type == 'int8':
            input_data = (X_test[i:i + 1] * 255).astype(np.int8)
        elif input_type == 'uint8':
            input_data = (X_test[i:i + 1] * 255).astype(np.uint8)
        else:
            raise ValueError(f"Unsupported input_type: {input_type}")

        interpreter.set_tensor(input_tensor_index, input_data)
        interpreter.invoke()

        output_details = interpreter.get_output_details()[0]
        output_data = interpreter.get_tensor(output_details['index'])
        predicted_label = np.argmax(output_data)
        predictions.append(predicted_label)

    predictions = np.array(predictions)
    y_test_labels = np.argmax(y_test, axis=1)
    accuracy = accuracy_score(y_test_labels, predictions)

    print(f'Accuracy on the test set: {accuracy:.2%}')
    
def measure_cpu_utilization_and_run(func, *args, **kwargs):
    """
    Measure CPU utilization while running a function.

    Parameters:
        func (function): The function to be executed.
        *args: Arguments to be passed to func.
        **kwargs: Keyword arguments to be passed to func.

    Returns:
        float: CPU utilization percentage during the execution of func.
        float: The elapsed time during the execution of func.
        any: The result of func execution.
    """
    
    # Measure CPU utilization before execution
    cpu_percent_before = psutil.cpu_percent(interval=None)

    # Record the start time
    start_time = time.time()

    # Execute the function and store its result
    result = func(*args, **kwargs)

    # Record the end time
    end_time = time.time()

    # Measure CPU utilization after execution
    cpu_percent_after = psutil.cpu_percent(interval=None)

    # Calculate elapsed time and average CPU utilization
    elapsed_time = end_time - start_time
    average_cpu_utilization = (cpu_percent_before + cpu_percent_after) / 2

    return average_cpu_utilization, elapsed_time, result

