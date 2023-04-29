/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
package com.mpsensors.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.mpsensors.Sensors

class MainActivity : ComponentActivity() {

    val x = mutableStateOf(0.0)
    val y = mutableStateOf(0.0)
    var z = mutableStateOf(0.0)
    var prediction = mutableStateOf("Unknown")

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val sensors = Sensors(this)
        sensors.start()
        sensors.data.watch { sensors ->
            sensors?.let {
                x.value = it.sensor.x
                y.value = it.sensor.y
                z.value = it.sensor.z
            }
            // prediction.value = model.predict(x, y, z)
        }

        setContent {
            MyApplicationTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colors.background
                ) {
                    Column(modifier = Modifier.fillMaxSize(), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
                        SensorsView(x.value, y.value, z.value, prediction.value)
                    }
                }
            }
        }
    }
}

@Composable
fun SensorsView(x: Double, y: Double, z: Double, prediction: String) {
    Text("Acceleration:")
    Text("x: $x")
    Text("y: $y")
    Text("z: $z")

    Text("\nPrediction:")
    Text(prediction)
}

@Preview
@Composable
fun DefaultPreview() {
    MyApplicationTheme {
     Text(text = "Hello World!")
    }
}
