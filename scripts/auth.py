#!/usr/bin/env python3
"""
API Key Authentication Middleware
Handles API key validation, rate limiting, and usage tracking
"""

import time
import hashlib
import base64
import logging
import uuid
from typing import Optional, Dict
from datetime import datetime, date

from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware
import asyncpg
import redis.asyncio as aioredis

logger = logging.getLogger(__name__)

# Scrypt parameters (must match key generation)
SCRYPT_N, SCRYPT_R, SCRYPT_P, DKLEN = 2**14, 8, 1, 32


def scrypt_verify(raw: str, stored: str) -> bool:
    """
    Verify a raw API key against a stored scrypt hash.
    
    Args:
        raw: The raw API key from the request
        stored: The stored hash in format "scrypt$<base64_salt>$<base64_hash>"
    
    Returns:
        True if the key matches, False otherwise
    """
    try:
        parts = stored.split("$")
        if len(parts) != 3 or parts[0] != "scrypt":
            logger.warning(f"Invalid hash format: {stored[:20]}...")
            return False
            
        _, b64salt, b64hash = parts
        salt = base64.b64decode(b64salt)
        target = base64.b64decode(b64hash)
        
        h = hashlib.scrypt(
            raw.encode(),
            salt=salt,
            n=SCRYPT_N,
            r=SCRYPT_R,
            p=SCRYPT_P,
            dklen=DKLEN
        )
        
        return h == target
    except Exception as e:
        logger.error(f"Error verifying key: {e}")
        return False


