"""
Voice Request Queue Manager - Prevents Overlapping TTS Calls
=============================================================
Industry best practice: Session-based request queuing with voice isolation.

Features:
- Per-voice concurrency limits (prevents same voice from overlapping)
- Session-based isolation (different users can use same voice simultaneously)
- Request queuing with timeout
- Automatic cleanup of stale sessions

This is how Twilio, Amazon Connect, and Google Dialogflow prevent audio conflicts.
"""

import asyncio
import logging
import time
import uuid
from typing import Dict, Optional, Any
from dataclasses import dataclass, field
from contextlib import asynccontextmanager

logger = logging.getLogger(__name__)


@dataclass
class QueuedRequest:
    """Represents a queued TTS request"""
    request_id: str
    voice_id: str
    session_id: Optional[str]
    text: str
    timestamp: float = field(default_factory=time.time)
    timeout: float = 30.0


class VoiceRequestQueue:
    """
    Manages TTS request queuing to prevent voice overlap.

    Best practices:
    1. One voice instance can only synthesize ONE audio at a time
    2. Different sessions can use different voices simultaneously
    3. Same session should queue requests for the same voice
    4. Timeout stale requests to prevent queue buildup
    """

    def __init__(self):
        # Track active synthesis per voice
        self._active_synthesis: Dict[str, str] = {}  # voice_id → request_id

        # Locks per voice to prevent race conditions
        self._voice_locks: Dict[str, asyncio.Lock] = {}

        # Session tracking for isolation
        self._session_voices: Dict[str, set] = {}  # session_id → {voice_ids}

        # Queue stats
        self.total_requests = 0
        self.queued_requests = 0
        self.completed_requests = 0
        self.timeout_requests = 0

    def _get_isolation_key(self, voice_id: str, session_id: Optional[str]) -> str:
        """
        Generate isolation key for request.

        Best practice: Isolate by voice OR by session+voice
        - If session_id is None: global lock per voice
        - If session_id is set: lock per session+voice combination

        This allows:
        - User A using "naija_female" doesn't block User B using "naija_male"
        - User A's sequential messages queue properly
        """
        if session_id:
            return f"{session_id}:{voice_id}"
        return voice_id

    def _get_lock(self, isolation_key: str) -> asyncio.Lock:
        """Get or create lock for isolation key"""
        if isolation_key not in self._voice_locks:
            self._voice_locks[isolation_key] = asyncio.Lock()
        return self._voice_locks[isolation_key]

    @asynccontextmanager
    async def acquire_voice(
        self,
        request_id: str,
        voice_id: str,
        session_id: Optional[str] = None,
        timeout: float = 30.0
    ):
        """
        Acquire exclusive access to a voice for synthesis.

        Usage:
            async with queue.acquire_voice(req_id, voice_id, session_id):
                # Synthesize audio here
                # No other request can use this voice+session until released

        Args:
            request_id: Unique request ID
            voice_id: Voice to use
            session_id: Optional session ID for isolation
            timeout: Max time to wait for lock (seconds)

        Yields:
            None (just provides lock context)

        Raises:
            TimeoutError: If lock cannot be acquired within timeout
        """
        isolation_key = self._get_isolation_key(voice_id, session_id)
        lock = self._get_lock(isolation_key)

        self.total_requests += 1
        start_time = time.time()

        logger.info(
            f"[{request_id}] Acquiring voice lock: key={isolation_key}, "
            f"session={session_id or 'global'}"
        )

        try:
            # Try to acquire lock with timeout
            acquired = await asyncio.wait_for(
                lock.acquire(),
                timeout=timeout
            )

            if not acquired:
                self.timeout_requests += 1
                raise TimeoutError(
                    f"Failed to acquire voice lock for {isolation_key} within {timeout}s"
                )

            wait_time = time.time() - start_time
            if wait_time > 0.1:  # Log if had to wait
                self.queued_requests += 1
                logger.warning(
                    f"[{request_id}] Request queued for {wait_time:.2f}s "
                    f"(isolation_key={isolation_key})"
                )

            # Mark as active
            self._active_synthesis[isolation_key] = request_id

            # Track session
            if session_id:
                if session_id not in self._session_voices:
                    self._session_voices[session_id] = set()
                self._session_voices[session_id].add(voice_id)

            logger.info(
                f"[{request_id}] Voice lock acquired: {isolation_key} "
                f"(waited {wait_time:.3f}s)"
            )

            # Yield control back to caller
            yield

        except asyncio.TimeoutError:
            self.timeout_requests += 1
            logger.error(
                f"[{request_id}] TIMEOUT waiting for voice lock: {isolation_key} "
                f"(timeout={timeout}s)"
            )
            raise TimeoutError(
                f"Voice {voice_id} is busy. Request timed out after {timeout}s. "
                f"Try again or use a different voice."
            )

        finally:
            # Always release lock
            if lock.locked():
                # Clean up tracking
                if isolation_key in self._active_synthesis:
                    del self._active_synthesis[isolation_key]

                lock.release()
                self.completed_requests += 1

                logger.info(
                    f"[{request_id}] Voice lock released: {isolation_key} "
                    f"(total_time={(time.time() - start_time):.3f}s)"
                )

    def get_stats(self) -> Dict[str, Any]:
        """Get queue statistics"""
        return {
            "total_requests": self.total_requests,
            "queued_requests": self.queued_requests,
            "completed_requests": self.completed_requests,
            "timeout_requests": self.timeout_requests,
            "active_locks": len([k for k, v in self._voice_locks.items() if v.locked()]),
            "total_locks": len(self._voice_locks),
            "active_sessions": len(self._session_voices)
        }

    def is_voice_busy(self, voice_id: str, session_id: Optional[str] = None) -> bool:
        """Check if a voice is currently busy"""
        isolation_key = self._get_isolation_key(voice_id, session_id)
        lock = self._voice_locks.get(isolation_key)
        return lock.locked() if lock else False

    def get_active_request(self, voice_id: str, session_id: Optional[str] = None) -> Optional[str]:
        """Get the currently active request ID for a voice"""
        isolation_key = self._get_isolation_key(voice_id, session_id)
        return self._active_synthesis.get(isolation_key)

    async def cleanup_session(self, session_id: str):
        """Clean up all locks for a session"""
        if session_id not in self._session_voices:
            return

        voice_ids = self._session_voices[session_id]
        logger.info(f"Cleaning up session {session_id}: {len(voice_ids)} voices")

        for voice_id in voice_ids:
            isolation_key = f"{session_id}:{voice_id}"
            if isolation_key in self._voice_locks:
                lock = self._voice_locks[isolation_key]
                if lock.locked():
                    logger.warning(
                        f"Session cleanup: Force-releasing locked voice {isolation_key}"
                    )
                    lock.release()
                del self._voice_locks[isolation_key]

        del self._session_voices[session_id]
        logger.info(f"Session {session_id} cleaned up")


