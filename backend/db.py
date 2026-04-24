from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "postgresql+psycopg2://postgres:47p9SB3DsfsutFq%40@db.dkxvoneldkoletwpuqfu.supabase.co:5432/postgres?sslmode=require"

# 🔥 ENGINE (WITH POOLING + STABILITY)
engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,     # avoids stale connections
    pool_size=5,            # connection pool
    max_overflow=10,        # extra connections if needed
)

# 🔥 SESSION CONFIG (IMPORTANT)
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)