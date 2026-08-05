from ultralytics import YOLO
import os

def train_model():
    # Load a pretrained YOLOv8n-cls model
    model = YOLO('yolov8n-cls.pt')
    
    # Train the model
    results = model.train(
        data='dataset', 
        epochs=10, 
        imgsz=224, 
        batch=16,
        name='solar_defect_classifier'
    )
    
    print("Training complete. Model saved in runs/classify/solar_defect_classifier/weights/best.pt")

if __name__ == "__main__":
    train_model()
