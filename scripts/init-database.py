#!/usr/bin/env python3
"""
Database initialization script for Weather Bot.
This script can be used to initialize or migrate the database.
"""

import sys
import os
import logging
from pathlib import Path

# Add src to path so we can import our modules
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from src.database import init_database, migrate_database, test_database_connection
from src.config.logging import setup_logging

def main():
    """Initialize or migrate the database."""
    logger = setup_logging()
    
    try:
        logger.info("Starting database initialization...")
        
        # Test connection first
        if not test_database_connection():
            logger.error("Database connection test failed")
            sys.exit(1)
        
        # Initialize database
        init_database()
        
        # Test again to make sure everything works
        if not test_database_connection():
            logger.error("Database initialization failed - connection test failed")
            sys.exit(1)
        
        logger.info("Database initialization completed successfully!")
        
    except Exception as e:
        logger.error(f"Database initialization failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
