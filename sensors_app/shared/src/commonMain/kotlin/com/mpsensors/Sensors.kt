/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
package com.mpsensors

expect class Sensors : SensorInterface {
    override val isEnabled: Boolean
    override val data: CommonFlow<SensorDataInterface?>
    override fun start()
    override fun stop()
}