class APIKeyMiddleware(BaseHTTPMiddleware):
    """
    Middleware for API key authentication, rate limiting, and usage tracking.
    
    Features:
    - API key validation with scrypt
    - Per-key rate limiting (per minute)
    - Usage tracking (requests, chars, latency)
    - Request logging with unique request IDs
    """
    
    def __init__(self, app, pool: asyncpg.Pool, redis_client: aioredis.Redis):
        super().__init__(app)
        self.pool = pool
        self.redis = redis_client
        
    async def dispatch(self, request: Request, call_next):
        """Process each request with authentication and rate limiting"""
        
        # Generate unique request ID
        request_id = str(uuid.uuid4())
        request.state.request_id = request_id
        
        # Skip auth for public endpoints
        public_paths = ["/health", "/v1/health", "/docs", "/openapi.json", "/redoc", "/"]
        if any(request.url.path.startswith(path) for path in public_paths):
            return await call_next(request)
        
        # Extract API key from header
        api_key = request.headers.get("x-api-key") or request.headers.get("authorization", "").replace("Bearer ", "")
        
        if not api_key:
            logger.warning(f"[{request_id}] Missing API key from {request.client.host}")
            raise HTTPException(
                status_code=401,
                detail="Missing x-api-key header"
            )
        
        # Extract key prefix (e.g., "cw_live_" from "cw_live_xxxxx")
        try:
            prefix_parts = api_key.split("_")
            if len(prefix_parts) >= 2:
                prefix = "_".join(prefix_parts[:2]) + "_"  # "cw_live_"
            else:
                prefix = api_key[:10]  # Fallback
        except Exception:
            prefix = api_key[:10]
        
        # Validate API key in database
        try:
            async with self.pool.acquire() as conn:
                row = await conn.fetchrow("""
                    SELECT id, key_hash, rate_limit_per_min, status, scopes, tenant_id, name
                    FROM api_keys
                    WHERE key_prefix = $1
                """, prefix)
        except Exception as e:
            logger.error(f"[{request_id}] Database error: {e}")
            raise HTTPException(status_code=503, detail="Service temporarily unavailable")
        
        if not row:
            logger.warning(f"[{request_id}] Invalid key prefix: {prefix}")
            raise HTTPException(status_code=403, detail="Invalid API key")
        
        if row["status"] != "active":
            logger.warning(f"[{request_id}] Inactive key: {row['name']}")
            raise HTTPException(status_code=403, detail=f"API key is {row['status']}")
        
        # Verify the full key hash
        if not scrypt_verify(api_key, row["key_hash"]):
            logger.warning(f"[{request_id}] Key hash verification failed for: {row['name']}")
            raise HTTPException(status_code=403, detail="Invalid API key")
        
        # Check rate limit (per minute per key)
        rate_limit_key = f"rl:{row['id']}:{int(time.time() // 60)}"
        try:
            count = await self.redis.incr(rate_limit_key)
            if count == 1:
                await self.redis.expire(rate_limit_key, 65)  # Expire after 65 seconds
            
            if count > row["rate_limit_per_min"]:
                logger.warning(f"[{request_id}] Rate limit exceeded for key: {row['name']}")
                raise HTTPException(
                    status_code=429,
                    detail=f"Rate limit exceeded: {row['rate_limit_per_min']} requests per minute",
                    headers={"Retry-After": "60"}
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"[{request_id}] Redis error: {e}")
            # Continue without rate limiting if Redis is down (fail-open for availability)
        
        # Store API key info in request state
        request.state.api_key_id = row["id"]
        request.state.api_key_name = row["name"]
        request.state.tenant_id = row["tenant_id"]
        request.state.scopes = row["scopes"]
        
        # Update last_used_at timestamp (fire and forget)
        try:
            async with self.pool.acquire() as conn:
                await conn.execute(
                    "UPDATE api_keys SET last_used_at = NOW() WHERE id = $1",
                    row["id"]
                )
        except Exception as e:
            logger.error(f"[{request_id}] Error updating last_used_at: {e}")
        
        # Process request and track timing
        start_time = time.time()
        status_code = 500
        error_message = None
        
        try:
            response = await call_next(request)
            status_code = response.status_code
            
            # Track usage
            duration_ms = int((time.time() - start_time) * 1000)
            
            # Get text length if available (will be set by TTS endpoint)
            text_length = getattr(request.state, "text_length", 0)
            voice_id = getattr(request.state, "voice_id", None)
            
            # Update usage counters (fire and forget)
            asyncio.create_task(self._update_usage(
                row["id"],
                text_length,
                duration_ms,
                status_code >= 400
            ))
            
            # Log request (fire and forget)
            asyncio.create_task(self._log_request(
                request_id,
                row["id"],
                request.url.path,
                request.method,
                status_code,
                voice_id,
                text_length,
                duration_ms,
                None,
                request.client.host if request.client else None,
                request.headers.get("user-agent")
            ))
            
            # Add custom headers
            response.headers["X-Request-ID"] = request_id
            response.headers["X-RateLimit-Limit"] = str(row["rate_limit_per_min"])
            response.headers["X-RateLimit-Remaining"] = str(max(0, row["rate_limit_per_min"] - count))
            
            return response
            
        except HTTPException as e:
            status_code = e.status_code
            error_message = e.detail
            raise
        except Exception as e:
            status_code = 500
            error_message = str(e)
            logger.error(f"[{request_id}] Unexpected error: {e}")
            raise HTTPException(status_code=500, detail="Internal server error")
    
    async def _update_usage(self, api_key_id: uuid.UUID, chars: int, duration_ms: int, is_error: bool):
        """Update usage counters in database"""
        try:
            async with self.pool.acquire() as conn:
                await conn.execute("""
                    INSERT INTO usage_counters(day, api_key_id, requests, chars, ms_synth, errors)
                    VALUES (CURRENT_DATE, $1, 1, $2, $3, $4)
                    ON CONFLICT (day, api_key_id) DO UPDATE SET
                        requests = usage_counters.requests + 1,
                        chars = usage_counters.chars + EXCLUDED.chars,
                        ms_synth = usage_counters.ms_synth + EXCLUDED.ms_synth,
                        errors = usage_counters.errors + EXCLUDED.errors
                """, api_key_id, chars, duration_ms, 1 if is_error else 0)
        except Exception as e:
            logger.error(f"Error updating usage counters: {e}")
    
    async def _log_request(
        self,
        request_id: str,
        api_key_id: uuid.UUID,
        endpoint: str,
        method: str,
        status_code: int,
        voice_id: Optional[uuid.UUID],
        text_length: int,
        duration_ms: int,
        error_message: Optional[str],
        ip_address: Optional[str],
        user_agent: Optional[str]
    ):
        """Log request details to database"""
        try:
            async with self.pool.acquire() as conn:
                await conn.execute("""
                    INSERT INTO request_logs(
                        request_id, api_key_id, endpoint, method, status_code,
                        voice_id, text_length, duration_ms, error_message,
                        ip_address, user_agent
                    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
                """, request_id, api_key_id, endpoint, method, status_code,
                voice_id, text_length, duration_ms, error_message,
                ip_address, user_agent)
        except Exception as e:
            logger.error(f"Error logging request: {e}")


# Import asyncio at the end to avoid circular imports
import asyncio

