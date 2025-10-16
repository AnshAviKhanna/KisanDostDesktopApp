# # import os
# # import sys
# # import argparse
# # import base64
# # import json
# # import time
# # import numpy as np
# # import torch
# # from PIL import Image
# # import cv2
# # import clip

# # # ==============================================================================
# # # 1. HELPER FUNCTION FOR PYINSTALLER
# # # ==============================================================================
# # def get_base_path():
# #     """
# #     Gets the base path for the application, which is crucial for PyInstaller.
# #     When running as a bundled executable, `sys._MEIPASS` is the temporary folder
# #     where the app's data is extracted.
# #     """
# #     if getattr(sys, 'frozen', False):
# #         # Running as a bundled executable (PyInstaller)
# #         return sys._MEIPASS
# #     else:
# #         # Running as a normal Python script
# #         return os.path.dirname(os.path.abspath(__file__))

# # # ==============================================================================
# # # 2. CORE PROCESSING LOGIC (ULTRALYTICS SAM + CLIP)
# # # ==============================================================================
# # def process_image(image_path: str) -> dict:
# #     """
# #     Loads models, processes an image to count ripe/unripe tomatoes using
# #     Ultralytics SAM for segmentation and CLIP for classification.
# #     """
# #     # --- Device Configuration ---
# #     device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
# #     print(f"Using device: {device}")

# #     # --- Load Models ---
# #     try:
# #         from ultralytics import SAM

# #         print("Loading Ultralytics SAM model (will download if needed)...")
# #         # Load the Ultralytics pre-trained SAM model. The '.pt' file is downloaded automatically.
# #         sam_model = SAM('sam_b.pt')

# #         print("Loading CLIP model...")
# #         clip_model, preprocess = clip.load("ViT-B/32", device=device)
# #         print("✅ Models loaded successfully.")

# #     except Exception as e:
# #         import traceback
# #         return {"error": f"Failed to load models. Details: {e}\n{traceback.format_exc()}"}

# #     # --- Load Image ---
# #     try:
# #         print(f"Opening image: {image_path}")
# #         image_pil = Image.open(image_path).convert("RGB")
# #         image = np.array(image_pil)
# #     except FileNotFoundError:
# #         return {"error": f"Image not found at path: {image_path}"}

# #     # --- Run Ultralytics SAM Segmentation ---
# #     print("Running SAM segmentation...")
# #     results = sam_model(image_pil, device=device)  # Run inference

# #     # --- Classification Setup ---
# #     texts = [
# #         "a ripe red tomato", "an unripe green tomato", "a green leaf",
# #         "a stem or vine", "a white or yellow flower", "the ground or background"
# #     ]
# #     labels = ['ripe', 'unripe', 'leaf', 'stem', 'flower', 'others']
# #     text_tokens = clip.tokenize(texts).to(device)
# #     with torch.no_grad():
# #         text_features = clip_model.encode_text(text_tokens)
# #         text_features /= text_features.norm(dim=-1, keepdim=True)

# #     # --- Process, Classify, and Visualize ---
# #     print("Classifying segments...")
# #     ripe_count = 0
# #     unripe_count = 0
# #     image_with_boxes = image.copy()

# #     # Iterate through each result object
# #     for result in results:
# #         # Check if the result contains any masks
# #         if result.masks is None:
# #             continue

# #         # Iterate over each found mask and its corresponding bounding box
# #         for mask_tensor, box in zip(result.masks.data, result.boxes):
# #             x1, y1, x2, y2 = map(int, box.xyxy[0])
# #             w, h = x2 - x1, y2 - y1
# #             if w <= 1 or h <= 1:
# #                 continue

# #             # Crop the original image and the mask to the bounding box area
# #             cropped_rgb = image[y1:y2, x1:x2]
# #             segment_mask_cropped = mask_tensor[y1:y2, x1:x2].cpu().numpy()

# #             # Create a transparent (RGBA) image of the segment for CLIP
# #             # This isolates the object from its background
# #             rgba_crop = cv2.cvtColor(cropped_rgb, cv2.COLOR_RGB2RGBA)
# #             rgba_crop[:, :, 3] = (segment_mask_cropped > 0.5).astype(np.uint8) * 255
# #             pil_image_for_clip = Image.fromarray(rgba_crop, 'RGBA')

# #             # Run CLIP classification
# #             processed_clip_image = preprocess(pil_image_for_clip).unsqueeze(0).to(device)
# #             with torch.no_grad():
# #                 image_features = clip_model.encode_image(processed_clip_image)
# #                 image_features /= image_features.norm(dim=-1, keepdim=True)
# #                 similarity = (image_features @ text_features.T).squeeze(0)
# #                 best_match_idx = similarity.argmax().item()

# #             label = labels[best_match_idx]
# #             score = similarity[best_match_idx].item()

