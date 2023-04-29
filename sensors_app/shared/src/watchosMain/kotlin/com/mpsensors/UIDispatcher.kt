/**
 * Gaston Longhitano <gastonl@bu.edu> @ Boston University - Research
 *
 * This source code is licensed under the terms found in the
 * LICENSE file in the root directory of this source tree.
 */
package com.mpsensors

import kotlinx.coroutines.*
import platform.darwin.*
import kotlin.coroutines.CoroutineContext

@OptIn(InternalCoroutinesApi::class)
internal class UIDispatcher : CoroutineDispatcher(), Delay {
    private val mQueue = dispatch_get_main_queue()

    override fun dispatch(context: CoroutineContext, block: Runnable) {
        dispatch_async(mQueue) {
            block.run()
        }
    }

    override fun scheduleResumeAfterDelay(
        timeMillis: Long,
        continuation: CancellableContinuation<Unit>
    ) {
        dispatch_after(
            `when` = dispatch_time(
                DISPATCH_TIME_NOW,
                timeMillis * NSEC_PER_MSEC.toLong()
            ),
            queue = mQueue
        ) {
            val result = continuation.tryResume(Unit)
            if (result != null) {
                continuation.completeResume(result)
            }
        }
    }

    override fun invokeOnTimeout(
        timeMillis: Long,
        block: Runnable,
        context: CoroutineContext
    ): DisposableHandle {
        var disposed = false
        dispatch_after(
            `when` = dispatch_time(
                DISPATCH_TIME_NOW,
                timeMillis * NSEC_PER_MSEC.toLong()
            ),
            queue = mQueue
        ) {
            if (disposed) return@dispatch_after

            block.run()
        }
        return object : DisposableHandle {
            override fun dispose() {
                disposed = true
            }
        }
    }
}