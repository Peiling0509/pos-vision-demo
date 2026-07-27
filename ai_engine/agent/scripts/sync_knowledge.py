import pymysql
import chromadb
import uuid
from sentence_transformers import SentenceTransformer

# ==========================================
# 1. Initialize the embedding model and ChromaDB client
# ==========================================
print("Loading Embedding Model (this might take a few seconds on first run)...")
# use lightweight model for faster embedding generation
embedding_model = SentenceTransformer('all-MiniLM-L6-v2')

print("Connecting to ChromaDB...")

chroma_client = chromadb.PersistentClient(path="/app/chroma_data")

collection = chroma_client.get_or_create_collection(name="product_knowledge")

def get_db_connection():
    return pymysql.connect(
        host='mysql',
        user='sail',
        password='password',
        database='laravel',
        cursorclass=pymysql.cursors.DictCursor
    )

def sync_data():
    try:
        connection = get_db_connection()
        with connection.cursor() as cursor:
            # 1. Extract: Read knowledge records from the Laravel database that have not yet been vectorized
            sql_select = """
                SELECT id, item_name, item_code, knowledge_content 
                FROM product_knowledges 
                WHERE is_active = 1
            """
            cursor.execute(sql_select)
            records = cursor.fetchall()

            if not records:
                print("No active knowledge records found.")
                return

            print(f"Found {len(records)} records. Starting vectorization...")

            for record in records:
                content = record['knowledge_content']
                db_id = record['id']
                item_name = record['item_name']

                # generate a unique vector ID for this record
                vector_id = f"vec_{uuid.uuid4().hex[:12]}"

                # 2. Transform: Generate embeddings for the knowledge content
                # .tolist() is used to convert the numpy array to a list for ChromaDB compatibility
                vector = embedding_model.encode(content).tolist()

                # 3. Load: Upsert the vector and its metadata into ChromaDB
                collection.upsert(
                    ids=[vector_id],
                    embeddings=[vector],
                    metadatas=[{"item_name": item_name, "db_id": db_id}], # store the database ID for reference
                    documents=[content]
                )

                # 4. Update the database record to store the ChromaDB vector ID
                # Assuming your field name in the database is called chromadb_vector_id
                sql_update = """
                    UPDATE product_knowledges 
                    SET chromadb_vector_id = %s 
                    WHERE id = %s
                """
                cursor.execute(sql_update, (vector_id, db_id))
                connection.commit()
                
                print(f"✅ Successfully synced: {item_name} (Vector ID: {vector_id})")

    except Exception as e:
        print(f"❌ Error during sync: {str(e)}")
    finally:
        if 'connection' in locals() and connection.open:
            connection.close()
            print("Database connection closed.")

if __name__ == "__main__":
    sync_data()