# #             # Count and draw boxes based on the CLIP result
# #             if label == 'ripe' and score > 0.25:
# #                 ripe_count += 1
# #                 cv2.rectangle(image_with_boxes, (x1, y1), (x2, y2), (0, 255, 0), 3)  # Green box
# #             elif label == 'unripe' and score > 0.25:
# #                 unripe_count += 1
# #                 cv2.rectangle(image_with_boxes, (x1, y1), (x2, y2), (255, 255, 0), 3)  # Yellow box

# #     print("Processing complete. Encoding final image...")
# #     # --- Encode Final Image to Base64 ---
# #     image_bgr = cv2.cvtColor(image_with_boxes, cv2.COLOR_RGB2BGR)
# #     _, buffer = cv2.imencode('.jpg', image_bgr)
# #     processed_image_base64 = base64.b64encode(buffer).decode('utf-8')

# #     # --- Compile Final JSON Output ---
# #     final_result = {
# #         "ripe_count": ripe_count,
# #         "unripe_count": unripe_count,
# #         "processed_image_base64": processed_image_base64
# #     }

# #     return final_result

# # # ==============================================================================
# # # 3. COMMAND-LINE INTERFACE
# # # ==============================================================================
# # if __name__ == "__main__":
# #     # Suppress verbose PyTorch MPS fallback warnings on macOS
# #     os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"

# #     parser = argparse.ArgumentParser(
# #         description="Count ripe and unripe tomatoes in an image."
# #     )
# #     parser.add_argument(
# #         "image_path",
# #         type=str,
# #         help="The full path to the input image file."
# #     )
# #     args = parser.parse_args()

# #     start_time = time.time()
# #     output_data = process_image(args.image_path)
# #     end_time = time.time()

# #     # Print the final result as a JSON string to standard output
# #     print(json.dumps(output_data))

# #     # Print performance info to standard error so it doesn't interfere with the JSON output
# #     print(f"\n--- Script finished in {end_time - start_time:.2f} seconds. ---", file=sys.stderr)

# # main.py (Correct - No Changes Needed)
# import os
# import sys
# import argparse
# import base64
# import json
# import numpy as np
# import torch
# from PIL import Image
# import cv2
# import clip

# def process_image(image_path: str) -> dict:
#     device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
#     try:
#         from ultralytics import SAM
#         sam_model = SAM('sam_b.pt')
#         clip_model, preprocess = clip.load("ViT-B/32", device=device)
#     except Exception as e:
#         return {"error": f"Failed to load models. Details: {e}"}

#     try:
#         image_pil = Image.open(image_path).convert("RGB")
#         image = np.array(image_pil)
#     except FileNotFoundError:
#         return {"error": f"Image not found at path: {image_path}"}

#     results = sam_model(image_pil, device=device)
#     texts = ["a ripe red tomato", "an unripe green tomato", "a green leaf", "a stem or vine", "a white or yellow flower", "background"]
#     labels = ['ripe', 'unripe', 'leaf', 'stem', 'flower', 'others']
#     text_tokens = clip.tokenize(texts).to(device)
#     with torch.no_grad():
#         text_features = clip_model.encode_text(text_tokens)
#         text_features /= text_features.norm(dim=-1, keepdim=True)

#     ripe_count = 0
#     unripe_count = 0
#     image_with_boxes = image.copy()

#     for result in results:
#         if result.masks is None:
#             continue
#         for mask_tensor, box in zip(result.masks.data, result.boxes):
#             x1, y1, x2, y2 = map(int, box.xyxy[0])
#             if (x2 - x1) <= 1 or (y2 - y1) <= 1:
#                 continue

#             cropped_rgb = image[y1:y2, x1:x2]
#             segment_mask_cropped = mask_tensor[y1:y2, x1:x2].cpu().numpy()
#             rgba_crop = cv2.cvtColor(cropped_rgb, cv2.COLOR_RGB2RGBA)
#             rgba_crop[:, :, 3] = (segment_mask_cropped > 0.5).astype(np.uint8) * 255
#             pil_image_for_clip = Image.fromarray(rgba_crop, 'RGBA')
#             processed_clip_image = preprocess(pil_image_for_clip).unsqueeze(0).to(device)

#             with torch.no_grad():
#                 image_features = clip_model.encode_image(processed_clip_image)
#                 image_features /= image_features.norm(dim=-1, keepdim=True)
#                 similarity = (image_features @ text_features.T).squeeze(0)
#                 best_match_idx = similarity.argmax().item()

#             label = labels[best_match_idx]
#             score = similarity[best_match_idx].item()

#             if label == 'ripe' and score > 0.25:
#                 ripe_count += 1
#                 cv2.rectangle(image_with_boxes, (x1, y1), (x2, y2), (0, 255, 0), 3)
#             elif label == 'unripe' and score > 0.25:
#                 unripe_count += 1
#                 cv2.rectangle(image_with_boxes, (x1, y1), (x2, y2), (255, 255, 0), 3)

