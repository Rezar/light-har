/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
package com.mpsensors

interface SensorInterface {
    val data: CommonFlow<SensorDataInterface?>
    val isEnabled: Boolean
    fun start()
    fun stop()
}