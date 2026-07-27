import pymysql
from langchain_core.tools import tool

from agent.rag import (
    get_rag_retriever,
    get_query_rewriter
)
from agent.vision import get_vision_model

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
    CRITICAL: ALWAYS use 'get_product_knowledge' FIRST to find the EXACT product name.
    Check real-time stock quantity, price, and status in the POS database.
    
    Args:
        product_name: A highly specific product name (e.g., 'Coca-Cola Zero Sugar'). Do not use broad categories.
    """
    connection = None
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            # OPTIMIZATION: Return up to 4 partial matches so the Agent has context 
            # if the exact name isn't a 100% perfect match.
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
            # Return multiple matches if they exist
            return {"matches_found": len(formatted_results), "items": formatted_results}

        return {"error": f"No products matching '{product_name}' were found in the inventory database."}

    except Exception as e:
        return {"error": f"Database execution error: {str(e)}"}
    
    finally:
        if connection:
            connection.close()

# ==========================================
# Tool 2: Image Product Detection
# ==========================================
@tool
def analyze_product_image(image_path: str) -> str:
    """
    Analyze an uploaded image to detect physical products inside it.
    Use this when the system notice indicates the user has uploaded an image.

    Args:
        image_path: The absolute file path of the image.
    """
    try:
        model = get_vision_model()
        results = model(image_path, conf=0.5)
        detected = []

        for box in results[0].boxes:
            cls_id = int(box.cls[0])
            name = model.names[cls_id]
            detected.append(name)

        if not detected:
            return "No recognizable products detected in the image."

        unique_items = list(set(detected))
        return f"Detected the following item categories: {', '.join(unique_items)}. Now use get_product_knowledge to find specific brands for these categories."

    except Exception as e:
        return f"Image analysis failed due to model error: {str(e)}"

# ==========================================
# Tool 3: Product Knowledge RAG Search
# ==========================================
@tool
def get_product_knowledge(query: str) -> str:
    """
    Search the semantic knowledge base for product recommendations, alternatives, and detailed descriptions.
    Use this FIRST when a user asks for general recommendations, categories, or has specific constraints (e.g., 'no sugar', 'movie snacks').

    Args:
        query: The user's exact requirements or situation.
    """
    try:
        # Step 1: Rewrite user query to handle negations
        rewriter = get_query_rewriter()
        intent = rewriter.invoke({"raw_query": query})
        
        print(f"🔍 Optimized Query: {intent.optimized_query}")
        print(f"🚫 Excluded Keywords: {intent.excluded_keywords}")

        # Step 2: Hybrid Retrieval
        retriever = get_rag_retriever()
        
        results = retriever.invoke(intent.optimized_query)

        if not results:
            return "No relevant product knowledge found in the database."

        # Step 3: Strict Substring Filter for exclusions
        filtered = []
        for doc in results:
            text = doc.page_content.lower()
            excluded = False

            if intent.excluded_keywords:
                for word in intent.excluded_keywords:
                    # Basic exclusion check
                    if word.lower() in text:
                        excluded = True
                        break

            if not excluded:
                filtered.append(doc.page_content)

        # Step 4: Contextual Response formatting
        if not filtered:
            return (f"Search completed for '{intent.optimized_query}', but all results were removed "
                    f"because they contained the excluded keywords: {intent.excluded_keywords}. "
                    f"Please inform the user we do not have items fitting this strict criteria.")

        # Return top 3 filtered results along with the constraints used
        context_str = "\n\n---\n\n".join(filtered[:3])
        return (f"[Search Context for '{intent.optimized_query}' | Excluded: {intent.excluded_keywords}]\n\n"
                f"{context_str}")

    except Exception as e:
        return f"Product knowledge search failed: {str(e)}"

# ==========================================
# Export Tools
# ==========================================
tools_list = [
    get_inventory,
    analyze_product_image,
    get_product_knowledge
]