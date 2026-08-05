import os
import shutil
import random
from pathlib import Path

def split_dataset(source_dir, target_dir, split_ratio=0.8):
    source_dir = Path(source_dir)
    target_dir = Path(target_dir)
    
    classes = [d.name for d in source_dir.iterdir() if d.is_dir()]
    
    for cls in classes:
        cls_source = source_dir / cls
        # Only get files, skip directories like 'New'
        images = [f for f in cls_source.iterdir() if f.is_file() and f.suffix.lower() in ['.jpg', '.jpeg', '.png', '.bmp']]
        random.shuffle(images)
        
        split_point = int(len(images) * split_ratio)
        train_images = images[:split_point]
        val_images = images[split_point:]
        
        # Create directories
        (target_dir / 'train' / cls).mkdir(parents=True, exist_ok=True)
        (target_dir / 'val' / cls).mkdir(parents=True, exist_ok=True)
        
        # Copy files
        for img in train_images:
            shutil.copy(img, target_dir / 'train' / cls / img.name)
        for img in val_images:
            shutil.copy(img, target_dir / 'val' / cls / img.name)
            
    print(f"Dataset split completed. Saved to {target_dir}")

if __name__ == "__main__":
    split_dataset('../train data', 'dataset')
