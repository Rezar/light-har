/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
package com.mpsensors

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlinx.coroutines.flow.MutableStateFlow

/**
 * Android implementation of the SensorInterface.
 */
actual class Sensors constructor(context: Context) :
    SensorEventListener, SensorInterface {

    private var mSensorManager: SensorManager? =
        context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager

    private var sAccelerometer: Sensor? =
        mSensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private var sGravity: Sensor? = mSensorManager?.getDefaultSensor(Sensor.TYPE_GRAVITY)
    private var sMagnetic: Sensor? = mSensorManager?.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)
    private var sRotation: Sensor? = mSensorManager?.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)

    private var rawAccelerometer: FloatArray? = null
    private var rawRotation: FloatArray? = null
    private var rawGravity: FloatArray? = null
    private var rawMagnetic: FloatArray? = null
    private var rawRotationMatrix = FloatArray(9)
    private var orientation = FloatArray(3)
    private var heading: Double = 0.0

    private var _isEnabled = false
    actual override val isEnabled: Boolean
        get() = _isEnabled

    private var _data = MutableStateFlow<SensorData?>(null)
    actual override val data: CommonFlow<SensorDataInterface?>
        get() = _data.asCommonFlow()

    actual override fun start() {
        _isEnabled = true
        mSensorManager?.registerListener(this, sAccelerometer, SensorManager.SENSOR_DELAY_NORMAL)
        mSensorManager?.registerListener(this, sGravity, SensorManager.SENSOR_DELAY_NORMAL)
        mSensorManager?.registerListener(this, sMagnetic, SensorManager.SENSOR_DELAY_NORMAL)
        mSensorManager?.registerListener(this, sRotation, SensorManager.SENSOR_DELAY_NORMAL)
    }

    actual override fun stop() {
        _isEnabled = false
        mSensorManager?.unregisterListener(this, sAccelerometer)
        mSensorManager?.unregisterListener(this, sGravity)
        mSensorManager?.unregisterListener(this, sMagnetic)
        mSensorManager?.unregisterListener(this, sRotation)
    }

    override fun onSensorChanged(p0: SensorEvent?) {
        if (!isEnabled) return

        val values = p0!!.values.copyOf()

        when (p0.sensor.type) {
            Sensor.TYPE_MAGNETIC_FIELD -> rawMagnetic = values
            Sensor.TYPE_GRAVITY -> rawGravity = values
            Sensor.TYPE_ACCELEROMETER -> rawAccelerometer = values
            Sensor.TYPE_ROTATION_VECTOR -> {
                rawRotation = values
                SensorManager.getRotationMatrixFromVector(rawRotationMatrix, values)
                heading = ((Math.toDegrees(
                    SensorManager.getOrientation(
                        rawRotationMatrix,
                        orientation
                    )[0].toDouble()
                ) + 360).toInt() % 360).toDouble()
            }
        }

        if (rawMagnetic != null && rawGravity != null && rawAccelerometer != null && rawRotation != null) {

            SensorManager.getRotationMatrix(rawRotationMatrix, null, rawGravity, rawMagnetic)
            heading = ((Math.toDegrees(
                SensorManager.getOrientation(
                    rawRotationMatrix,
                    orientation
                )[0].toDouble()
            ) + 360).toInt() % 360).toDouble()

            val user = AccelerometerData(
                rawAccelerometer!![0].toDouble(),
                rawAccelerometer!![1].toDouble(),
                rawAccelerometer!![2].toDouble()
            )
            val gravity = AccelerometerData(
                rawGravity!![0].toDouble(),
                rawGravity!![1].toDouble(),
                rawGravity!![2].toDouble()
            )

            _data.value = SensorData(heading, user, gravity)
        }

    }

    override fun onAccuracyChanged(p0: Sensor?, p1: Int) {}
}