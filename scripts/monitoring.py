#!/usr/bin/env python3
"""
Monitoring and Metrics Module
Provides Prometheus metrics for observability
"""

import time
import logging
import psutil
from typing import Dict
from prometheus_client import Counter, Histogram, Gauge, Info, generate_latest, CONTENT_TYPE_LATEST
from fastapi import APIRouter, Response

logger = logging.getLogger(__name__)

# Create router for metrics endpoint
router = APIRouter()

# ============================================================================
# Prometheus Metrics
# ============================================================================

# Request metrics
http_requests_total = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status_code']
)

http_request_duration_seconds = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency',
    ['method', 'endpoint']
)

# TTS-specific metrics
tts_requests_total = Counter(
    'tts_requests_total',
    'Total TTS generation requests',
    ['voice_id', 'format', 'status']
)

tts_generation_duration_seconds = Histogram(
    'tts_generation_duration_seconds',
    'TTS generation duration in seconds',
    ['voice_id', 'format'],
    buckets=[0.1, 0.25, 0.5, 1.0, 2.0, 5.0, 10.0]
)

tts_text_length = Histogram(
    'tts_text_length_characters',
    'Length of text submitted for TTS',
    buckets=[10, 50, 100, 200, 500, 1000, 1200]
)

tts_audio_duration_seconds = Histogram(
    'tts_audio_duration_seconds',
    'Duration of generated audio',
    buckets=[1, 5, 10, 30, 60, 120, 300]
)

# API key metrics
api_key_requests_total = Counter(
    'api_key_requests_total',
    'Total requests per API key',
    ['api_key_id', 'api_key_name']
)

api_key_rate_limit_exceeded_total = Counter(
    'api_key_rate_limit_exceeded_total',
    'Total rate limit violations',
    ['api_key_id', 'api_key_name']
)

# System metrics
system_cpu_percent = Gauge(
    'system_cpu_percent',
    'System CPU usage percentage'
)

system_memory_percent = Gauge(
    'system_memory_percent',
    'System memory usage percentage'
)

system_disk_usage_percent = Gauge(
    'system_disk_usage_percent',
    'System disk usage percentage'
)

# Model metrics
model_loaded = Gauge(
    'tts_model_loaded',
    'Whether TTS model is loaded (1=loaded, 0=not loaded)'
)

model_inference_errors_total = Counter(
    'tts_model_inference_errors_total',
    'Total TTS model inference errors'
)

# Database connection pool metrics
db_pool_size = Gauge(
    'db_pool_size',
    'Database connection pool size'
)

db_pool_available = Gauge(
    'db_pool_available',
    'Available database connections'
)

# Redis metrics
redis_operations_total = Counter(
    'redis_operations_total',
    'Total Redis operations',
    ['operation', 'status']
)

# Application info
app_info = Info('app_info', 'Application information')


# ============================================================================
# Metric Helper Functions
# ============================================================================

def update_system_metrics():
    """Update system resource metrics"""
    try:
        system_cpu_percent.set(psutil.cpu_percent(interval=0.1))
        system_memory_percent.set(psutil.virtual_memory().percent)
        system_disk_usage_percent.set(psutil.disk_usage('/').percent)
    except Exception as e:
        logger.error(f"Error updating system metrics: {e}")


def record_tts_request(voice_id: str, format: str, status: str, duration: float, text_length: int):
    """Record TTS request metrics"""
    try:
        tts_requests_total.labels(voice_id=voice_id, format=format, status=status).inc()
        tts_generation_duration_seconds.labels(voice_id=voice_id, format=format).observe(duration)
        tts_text_length.observe(text_length)
    except Exception as e:
        logger.error(f"Error recording TTS metrics: {e}")


def record_http_request(method: str, endpoint: str, status_code: int, duration: float):
    """Record HTTP request metrics"""
    try:
        http_requests_total.labels(method=method, endpoint=endpoint, status_code=status_code).inc()
        http_request_duration_seconds.labels(method=method, endpoint=endpoint).observe(duration)
    except Exception as e:
        logger.error(f"Error recording HTTP metrics: {e}")


def record_api_key_request(api_key_id: str, api_key_name: str):
    """Record API key usage"""
    try:
        api_key_requests_total.labels(api_key_id=api_key_id, api_key_name=api_key_name).inc()
    except Exception as e:
        logger.error(f"Error recording API key metrics: {e}")


def record_rate_limit_exceeded(api_key_id: str, api_key_name: str):
    """Record rate limit violation"""
    try:
        api_key_rate_limit_exceeded_total.labels(api_key_id=api_key_id, api_key_name=api_key_name).inc()
    except Exception as e:
        logger.error(f"Error recording rate limit metrics: {e}")


def set_model_loaded(loaded: bool):
    """Set model loaded status"""
    try:
        model_loaded.set(1 if loaded else 0)
    except Exception as e:
        logger.error(f"Error setting model loaded metric: {e}")


def record_model_error():
    """Record model inference error"""
    try:
        model_inference_errors_total.inc()
    except Exception as e:
        logger.error(f"Error recording model error: {e}")


def update_db_pool_metrics(pool_size: int, available: int):
    """Update database pool metrics"""
    try:
        db_pool_size.set(pool_size)
        db_pool_available.set(available)
    except Exception as e:
        logger.error(f"Error updating DB pool metrics: {e}")


def record_redis_operation(operation: str, success: bool):
    """Record Redis operation"""
    try:
        status = "success" if success else "error"
        redis_operations_total.labels(operation=operation, status=status).inc()
    except Exception as e:
        logger.error(f"Error recording Redis metrics: {e}")


def set_app_info(version: str, environment: str, device: str):
    """Set application info"""
    try:
        app_info.info({
            'version': version,
            'environment': environment,
            'device': device
        })
    except Exception as e:
        logger.error(f"Error setting app info: {e}")


# ============================================================================
# Metrics Endpoint
# ============================================================================

@router.get("/metrics")
async def metrics_endpoint():
    """
    Prometheus metrics endpoint.
    
    Exposes all application metrics in Prometheus format.
    This endpoint does not require authentication to allow Prometheus scraping.
    """
    # Update system metrics on each scrape
    update_system_metrics()
    
    # Generate Prometheus metrics
    metrics_output = generate_latest()
    
    return Response(
        content=metrics_output,
        media_type=CONTENT_TYPE_LATEST
    )


@router.get("/health/detailed")
async def detailed_health():
    """
    Detailed health check with system metrics.
    
    Returns comprehensive system health information.
    """
    try:
        cpu_percent = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return {
            "status": "healthy",
            "system": {
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "memory_available_mb": memory.available / (1024 * 1024),
                "disk_percent": disk.percent,
                "disk_free_gb": disk.free / (1024 * 1024 * 1024)
            },
            "uptime_seconds": time.time() - psutil.boot_time()
        }
    except Exception as e:
        logger.error(f"Error getting detailed health: {e}")
        return {
            "status": "degraded",
            "error": str(e)
        }

