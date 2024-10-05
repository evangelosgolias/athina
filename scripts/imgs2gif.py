#!/usr/bin/env python3

import argparse
from PIL import Image

def create_gif(image_paths, output_path, delay_ms=500):
    images = [Image.open(image) for image in image_paths]
    images[0].save(output_path, save_all=True, append_images=images[1:], duration=delay_ms, loop=0)

def main():
    parser = argparse.ArgumentParser(description="Create a GIF from multiple images.")
    
    # Required positional arguments
    parser.add_argument('output_gif', help="Output GIF file")
    parser.add_argument('images', nargs='+', help="Input image files")
    
    # Optional argument for delay
    parser.add_argument('--delay', type=int, default=500, help="Delay between frames in milliseconds (default: 500)")

    args = parser.parse_args()

    # Create the GIF
    create_gif(args.images, args.output_gif, args.delay)
    print(f"GIF saved as {args.output_gif} with delay {args.delay} ms")

if __name__ == "__main__":
    main()