# Global queue instance
_global_queue: Optional[VoiceRequestQueue] = None


def get_voice_queue() -> VoiceRequestQueue:
    """Get or create global voice queue instance"""
    global _global_queue
    if _global_queue is None:
        _global_queue = VoiceRequestQueue()
        logger.info("Voice queue manager initialized")
    return _global_queue


# Example usage and testing
if __name__ == "__main__":
    async def test_queue():
        """Test the queue system"""
        queue = get_voice_queue()

        async def simulate_tts(req_id: str, voice: str, session: str, duration: float):
            """Simulate a TTS request"""
            try:
                async with queue.acquire_voice(req_id, voice, session, timeout=5.0):
                    logger.info(f"[{req_id}] Synthesizing for {duration}s...")
                    await asyncio.sleep(duration)
                    logger.info(f"[{req_id}] Complete!")
            except TimeoutError as e:
                logger.error(f"[{req_id}] {e}")

        # Test 1: Sequential requests for same voice (should queue)
        logger.info("\n" + "=" * 80)
        logger.info("TEST 1: Sequential requests - same voice, same session")
        logger.info("=" * 80)

        await asyncio.gather(
            simulate_tts("req1", "naija_female", "session_a", 1.0),
            simulate_tts("req2", "naija_female", "session_a", 1.0),
            simulate_tts("req3", "naija_female", "session_a", 1.0),
        )

        # Test 2: Parallel requests for different voices (should NOT queue)
        logger.info("\n" + "=" * 80)
        logger.info("TEST 2: Parallel requests - different voices")
        logger.info("=" * 80)

        await asyncio.gather(
            simulate_tts("req4", "naija_female", "session_b", 1.0),
            simulate_tts("req5", "naija_male", "session_b", 1.0),
            simulate_tts("req6", "emily-en-us", "session_b", 1.0),
        )

        # Test 3: Different sessions, same voice (should NOT queue)
        logger.info("\n" + "=" * 80)
        logger.info("TEST 3: Different sessions - same voice")
        logger.info("=" * 80)

        await asyncio.gather(
            simulate_tts("req7", "naija_female", "session_c", 1.0),
            simulate_tts("req8", "naija_female", "session_d", 1.0),
            simulate_tts("req9", "naija_female", "session_e", 1.0),
        )

        # Print stats
        logger.info("\n" + "=" * 80)
        logger.info("QUEUE STATS")
        logger.info("=" * 80)
        stats = queue.get_stats()
        for key, value in stats.items():
            logger.info(f"{key}: {value}")

    # Run test
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s'
    )
    asyncio.run(test_queue())
