#!/usr/bin/env python3

#!/usr/bin/env python3

import argparse
from PIL import Image
import numpy as np

def normalize_to_8bit(image):
    """
    Normalize a 32-bit image to 8-bit (0-255) range.
    """
    np_image = np.array(image)
    normalized = 255 * (np_image - np_image.min()) / (np_image.max() - np_image.min())
    return Image.fromarray(normalized.astype('uint8'))

def normalize_to_16bit(image):
    """
    Normalize a 32-bit image to 16-bit (0-65535) range.
    """
    np_image = np.array(image)
    normalized = 65535 * (np_image - np_image.min()) / (np_image.max() - np_image.min())
    return Image.fromarray(normalized.astype('uint16'))

def create_gif(image_paths, output_path, delay_ms=500, bit_depth=8):
    images = []

    for image_path in image_paths:
        img = Image.open(image_path)
        
        # Check if the image is in 32-bit mode and normalize if necessary
        if img.mode == 'I' or img.mode == 'F':  # 'I' is 32-bit integer, 'F' is 32-bit floating point
            if bit_depth == 16:
                img = normalize_to_16bit(img)
            else:  # Default to 8-bit if not specified
                img = normalize_to_8bit(img)
        
        images.append(img)

    images[0].save(output_path, save_all=True, append_images=images[1:], duration=delay_ms, loop=0)

def main():
    parser = argparse.ArgumentParser(description="Create a GIF from multiple images.")
    
    # Required positional arguments
    parser.add_argument('output_gif', help="Output GIF file")
    parser.add_argument('images', nargs='+', help="Input image files")
    
    # Optional arguments
    parser.add_argument('--delay', type=int, default=500, help="Delay between frames in milliseconds (default: 500)")
    parser.add_argument('--bit-depth', type=int, choices=[8, 16], default=16, 
                        help="Convert to specified bit depth (8 or 16, default: 16)")

    args = parser.parse_args()

    # Create the GIF
    create_gif(args.images, args.output_gif, args.delay, args.bit_depth)
    print(f"GIF saved as {args.output_gif} with delay {args.delay} ms and bit depth {args.bit_depth}")

if __name__ == "__main__":
    main()
