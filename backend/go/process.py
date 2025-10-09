import sqlite3
import sys
import time
import random
import os

def process_image(image_path, db_path):
    """Simulates ML processing and saves the result to the database."""
    print(f"[Python] Processing image: {image_path}")
    
    if not os.path.exists(image_path):
        print(f"[Python] Error: Image path does not exist: {image_path}")
        return

    time.sleep(random.uniform(1, 3))
    predictions = ["Healthy Leaf", "Leaf Rust", "Powdery Mildew"]
    prediction = random.choice(predictions)
    confidence = round(random.uniform(0.80, 0.99), 2)

    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS results (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                image_path TEXT NOT NULL UNIQUE,
                prediction TEXT NOT NULL,
                confidence REAL NOT NULL,
                processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        cursor.execute(
            "INSERT OR IGNORE INTO results (image_path, prediction, confidence) VALUES (?, ?, ?)",
            (image_path, prediction, confidence)
        )
        conn.commit()
        conn.close()
        print(f"[Python] Successfully saved result for {image_path}")
    except sqlite3.Error as e:
        print(f"[Python] Database error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python process.py <image_path> <database_path>")
        sys.exit(1)
        
    image_path_arg = sys.argv[1]
    db_path_arg = sys.argv[2]
    process_image(image_path_arg, db_path_arg)