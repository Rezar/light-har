/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
package com.mpsensors

data class SensorData(
    override val heading: Double,
    override val sensor: AccelerometerInterface,
    override val gravity: AccelerometerInterface? = null
) : SensorDataInterface