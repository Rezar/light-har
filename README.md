# light-har

## Document action_identity


### Description
Contains two main functions: get accelerometer data on apple watch **(haven't been tested)**, use **GRU** to predict activity behavior **(tested and available)**


### Models
Under the premise of controlling the adjustable parameters, the performance of **five models (CNN, TensorFlow, GRU, LSTM, TensorFlow+CNN)** on the same data set was tested.

Combining several indicators such as accuracy and using time **(ExperimentalRecord.xlsx)**, **the GRU model has the best score**. Therefore, in the implementation of watchOS app, we choose to embed the GRU model.


### Additional documentation:
* [mpSensors](https://github.com/Rezar/light-har/tree/main/sensors_app): a mobile app for the activity recognition experiments documented above. It is developed in Kotlin and supports Android and iOS.