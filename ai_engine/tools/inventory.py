import os
import requests

from langchain_core.tools import tool


LARAVEL_BASE_URL = os.getenv(
    "LARAVEL_BASE_URL",
    "http://laravel.test/api"
)


@tool
def get_inventory(product_id: int) -> dict:
    """
    Get current inventory information for a product.

    Use this tool when the user asks about:
    - stock quantity
    - SKU
    - price
    - inventory
    - product stock
    """

    response = requests.get(
        f"{LARAVEL_BASE_URL}/products/{product_id}",
        timeout=10
    )

    response.raise_for_status()

    return response.json()


@tool
def get_products_needing_restock() -> dict:
    """
    Get products that are currently below their reorder threshold.
    """

    response = requests.get(
        f"{LARAVEL_BASE_URL}/products/low-stock",
        timeout=10
    )

    response.raise_for_status()

    return response.json()


@tool
def get_restock_recommendation(product_id: int) -> dict:
    """
    Generate an intelligent restock recommendation for a product.

    This includes:
    - demand history
    - demand forecast
    - demand trend
    - demand volatility
    - supplier information
    - supplier lead time
    - safety stock
    - reorder point
    - stockout estimation
    - recommended restock quantity
    - restock urgency

    Use this tool when the user asks:
    - Should I restock this product?
    - How much should I restock?
    - Which supplier should I use?
    - When should I reorder?
    - Is this product running out of stock?
    - Restock recommendation
    """

    response = requests.get(
        f"{LARAVEL_BASE_URL}/products/{product_id}/restock-recommendation",
        timeout=10
    )

    response.raise_for_status()

    return response.json()