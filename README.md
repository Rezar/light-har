# light-har

## Document action_identity
This is an Apple Watch Application(Use Swift) designed for testing the energy consumption of different models when performing the human activation detection task. Currently, the code for **the generation of synthetic data --> data preprocessing --> model inference --> and displaying prediction results** for this functionality has been thoroughly tested.


## Document code
Under the premise of controlling the adjustable parameters, the performance of **five models (CNN, TensorFlow, GRU, LSTM, TensorFlow+CNN)** on the same data set was tested.

Combining several indicators such as accuracy and using time **(Testing Results.xlsx)**, **the GRU model has the best score**. 

coreModel format is the model format that swift accept. The file **tf_to_coreModel.ipynp** is used to convert tensorflow format to coreModle format.

## Document data
The document includes the original dataset we used **[WISDM](https://www.cis.fordham.edu/wisdm/dataset.php)**.
It also includes the preprocessed data: **WISDM_x.csv(Attributes)**, **WISDM_y.csv(Predict Target)**.

### Additional documentation:
* [mpSensors](https://github.com/Rezar/light-har/tree/main/sensors_app): a mobile app for the activity recognition experiments documented above. It is developed in Kotlin and supports Android and iOS.
