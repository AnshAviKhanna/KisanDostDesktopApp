import cv2
import numpy as np
import argparse
import base64
import json
import sys
import random

def process_image(image_path):
    """
    Processes an image to count ripe and unripe objects.

    THIS IS A MOCK EXECUTABLE. It returns random counts for ripe/unripe
    and returns the original input image without modifications.

    Args:
        image_path (str): The file path to the input image.

    Returns:
        dict: A dictionary containing the counts, the base64 encoded
              original image, and any potential error.
    """
    try:
        # Read the image from the specified path
        image = cv2.imread(image_path)
        if image is None:
            raise FileNotFoundError(f"Could not read image file at: {image_path}")

        # --- MOCK Detection ---
        # Generate random counts instead of performing actual detection.
        ripe_count = random.randint(0, 15)
        unripe_count = random.randint(0, 15)


        # --- Encode Original Input Image ---
        # Encode the original input image (with no bounding boxes) to a JPEG in memory
        _, buffer = cv2.imencode('.jpg', image)
        # Convert the buffer to a base64 string
        encoded_image = base64.b64encode(buffer).decode('utf-8')

        # Prepare the successful result dictionary
        result = {
            "ripe_count": ripe_count,
            "unripe_count": unripe_count,
            "output_image": encoded_image,
            "error": None
        }

    except Exception as e:
        # Prepare the error result dictionary
        result = {
            "ripe_count": 0,
            "unripe_count": 0,
            "output_image": None,
            "error": str(e)
        }

    return result

def main():
    """
    Main function to parse command-line arguments and run the image processing.
    """
    # Set up argument parser
    parser = argparse.ArgumentParser(description="Detect ripe and unripe objects in an image.")
    parser.add_argument(
        "--image_path",
        type=str,
        required=True,
        help="The full path to the input image file."
    )

    # Parse the command-line arguments
    args = parser.parse_args()

    # Process the image and get the result
    output_data = process_image(args.image_path)

    # Print the result as a JSON string to standard output
    print(json.dumps(output_data, indent=4))

if __name__ == "__main__":
    main()