#     image_bgr = cv2.cvtColor(image_with_boxes, cv2.COLOR_RGB2BGR)
#     _, buffer = cv2.imencode('.jpg', image_bgr)
#     processed_image_base64 = base64.b64encode(buffer).decode('utf-8')

#     final_result = {
#         "ripe_count": ripe_count,
#         "unripe_count": unripe_count,
#         "processed_image_base64": processed_image_base64,
#         "error": ""
#     }
#     return final_result

# if __name__ == "__main__":
#     parser = argparse.ArgumentParser(description="Count ripe and unripe tomatoes in an image.")
#     parser.add_argument("image_path", type=str, help="The full path to the input image file.")
#     args = parser.parse_args()
#     output_data = process_image(args.image_path)
#     print(json.dumps(output_data))

# main.py (Final Corrected Version)

import os
import sys
import argparse
import base64
import json
import numpy as np
import torch
from PIL import Image
import cv2
import clip

def process_image(image_path: str) -> dict:
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Using device: {device}", file=sys.stderr)

    try:
        from ultralytics import SAM
        print("Loading Ultralytics SAM model...", file=sys.stderr)
        sam_model = SAM('sam_b.pt')
        print("Loading CLIP model...", file=sys.stderr)
        clip_model, preprocess = clip.load("ViT-B/32", device=device)
        print("✅ Models loaded successfully.", file=sys.stderr)
    except Exception as e:
        import traceback
        return {"error": f"Failed to load models. Details: {e}\n{traceback.format_exc()}"}

    try:
        print(f"Opening image: {image_path}", file=sys.stderr)
        image_pil = Image.open(image_path).convert("RGB")
        image = np.array(image_pil)
    except FileNotFoundError:
        return {"error": f"Image not found at path: {image_path}"}

    print("Running SAM segmentation...", file=sys.stderr)
    # --- CRITICAL FIX ---
    # Add verbose=False to prevent the library from printing its own output.
    results = sam_model(image_pil, device=device, verbose=False)

    texts = [
        "a ripe red tomato", "an unripe green tomato", "a green leaf",
        "a stem or vine", "a white or yellow flower", "the ground or background"
    ]
    labels = ['ripe', 'unripe', 'leaf', 'stem', 'flower', 'others']
    text_tokens = clip.tokenize(texts).to(device)
    with torch.no_grad():
        text_features = clip_model.encode_text(text_tokens)
        text_features /= text_features.norm(dim=-1, keepdim=True)

    print("Classifying segments...", file=sys.stderr)
    ripe_count = 0
    unripe_count = 0
    image_with_boxes = image.copy()

    for result in results:
        if result.masks is None:
            continue
        for mask_tensor, box in zip(result.masks.data, result.boxes):
            x1, y1, x2, y2 = map(int, box.xyxy[0])
            w, h = x2 - x1, y2 - y1
            if w <= 1 or h <= 1:
                continue
            
            cropped_rgb = image[y1:y2, x1:x2]
            segment_mask_cropped = mask_tensor[y1:y2, x1:x2].cpu().numpy()
            rgba_crop = cv2.cvtColor(cropped_rgb, cv2.COLOR_RGB2RGBA)
            rgba_crop[:, :, 3] = (segment_mask_cropped > 0.5).astype(np.uint8) * 255
            pil_image_for_clip = Image.fromarray(rgba_crop, 'RGBA')
            processed_clip_image = preprocess(pil_image_for_clip).unsqueeze(0).to(device)
            
            with torch.no_grad():
                image_features = clip_model.encode_image(processed_clip_image)
                image_features /= image_features.norm(dim=-1, keepdim=True)
                similarity = (image_features @ text_features.T).squeeze(0)
                best_match_idx = similarity.argmax().item()
            
            label = labels[best_match_idx]
            score = similarity[best_match_idx].item()
            
            if label == 'ripe' and score > 0.25:
                ripe_count += 1
                cv2.rectangle(image_with_boxes, (x1, y1), (x2, y2), (0, 255, 0), 3)
            elif label == 'unripe' and score > 0.25:
                unripe_count += 1
                cv2.rectangle(image_with_boxes, (x1, y1), (x2, y2), (255, 255, 0), 3)

    print("Processing complete. Encoding final image...", file=sys.stderr)
    image_bgr = cv2.cvtColor(image_with_boxes, cv2.COLOR_RGB2BGR)
    _, buffer = cv2.imencode('.jpg', image_bgr)
    processed_image_base64 = base64.b64encode(buffer).decode('utf-8')

    final_result = {
        "ripe_count": ripe_count,
        "unripe_count": unripe_count,
        "processed_image_base64": processed_image_base64,
        "error": ""
    }
    return final_result

if __name__ == "__main__":
    os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"
    parser = argparse.ArgumentParser(description="Count ripe and unripe tomatoes in an image.")
    parser.add_argument("image_path", type=str, help="The full path to the input image file.")
    args = parser.parse_args()
    
    output_data = process_image(args.image_path)
    # This will now be the ONLY output sent to stdout.
    print(json.dumps(output_data))