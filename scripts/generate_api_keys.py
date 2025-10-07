#!/usr/bin/env python3
"""
API Key Generation Script
Generates secure API keys with scrypt hashing
"""

import secrets
import hashlib
import base64
import sys
import argparse
from typing import Tuple

# Scrypt parameters (must match auth.py)
SCRYPT_N, SCRYPT_R, SCRYPT_P, DKLEN = 2**14, 8, 1, 32


def generate_api_key(prefix: str = "cw_live_") -> Tuple[str, str, str]:
    """
    Generate a new API key with scrypt hash.
    
    Args:
        prefix: Key prefix (e.g., "cw_live_" for production, "cw_test_" for testing)
    
    Returns:
        Tuple of (full_key, key_prefix, key_hash)
    """
    # Generate random key
    random_part = secrets.token_urlsafe(32)
    full_key = f"{prefix}{random_part}"
    
    # Generate salt and hash
    salt = secrets.token_bytes(16)
    
    # Try to use hashlib.scrypt if available (Python 3.6+)
    try:
        hash_bytes = hashlib.scrypt(
            full_key.encode(),
            salt=salt,
            n=SCRYPT_N,
            r=SCRYPT_R,
            p=SCRYPT_P,
            dklen=DKLEN
        )
    except AttributeError:
        # Fallback to passlib if hashlib.scrypt not available
        try:
            from passlib.hash import scrypt
            hash_result = scrypt.using(salt=salt, rounds=SCRYPT_N, block_size=SCRYPT_R, parallelism=SCRYPT_P).hash(full_key)
            # Extract the hash part (passlib format is different)
            # For simplicity, use SHA256 as fallback
            print("⚠  Warning: hashlib.scrypt not available, using SHA256 (less secure)")
            print("   Consider upgrading to Python 3.6+ for proper scrypt support")
            hash_bytes = hashlib.sha256(full_key.encode() + salt).digest()
        except ImportError:
            # Final fallback to SHA256
            print("⚠  Warning: scrypt not available, using SHA256 (less secure)")
            print("   Install passlib or upgrade to Python 3.6+ for proper scrypt support")
            hash_bytes = hashlib.sha256(full_key.encode() + salt).digest()
    
    # Format as "scrypt$<base64_salt>$<base64_hash>"
    key_hash = "scrypt$" + base64.b64encode(salt).decode() + "$" + base64.b64encode(hash_bytes).decode()
    
    return full_key, prefix, key_hash


def generate_sql_insert(
    name: str,
    full_key: str,
    key_prefix: str,
    key_hash: str,
    tenant_id: str = "00000000-0000-0000-0000-000000000000",
    rate_limit: int = 120,
    scopes: str = "'{tts:write,voices:read}'"
) -> str:
    """
    Generate SQL INSERT statement for the API key.
    
    Args:
        name: Human-readable name for the key
        full_key: The complete API key (DO NOT store in DB)
        key_prefix: The key prefix (e.g., "cw_live_")
        key_hash: The scrypt hash
        tenant_id: Tenant UUID
        rate_limit: Requests per minute
        scopes: Comma-separated scopes in PostgreSQL array format
    
    Returns:
        SQL INSERT statement
    """
    return f"""
INSERT INTO api_keys (name, key_prefix, key_hash, tenant_id, scopes, rate_limit_per_min, status)
VALUES (
    '{name}',
    '{key_prefix}',
    '{key_hash}',
    '{tenant_id}',
    {scopes},
    {rate_limit},
    'active'
);
"""


def main():
    parser = argparse.ArgumentParser(description="Generate API keys for CallWaiting TTS")
    parser.add_argument("-n", "--count", type=int, default=1, help="Number of keys to generate")
    parser.add_argument("-p", "--prefix", type=str, default="cw_live_", help="Key prefix")
    parser.add_argument("--name-prefix", type=str, default="API Key", help="Name prefix for keys")
    parser.add_argument("-r", "--rate-limit", type=int, default=120, help="Rate limit per minute")
    parser.add_argument("--sql", action="store_true", help="Output SQL INSERT statements")
    parser.add_argument("--tenant-id", type=str, default="00000000-0000-0000-0000-000000000000", help="Tenant UUID")
    
    args = parser.parse_args()
    
    print("=" * 80)
    print("CallWaiting TTS - API Key Generator")
    print("=" * 80)
    print()
    
    keys_info = []
    
    for i in range(args.count):
        full_key, key_prefix, key_hash = generate_api_key(args.prefix)
        name = f"{args.name_prefix} #{i+1}" if args.count > 1 else args.name_prefix
        
        keys_info.append({
            "name": name,
            "full_key": full_key,
            "key_prefix": key_prefix,
            "key_hash": key_hash
        })
    
    if args.sql:
        print("-- SQL INSERT Statements")
        print("-- IMPORTANT: Store the full API keys in your secret manager!")
        print("-- DO NOT commit the full keys to version control!")
        print()
        
        for info in keys_info:
            print(generate_sql_insert(
                info["name"],
                info["full_key"],
                info["key_prefix"],
                info["key_hash"],
                args.tenant_id,
                args.rate_limit
            ))
    else:
        print("Generated API Keys:")
        print()
        print("⚠️  CRITICAL: Store these keys securely! They will NOT be shown again.")
        print("⚠️  Store in environment variables or secret manager (AWS Secrets Manager, etc.)")
        print()
        
        for info in keys_info:
            print(f"Name:       {info['name']}")
            print(f"Full Key:   {info['full_key']}")
            print(f"Prefix:     {info['key_prefix']}")
            print(f"Hash:       {info['key_hash'][:50]}...")
            print()
        
        print("=" * 80)
        print("To insert into database, run with --sql flag:")
        print(f"  python3 {sys.argv[0]} -n {args.count} --sql | psql -U postgres -d chatterbox")
        print()
        print("Or manually insert into PostgreSQL:")
        print("  INSERT INTO api_keys (name, key_prefix, key_hash, tenant_id, status)")
        print("  VALUES ('<name>', '<prefix>', '<hash>', '<tenant_id>', 'active');")
        print("=" * 80)


if __name__ == "__main__":
    # Quick demo mode if no args
    if len(sys.argv) == 1 and sys.stdin.isatty():
        print("Generating 5 example keys for demonstration...")
        print()
        
        for i in range(5):
            full_key, key_prefix, key_hash = generate_api_key()
            print(f"Key {i+1}:")
            print(f"  Full Key: {full_key}")
            print(f"  Hash:     {key_hash}")
            print()
        
        print("Run with --help for more options")
    else:
        main()

