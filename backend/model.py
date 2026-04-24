from sqlalchemy import Column, Integer, String, Float, Date
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class Sales(Base):
    __tablename__ = "sales"

    id = Column(Integer, primary_key=True, index=True)

    # 🛒 PRODUCT INFO
    product_name = Column(String)
    category = Column(String)          # electronics, clothing, etc.

    # 💰 TRANSACTION
    amount = Column(Float)
    quantity = Column(Integer)
    discount = Column(Float)
    payment_method = Column(String)    # UPI, Card, Cash

    # 👤 CUSTOMER
    buyer = Column(String)
    phone = Column(String)             # 🔥 NEW
    email = Column(String)

    # 📍 LOCATION
    city = Column(String)
    country = Column(String)

    # 📅 TIME
    date = Column(Date)

    # 📊 BUSINESS
    sales_channel = Column(String)     # online / offline