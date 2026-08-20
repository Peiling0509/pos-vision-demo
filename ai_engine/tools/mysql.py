import pymysql
from langchain_core.tools import tool

# ==========================================
# Database Connection
# ==========================================
def get_db_connection():
    return pymysql.connect(
        host="mysql",
        user="sail",
        password="password",
        database="laravel",
        cursorclass=pymysql.cursors.DictCursor
    )

# ==========================================
# Tool 1: Inventory Lookup
# ==========================================
@tool
def get_inventory(product_name: str) -> dict:
    """
    Check real-time stock quantity, price, and status in the POS database.
    Use this when you already have a specific product name or partial name.
    
    Args:
        product_name: A highly specific product name (e.g., 'Coca-Cola Zero Sugar'). Do not use broad categories.
    """
    connection = None
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            sql = """
                SELECT 
                    name,
                    stock_quantity,
                    price,
                    is_active
                FROM products
                WHERE name LIKE %s
                LIMIT 4
            """
            cursor.execute(sql, (f"%{product_name}%",))
            results = cursor.fetchall()

        if results:
            formatted_results = []
            for res in results:
                formatted_results.append({
                    "product": res["name"],
                    "stock": res["stock_quantity"],
                    "price": float(res["price"]),
                    "status": "In Stock" if res["stock_quantity"] > 0 else "Out of Stock",
                    "active": bool(res["is_active"])
                })
            return {"matches_found": len(formatted_results), "items": formatted_results}

        return {"error": f"No products matching '{product_name}' were found in the inventory database."}

    except Exception as e:
        return {"error": f"Database execution error: {str(e)}"}
    
    finally:
        if connection:
            connection.close()

# ==========================================
# Tool 2: Low Stock / Restock Lookup
# ==========================================
@tool
def get_products_needing_restock(threshold: int = 10) -> dict:
    """
    Check the database for active products that are running low on stock and need restocking.
    Use this when the user asks which products need to be restocked, ordered, or are running out.
    
    Args:
        threshold: An INTEGER number (e.g., 10 or 0). CRITICAL: Do NOT wrap this value in quotes or treat it as a string. It must be a raw integer number. Defaults to 10.
    """
    connection = None
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            sql = """
                SELECT 
                    name,
                    sku,
                    item_code,
                    stock_quantity
                FROM products
                WHERE stock_quantity <= %s AND is_active = 1
                ORDER BY stock_quantity ASC
                LIMIT 50
            """
            cursor.execute(sql, (threshold,))
            results = cursor.fetchall()

        if results:
            formatted_results = []
            for res in results:
                formatted_results.append({
                    "product": res["name"],
                    "sku": res["sku"],
                    "item_code": res["item_code"],
                    "stock": res["stock_quantity"]
                })
            
            return {
                "matches_found": len(formatted_results), 
                "threshold_used": threshold,
                "items": formatted_results
            }

        return {"message": f"Inventory looks good. No active products have stock at or below {threshold}."}

    except Exception as e:
        return {"error": f"Database execution error: {str(e)}"}
    
    finally:
        if connection:
            connection.close()