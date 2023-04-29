/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
package com.mpsensors

interface SensorDataInterface {
    val heading: Double
    val sensor: AccelerometerInterface
    val gravity: AccelerometerInterface?
}